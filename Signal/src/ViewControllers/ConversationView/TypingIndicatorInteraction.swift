//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc(OWSTypingIndicatorInteraction)
public class TypingIndicatorInteraction: TSInteraction {
    @objc
    public static let TypingIndicatorId = "TypingIndicator"

    @objc
    public override func isDynamicInteraction() -> Bool {
        return true
    }

    @objc
    public override func interactionType() -> OWSInteractionType {
        return .typingIndicator
    }

    @available(*, unavailable, message:"use other constructor instead.")
    @objc
    public required init(coder aDecoder: NSCoder) {
        notImplemented()
    }

    @available(*, unavailable, message:"use other constructor instead.")
    @objc
    public required init(dictionary dictionaryValue: [AnyHashable: Any]!) throws {
        notImplemented()
    }

    @objc
    public let recipientId: String

    @objc
    public init(thread: TSThread, timestamp: UInt64, recipientId: String) {
        self.recipientId = recipientId

        super.init(interactionWithUniqueId: TypingIndicatorInteraction.TypingIndicatorId,
            timestamp: timestamp, in: thread)
    }

    @objc
    public override func save(with transaction: YapDatabaseReadWriteTransaction) {
        owsFailDebug("The transient interaction should not be saved in the database.")
    }
}
