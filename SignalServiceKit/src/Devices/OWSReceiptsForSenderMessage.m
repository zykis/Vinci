//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSReceiptsForSenderMessage.h"
#import "SignalRecipient.h"
#import <SignalCoreKit/NSDate+OWS.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSReceiptsForSenderMessage ()

@property (nonatomic, readonly) NSArray<NSNumber *> *messageTimestamps;

@property (nonatomic, readonly) SSKProtoReceiptMessageType receiptType;

@end

#pragma mark -

@implementation OWSReceiptsForSenderMessage

+ (OWSReceiptsForSenderMessage *)deliveryReceiptsForSenderMessageWithThread:(nullable TSThread *)thread
                                                          messageTimestamps:(NSArray<NSNumber *> *)messageTimestamps
{
    return [[OWSReceiptsForSenderMessage alloc] initWithThread:thread
                                             messageTimestamps:messageTimestamps
                                                   receiptType:SSKProtoReceiptMessageTypeDelivery];
}

+ (OWSReceiptsForSenderMessage *)readReceiptsForSenderMessageWithThread:(nullable TSThread *)thread
                                                      messageTimestamps:(NSArray<NSNumber *> *)messageTimestamps
{
    return [[OWSReceiptsForSenderMessage alloc] initWithThread:thread
                                             messageTimestamps:messageTimestamps
                                                   receiptType:SSKProtoReceiptMessageTypeRead];
}

- (instancetype)initWithThread:(nullable TSThread *)thread
             messageTimestamps:(NSArray<NSNumber *> *)messageTimestamps
                   receiptType:(SSKProtoReceiptMessageType)receiptType
{
    self = [super initOutgoingMessageWithTimestamp:[NSDate ows_millisecondTimeStamp]
                                          inThread:thread
                                       messageBody:nil
                                     attachmentIds:[NSMutableArray new]
                                  expiresInSeconds:0
                                   expireStartedAt:0
                                    isVoiceMessage:NO
                                  groupMetaMessage:TSGroupMetaMessageUnspecified
                                     quotedMessage:nil
                                      contactShare:nil];
    if (!self) {
        return self;
    }

    _messageTimestamps = [messageTimestamps copy];
    _receiptType = receiptType;

    return self;
}

#pragma mark - TSOutgoingMessage overrides

- (BOOL)shouldSyncTranscript
{
    return NO;
}

- (BOOL)isSilent
{
    // Avoid "phantom messages" for "recipient read receipts".

    return YES;
}

- (nullable NSData *)buildPlainTextData:(SignalRecipient *)recipient
{
    OWSAssertDebug(recipient);

    SSKProtoReceiptMessage *_Nullable receiptMessage = [self buildReceiptMessage:recipient.recipientId];
    if (!receiptMessage) {
        OWSFailDebug(@"could not build protobuf.");
        return nil;
    }

    SSKProtoContentBuilder *contentBuilder = [SSKProtoContent builder];
    [contentBuilder setReceiptMessage:receiptMessage];

    NSError *error;
    NSData *_Nullable contentData = [contentBuilder buildSerializedDataAndReturnError:&error];
    if (error || !contentData) {
        OWSFailDebug(@"could not serialize protobuf: %@", error);
        return nil;
    }
    return contentData;
}

- (nullable SSKProtoReceiptMessage *)buildReceiptMessage:(NSString *)recipientId
{
    SSKProtoReceiptMessageBuilder *builder = [SSKProtoReceiptMessage builderWithType:self.receiptType];

    OWSAssertDebug(self.messageTimestamps.count > 0);
    for (NSNumber *messageTimestamp in self.messageTimestamps) {
        [builder addTimestamp:[messageTimestamp unsignedLongLongValue]];
    }

    NSError *error;
    SSKProtoReceiptMessage *_Nullable receiptMessage = [builder buildAndReturnError:&error];
    if (error || !receiptMessage) {
        OWSFailDebug(@"could not build protobuf: %@", error);
        return nil;
    }
    return receiptMessage;
}

#pragma mark - TSYapDatabaseObject overrides

- (BOOL)shouldBeSaved
{
    return NO;
}

- (NSString *)debugDescription
{
    return [NSString
        stringWithFormat:@"%@ with message timestamps: %lu", self.logTag, (unsigned long)self.messageTimestamps.count];
}

@end

NS_ASSUME_NONNULL_END
