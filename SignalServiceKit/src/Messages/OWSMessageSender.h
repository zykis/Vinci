//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "DataSource.h"

NS_ASSUME_NONNULL_BEGIN

extern const NSUInteger kOversizeTextMessageSizeThreshold;

@class OWSBlockingManager;
@class OWSPrimaryStorage;
@class TSAttachmentStream;
@class TSInvalidIdentityKeySendingErrorMessage;
@class TSNetworkManager;
@class TSOutgoingMessage;
@class TSThread;
@class YapDatabaseReadWriteTransaction;

@protocol ContactsManagerProtocol;

/**
 * Useful for when you *sometimes* want to retry before giving up and calling the failure handler
 * but *sometimes* we don't want to retry when we know it's a terminal failure, so we allow the
 * caller to indicate this with isRetryable=NO.
 */
typedef void (^RetryableFailureHandler)(NSError *_Nonnull error);

// Message send error handling is slightly different for contact and group messages.
//
// For example, If one member of a group deletes their account, the group should
// ignore errors when trying to send messages to this ex-member.

#pragma mark -

NS_SWIFT_NAME(OutgoingAttachmentInfo)
@interface OWSOutgoingAttachmentInfo : NSObject

@property (nonatomic, readonly) DataSource *dataSource;
@property (nonatomic, readonly) NSString *contentType;
@property (nonatomic, readonly, nullable) NSString *sourceFilename;
@property (nonatomic, readonly, nullable) NSString *caption;
@property (nonatomic, readonly, nullable) NSString *albumMessageId;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(DataSource *)dataSource
                       contentType:(NSString *)contentType
                    sourceFilename:(nullable NSString *)sourceFilename
                           caption:(nullable NSString *)caption
                    albumMessageId:(nullable NSString *)albumMessageId NS_DESIGNATED_INITIALIZER;

@end

#pragma mark -

NS_SWIFT_NAME(MessageSender)
@interface OWSMessageSender : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPrimaryStorage:(OWSPrimaryStorage *)primaryStorage NS_DESIGNATED_INITIALIZER;

/**
 * Send and resend text messages or resend messages with existing attachments.
 * If you haven't yet created the attachment, see the `sendAttachment:` variants.
 */
- (void)sendMessage:(TSOutgoingMessage *)message
            success:(void (^)(void))successHandler
            failure:(void (^)(NSError *error))failureHandler;

/**
 * Takes care of allocating and uploading the attachment, then sends the message.
 * Only necessary to call once. If sending fails, retry with `sendMessage:`.
 */
- (void)sendAttachment:(DataSource *)dataSource
           contentType:(NSString *)contentType
        sourceFilename:(nullable NSString *)sourceFilename
             inMessage:(TSOutgoingMessage *)outgoingMessage
               success:(void (^)(void))successHandler
               failure:(void (^)(NSError *error))failureHandler;

/**
 * Same as `sendAttachment:`, but deletes the local copy of the attachment after sending.
 * Used for sending sync request data, not for user visible attachments.
 */
- (void)sendTemporaryAttachment:(DataSource *)dataSource
                    contentType:(NSString *)contentType
                      inMessage:(TSOutgoingMessage *)outgoingMessage
                        success:(void (^)(void))successHandler
                        failure:(void (^)(NSError *error))failureHandler;

@end

#pragma mark -

@interface OutgoingMessagePreparer : NSObject

/// Persists all necessary data to disk before sending, e.g. generate thumbnails
+ (void)prepareMessageForSending:(TSOutgoingMessage *)message
      quotedThumbnailAttachments:(NSArray<TSAttachmentStream *> **)outQuotedThumbnailAttachments
    contactShareAvatarAttachment:(TSAttachmentStream **)outContactShareAvatarAttachment
                     transaction:(YapDatabaseReadWriteTransaction *)transaction;

/// Writes attachment to disk and applies original filename to message attributes
+ (void)prepareAttachments:(NSArray<OWSOutgoingAttachmentInfo *> *)attachmentInfos
                 inMessage:(TSOutgoingMessage *)outgoingMessage
         completionHandler:(void (^)(NSError *_Nullable error))completionHandler
    NS_SWIFT_NAME(prepareAttachments(_:inMessage:completionHandler:));

@end

NS_ASSUME_NONNULL_END
