//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

/// Durably enqueues a message for sending.
///
/// The queue's operations (`MessageSenderOperation`) uses `MessageSender` to send a message.
///
/// ## Retry behavior
///
/// Like all JobQueue's, MessageSenderJobQueue implements retry handling for operation errors.
///
/// `MessageSender` also includes it's own retry logic necessary to encapsulate business logic around
/// a user changing their Registration ID, or adding/removing devices. That is, it is sometimes *normal*
/// for MessageSender to have to resend to a recipient multiple times before it is accepted, and doesn't
/// represent a "failure" from the application standpoint.
///
/// So we have an inner non-durable retry (MessageSender) and an outer durable retry (MessageSenderJobQueue).
///
/// Both respect the `error.isRetryable` convention to be sure we don't keep retrying in some situations
/// (e.g. rate limiting)

@objc(SSKMessageSenderJobQueue)
public class MessageSenderJobQueue: NSObject, JobQueue {

    @objc
    public override init() {
        super.init()

        AppReadiness.runNowOrWhenAppWillBecomeReady {
            self.setup()
        }
    }

    // MARK: 

    @objc(addMessage:transaction:)
    public func add(message: TSOutgoingMessage, transaction: YapDatabaseReadWriteTransaction) {
        self.add(message: message, removeMessageAfterSending: false, transaction: transaction)
    }

    @objc(addMediaMessage:dataSource:contentType:sourceFilename:caption:albumMessageId:isTemporaryAttachment:)
    public func add(mediaMessage: TSOutgoingMessage, dataSource: DataSource, contentType: String, sourceFilename: String?, caption: String?, albumMessageId: String?, isTemporaryAttachment: Bool) {
        let attachmentInfo = OutgoingAttachmentInfo(dataSource: dataSource, contentType: contentType, sourceFilename: sourceFilename, caption: caption, albumMessageId: albumMessageId)
        add(mediaMessage: mediaMessage, attachmentInfos: [attachmentInfo], isTemporaryAttachment: isTemporaryAttachment)
    }

    @objc(addMediaMessage:attachmentInfos:isTemporaryAttachment:)
    public func add(mediaMessage: TSOutgoingMessage, attachmentInfos: [OutgoingAttachmentInfo], isTemporaryAttachment: Bool) {
        OutgoingMessagePreparer.prepareAttachments(attachmentInfos,
                                                  inMessage: mediaMessage,
                                                  completionHandler: { error in
                                                    if let error = error {
                                                        self.dbConnection.readWrite { transaction in
                                                            mediaMessage.update(sendingError: error, transaction: transaction)
                                                        }
                                                    } else {
                                                        self.dbConnection.readWrite { transaction in
                                                            self.add(message: mediaMessage, removeMessageAfterSending: isTemporaryAttachment, transaction: transaction)
                                                        }
                                                    }
        })
    }

    private func add(message: TSOutgoingMessage, removeMessageAfterSending: Bool, transaction: YapDatabaseReadWriteTransaction) {
        assert(AppReadiness.isAppReady() || CurrentAppContext().isRunningTests)

        let jobRecord: SSKMessageSenderJobRecord
        do {
            jobRecord = try SSKMessageSenderJobRecord(message: message, removeMessageAfterSending: false, label: self.jobRecordLabel)
        } catch {
            owsFailDebug("failed to build job: \(error)")
            return
        }
        self.add(jobRecord: jobRecord, transaction: transaction)
    }

    // MARK: JobQueue

    public typealias DurableOperationType = MessageSenderOperation
    public static let jobRecordLabel: String = "MessageSender"
    public static let maxRetries: UInt = 10
    public let requiresInternet: Bool = true
    public var runningOperations: [MessageSenderOperation] = []

    public var jobRecordLabel: String {
        return type(of: self).jobRecordLabel
    }

    @objc
    public func setup() {
        defaultSetup()
    }

    public var isSetup: Bool = false

    public func didMarkAsReady(oldJobRecord: SSKMessageSenderJobRecord, transaction: YapDatabaseReadWriteTransaction) {
        if let messageId = oldJobRecord.messageId, let message = TSOutgoingMessage.fetch(uniqueId: messageId, transaction: transaction) {
            message.updateWithMarkingAllUnsentRecipientsAsSending(with: transaction)
        }
    }

    public func buildOperation(jobRecord: SSKMessageSenderJobRecord, transaction: YapDatabaseReadTransaction) throws -> MessageSenderOperation {
        let message: TSOutgoingMessage
        if let invisibleMessage = jobRecord.invisibleMessage {
            message = invisibleMessage
        } else if let messageId = jobRecord.messageId, let fetchedMessage = TSOutgoingMessage.fetch(uniqueId: messageId, transaction: transaction) {
            message = fetchedMessage
        } else {
            assert(jobRecord.messageId != nil)
            throw JobError.obsolete(description: "message no longer exists")
        }

        return MessageSenderOperation(message: message, jobRecord: jobRecord)
    }

    var senderQueues: [String: OperationQueue] = [:]
    let defaultQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "DefaultSendingQueue"
        operationQueue.maxConcurrentOperationCount = 1

        return operationQueue
    }()

    // We use a per-thread serial OperationQueue to ensure messages are delivered to the
    // service in the order the user sent them.
    public func operationQueue(jobRecord: SSKMessageSenderJobRecord) -> OperationQueue {
        guard let threadId = jobRecord.threadId else {
            return defaultQueue
        }

        guard let existingQueue = senderQueues[threadId] else {
            let operationQueue = OperationQueue()
            operationQueue.name = "SendingQueue:\(threadId)"
            operationQueue.maxConcurrentOperationCount = 1

            senderQueues[threadId] = operationQueue

            return operationQueue
        }

        return existingQueue
    }
}

public class MessageSenderOperation: OWSOperation, DurableOperation {

    // MARK: DurableOperation

    public let jobRecord: SSKMessageSenderJobRecord

    weak public var durableOperationDelegate: MessageSenderJobQueue?

    public var operation: OWSOperation {
        return self
    }

    // MARK: Init

    let message: TSOutgoingMessage

    init(message: TSOutgoingMessage, jobRecord: SSKMessageSenderJobRecord) {
        self.message = message
        self.jobRecord = jobRecord
        super.init()
    }

    // MARK: Dependencies

    var messageSender: MessageSender {
        return SSKEnvironment.shared.messageSender
    }

    var dbConnection: YapDatabaseConnection {
        return SSKEnvironment.shared.primaryStorage.dbReadWriteConnection
    }

    // MARK: OWSOperation

    override public func run() {
        self.messageSender.send(message, success: reportSuccess, failure: reportError)
    }

    override public func didSucceed() {
        self.dbConnection.readWrite { transaction in
            self.durableOperationDelegate?.durableOperationDidSucceed(self, transaction: transaction)
            if self.jobRecord.removeMessageAfterSending {
                self.message.remove(with: transaction)
            }
        }
    }

    override public func didReportError(_ error: Error) {
        Logger.debug("remainingRetries: \(self.remainingRetries)")

        self.dbConnection.readWrite { transaction in
            self.durableOperationDelegate?.durableOperation(self, didReportError: error, transaction: transaction)
        }
    }

    override public func retryInterval() -> TimeInterval {
        // Arbitrary backoff factor...
        // With backOffFactor of 1.9
        // try  1 delay:  0.00s
        // try  2 delay:  0.19s
        // ...
        // try  5 delay:  1.30s
        // ...
        // try 11 delay: 61.31s
        let backoffFactor = 1.9
        let maxBackoff = kHourInterval

        let seconds = 0.1 * min(maxBackoff, pow(backoffFactor, Double(self.jobRecord.failureCount)))
        return seconds
    }

    override public func didFail(error: Error) {
        self.dbConnection.readWrite { transaction in
            self.durableOperationDelegate?.durableOperation(self, didFailWithError: error, transaction: transaction)

            self.message.update(sendingError: error, transaction: transaction)
            if self.jobRecord.removeMessageAfterSending {
                self.message.remove(with: transaction)
            }
        }
    }
}
