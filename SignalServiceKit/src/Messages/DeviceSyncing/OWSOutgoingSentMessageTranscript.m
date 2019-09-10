//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSOutgoingSentMessageTranscript.h"
#import "TSOutgoingMessage.h"
#import "TSThread.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSOutgoingMessage (OWSOutgoingSentMessageTranscript)

/**
 * Normally this is private, but we need to embed this
 * data structure within our own.
 *
 * recipientId is nil when building "sent" sync messages for messages
 * sent to groups.
 */
- (nullable SSKProtoDataMessage *)buildDataMessage:(NSString *_Nullable)recipientId;

@end

@interface OWSOutgoingSentMessageTranscript ()

@property (nonatomic, readonly) TSOutgoingMessage *message;
// sentRecipientId is the recipient of message, for contact thread messages.
// It is used to identify the thread/conversation to desktop.
@property (nonatomic, readonly, nullable) NSString *sentRecipientId;

@end

@implementation OWSOutgoingSentMessageTranscript

- (instancetype)initWithOutgoingMessage:(TSOutgoingMessage *)message
{
    self = [super init];

    if (!self) {
        return self;
    }

    _message = message;
    // This will be nil for groups.
    _sentRecipientId = message.thread.contactIdentifier;

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    return [super initWithCoder:coder];
}

- (nullable SSKProtoSyncMessageBuilder *)syncMessageBuilder
{
    SSKProtoSyncMessageSentBuilder *sentBuilder = [SSKProtoSyncMessageSent builder];
    [sentBuilder setTimestamp:self.message.timestamp];
    [sentBuilder setDestination:self.sentRecipientId];

    SSKProtoDataMessage *_Nullable dataMessage = [self.message buildDataMessage:self.sentRecipientId];
    if (!dataMessage) {
        OWSFailDebug(@"could not build protobuf.");
        return nil;
    }
    [sentBuilder setMessage:dataMessage];
    [sentBuilder setExpirationStartTimestamp:self.message.timestamp];

    for (NSString *recipientId in self.message.sentRecipientIds) {
        TSOutgoingMessageRecipientState *_Nullable recipientState =
            [self.message recipientStateForRecipientId:recipientId];
        if (!recipientState) {
            OWSFailDebug(@"missing recipient state for: %@", recipientId);
            continue;
        }
        if (recipientState.state != OWSOutgoingMessageRecipientStateSent) {
            OWSFailDebug(@"unexpected recipient state for: %@", recipientId);
            continue;
        }

        NSError *error;
        SSKProtoSyncMessageSentUnidentifiedDeliveryStatusBuilder *statusBuilder =
            [SSKProtoSyncMessageSentUnidentifiedDeliveryStatus builder];
        [statusBuilder setDestination:recipientId];
        [statusBuilder setUnidentified:recipientState.wasSentByUD];
        SSKProtoSyncMessageSentUnidentifiedDeliveryStatus *_Nullable status =
            [statusBuilder buildAndReturnError:&error];
        if (error || !status) {
            OWSFailDebug(@"Couldn't build UD status proto: %@", error);
            continue;
        }
        [sentBuilder addUnidentifiedStatus:status];
    }

    NSError *error;
    SSKProtoSyncMessageSent *_Nullable sentProto = [sentBuilder buildAndReturnError:&error];
    if (error || !sentProto) {
        OWSFailDebug(@"could not build protobuf: %@", error);
        return nil;
    }

    SSKProtoSyncMessageBuilder *syncMessageBuilder = [SSKProtoSyncMessage builder];
    [syncMessageBuilder setSent:sentProto];
    return syncMessageBuilder;
}

@end

NS_ASSUME_NONNULL_END
