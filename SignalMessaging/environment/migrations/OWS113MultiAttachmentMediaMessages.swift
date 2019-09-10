//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalServiceKit

@objc
public class OWS113MultiAttachmentMediaMessages: OWSDatabaseMigration {

    // MARK: - Dependencies

    // MARK: -

    // Increment a similar constant for each migration.
    @objc
    class func migrationId() -> String {
        // NOTE: that we use .1 since there was a bug in the logic to
        //       set albumMessageId.
        return "113.1"
    }

    override public func runUp(completion: @escaping OWSDatabaseMigrationCompletion) {
        Logger.debug("")
        BenchAsync(title: "\(self.logTag)") { (benchCompletion) in
            self.doMigrationAsync(completion: {
                benchCompletion()
                completion()
            })
        }
    }

    private func doMigrationAsync(completion : @escaping OWSDatabaseMigrationCompletion) {
        DispatchQueue.global().async {
            var legacyAttachments: [(attachmentId: String, messageId: String)] = []

            self.dbReadWriteConnection().read { transaction in
                TSMessage.enumerateCollectionObjects(with: transaction) { object, _ in
                    autoreleasepool {
                        guard let message: TSMessage = object as? TSMessage else {
                            Logger.debug("ignoring message with type: \(object)")
                            return
                        }

                        guard let messageId = message.uniqueId else {
                            owsFailDebug("messageId was unexpectedly nil")
                            return
                        }

                        for attachmentId in message.attachmentIds {
                            legacyAttachments.append((attachmentId: attachmentId as! String, messageId: messageId))
                        }
                    }
                }
            }
            self.dbReadWriteConnection().readWrite { transaction in
                for (attachmentId, messageId) in legacyAttachments {
                    autoreleasepool {
                        guard let attachment = TSAttachment.fetch(uniqueId: attachmentId, transaction: transaction) else {
                            Logger.warn("missing attachment for messageId: \(messageId)")
                            return
                        }

                        attachment.migrateAlbumMessageId(messageId)
                        attachment.save(with: transaction)
                    }
                }
                self.save(with: transaction)
            }

            completion()
        }
    }
}
