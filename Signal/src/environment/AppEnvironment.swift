//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation
import SignalServiceKit
import SignalMessaging

@objc public class AppEnvironment: NSObject {

    private static var _shared: AppEnvironment = AppEnvironment()

    @objc
    public class var shared: AppEnvironment {
        get {
            return _shared
        }
        set {
            guard CurrentAppContext().isRunningTests else {
                owsFailDebug("Can only switch environments in tests.")
                return
            }

            _shared = newValue
        }
    }

    @objc
    public var callMessageHandler: WebRTCCallMessageHandler

    @objc
    public var callService: CallService

    @objc
    public var outboundCallInitiator: OutboundCallInitiator

    @objc
    public var messageFetcherJob: MessageFetcherJob

    @objc
    public var notificationsManager: NotificationsManager

    @objc
    public var accountManager: AccountManager

    @objc
    public var callNotificationsAdapter: CallNotificationsAdapter

    @objc
    public var pushRegistrationManager: PushRegistrationManager

    @objc
    public var pushManager: PushManager

    @objc
    public var sessionResetJobQueue: SessionResetJobQueue

    private override init() {
        self.callMessageHandler = WebRTCCallMessageHandler()
        self.callService = CallService()
        self.outboundCallInitiator = OutboundCallInitiator()
        self.messageFetcherJob = MessageFetcherJob()
        self.notificationsManager = NotificationsManager()
        self.accountManager = AccountManager()
        self.callNotificationsAdapter = CallNotificationsAdapter()
        self.pushRegistrationManager = PushRegistrationManager()
        self.pushManager = PushManager()
        self.sessionResetJobQueue = SessionResetJobQueue()

        super.init()

        SwiftSingletons.register(self)
    }

    @objc
    public func setup() {
        callService.createCallUIAdapter()

        // Hang certain singletons on SSKEnvironment too.
        SSKEnvironment.shared.notificationsManager = notificationsManager
        SSKEnvironment.shared.callMessageHandler = callMessageHandler
    }
}
