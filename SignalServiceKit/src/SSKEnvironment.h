//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSSyncManagerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class ContactDiscoveryService;
@class ContactsUpdater;
@class OWS2FAManager;
@class OWSAttachmentDownloads;
@class OWSBatchMessageProcessor;
@class OWSBlockingManager;
@class OWSDisappearingMessagesJob;
@class OWSIdentityManager;
@class OWSMessageDecrypter;
@class OWSMessageManager;
@class OWSMessageReceiver;
@class OWSMessageSender;
@class OWSOutgoingReceiptManager;
@class OWSPrimaryStorage;
@class OWSReadReceiptManager;
@class SSKMessageSenderJobQueue;
@class TSAccountManager;
@class TSNetworkManager;
@class TSSocketManager;
@class YapDatabaseConnection;

@protocol ContactsManagerProtocol;
@protocol NotificationsProtocol;
@protocol OWSCallMessageHandler;
@protocol ProfileManagerProtocol;
@protocol OWSUDManager;
@protocol SSKReachabilityManager;
@protocol OWSSyncManagerProtocol;
@protocol OWSTypingIndicators;

@interface SSKEnvironment : NSObject

- (instancetype)initWithContactsManager:(id<ContactsManagerProtocol>)contactsManager
                          messageSender:(OWSMessageSender *)messageSender
                  messageSenderJobQueue:(SSKMessageSenderJobQueue *)messageSenderJobQueue
                         profileManager:(id<ProfileManagerProtocol>)profileManager
                         primaryStorage:(OWSPrimaryStorage *)primaryStorage
                        contactsUpdater:(ContactsUpdater *)contactsUpdater
                         networkManager:(TSNetworkManager *)networkManager
                         messageManager:(OWSMessageManager *)messageManager
                        blockingManager:(OWSBlockingManager *)blockingManager
                        identityManager:(OWSIdentityManager *)identityManager
                              udManager:(id<OWSUDManager>)udManager
                       messageDecrypter:(OWSMessageDecrypter *)messageDecrypter
                  batchMessageProcessor:(OWSBatchMessageProcessor *)batchMessageProcessor
                        messageReceiver:(OWSMessageReceiver *)messageReceiver
                          socketManager:(TSSocketManager *)socketManager
                       tsAccountManager:(TSAccountManager *)tsAccountManager
                          ows2FAManager:(OWS2FAManager *)ows2FAManager
                disappearingMessagesJob:(OWSDisappearingMessagesJob *)disappearingMessagesJob
                contactDiscoveryService:(ContactDiscoveryService *)contactDiscoveryService
                     readReceiptManager:(OWSReadReceiptManager *)readReceiptManager
                 outgoingReceiptManager:(OWSOutgoingReceiptManager *)outgoingReceiptManager
                    reachabilityManager:(id<SSKReachabilityManager>)reachabilityManager
                            syncManager:(id<OWSSyncManagerProtocol>)syncManager
                       typingIndicators:(id<OWSTypingIndicators>)typingIndicators
                    attachmentDownloads:(OWSAttachmentDownloads *)attachmentDownloads NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly, class) SSKEnvironment *shared;

+ (void)setShared:(SSKEnvironment *)env;

#ifdef DEBUG
// Should only be called by tests.
+ (void)clearSharedForTests;
#endif

@property (nonatomic, readonly) id<ContactsManagerProtocol> contactsManager;
@property (nonatomic, readonly) OWSMessageSender *messageSender;
@property (nonatomic, readonly) SSKMessageSenderJobQueue *messageSenderJobQueue;
@property (nonatomic, readonly) id<ProfileManagerProtocol> profileManager;
@property (nonatomic, readonly) OWSPrimaryStorage *primaryStorage;
@property (nonatomic, readonly) ContactsUpdater *contactsUpdater;
@property (nonatomic, readonly) TSNetworkManager *networkManager;
@property (nonatomic, readonly) OWSMessageManager *messageManager;
@property (nonatomic, readonly) OWSBlockingManager *blockingManager;
@property (nonatomic, readonly) OWSIdentityManager *identityManager;
@property (nonatomic, readonly) id<OWSUDManager> udManager;
@property (nonatomic, readonly) OWSMessageDecrypter *messageDecrypter;
@property (nonatomic, readonly) OWSBatchMessageProcessor *batchMessageProcessor;
@property (nonatomic, readonly) OWSMessageReceiver *messageReceiver;
@property (nonatomic, readonly) TSSocketManager *socketManager;
@property (nonatomic, readonly) TSAccountManager *tsAccountManager;
@property (nonatomic, readonly) OWS2FAManager *ows2FAManager;
@property (nonatomic, readonly) OWSDisappearingMessagesJob *disappearingMessagesJob;
@property (nonatomic, readonly) ContactDiscoveryService *contactDiscoveryService;
@property (nonatomic, readonly) OWSReadReceiptManager *readReceiptManager;
@property (nonatomic, readonly) OWSOutgoingReceiptManager *outgoingReceiptManager;
@property (nonatomic, readonly) id<OWSSyncManagerProtocol> syncManager;
@property (nonatomic, readonly) id<SSKReachabilityManager> reachabilityManager;
@property (nonatomic, readonly) id<OWSTypingIndicators> typingIndicators;
@property (nonatomic, readonly) OWSAttachmentDownloads *attachmentDownloads;

// This property is configured after Environment is created.
@property (atomic, nullable) id<OWSCallMessageHandler> callMessageHandler;
// This property is configured after Environment is created.
@property (atomic, nullable) id<NotificationsProtocol> notificationsManager;

@property (atomic, readonly) YapDatabaseConnection *objectReadWriteConnection;
@property (atomic, readonly) YapDatabaseConnection *sessionStoreDBConnection;
@property (atomic, readonly) YapDatabaseConnection *migrationDBConnection;
@property (atomic, readonly) YapDatabaseConnection *analyticsDBConnection;

- (BOOL)isComplete;

@end

NS_ASSUME_NONNULL_END
