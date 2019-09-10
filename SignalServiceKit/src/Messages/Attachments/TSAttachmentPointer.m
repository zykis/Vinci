//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSAttachmentPointer.h"
#import <SignalServiceKit/MimeTypeUtil.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@implementation TSAttachmentPointer

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    // A TSAttachmentPointer is a yet-to-be-downloaded attachment.
    // If this is an old TSAttachmentPointer from another session,
    // we know that it failed to complete before the session completed.
    if (![coder containsValueForKey:@"state"]) {
        _state = TSAttachmentPointerStateFailed;
    }

    return self;
}

- (instancetype)initWithServerId:(UInt64)serverId
                             key:(NSData *)key
                          digest:(nullable NSData *)digest
                       byteCount:(UInt32)byteCount
                     contentType:(NSString *)contentType
                  sourceFilename:(nullable NSString *)sourceFilename
                         caption:(nullable NSString *)caption
                  albumMessageId:(nullable NSString *)albumMessageId
                  attachmentType:(TSAttachmentType)attachmentType
{
    self = [super initWithServerId:serverId
                     encryptionKey:key
                         byteCount:byteCount
                       contentType:contentType
                    sourceFilename:sourceFilename
                           caption:caption
                    albumMessageId:albumMessageId];
    if (!self) {
        return self;
    }

    _digest = digest;
    _state = TSAttachmentPointerStateEnqueued;
    self.attachmentType = attachmentType;

    return self;
}

+ (nullable TSAttachmentPointer *)attachmentPointerFromProto:(SSKProtoAttachmentPointer *)attachmentProto
                                                albumMessage:(nullable TSMessage *)albumMessage
{
    if (attachmentProto.id < 1) {
        OWSFailDebug(@"Invalid attachment id.");
        return nil;
    }
    if (attachmentProto.key.length < 1) {
        OWSFailDebug(@"Invalid attachment key.");
        return nil;
    }
    if (attachmentProto.contentType.length < 1) {
        OWSFailDebug(@"Invalid attachment content type.");
        return nil;
    }

    // digest will be empty for old clients.
    NSData *_Nullable digest = attachmentProto.hasDigest ? attachmentProto.digest : nil;

    TSAttachmentType attachmentType = TSAttachmentTypeDefault;
    if ([attachmentProto hasFlags]) {
        UInt32 flags = attachmentProto.flags;
        if ((flags & (UInt32)SSKProtoAttachmentPointerFlagsVoiceMessage) > 0) {
            attachmentType = TSAttachmentTypeVoiceMessage;
        }
    }
    NSString *_Nullable caption;
    if (attachmentProto.hasCaption) {
        caption = attachmentProto.caption;
    }

    NSString *_Nullable albumMessageId;
    if (albumMessage != nil) {
        albumMessageId = albumMessage.uniqueId;
    }

    TSAttachmentPointer *pointer = [[TSAttachmentPointer alloc] initWithServerId:attachmentProto.id
                                                                             key:attachmentProto.key
                                                                          digest:digest
                                                                       byteCount:attachmentProto.size
                                                                     contentType:attachmentProto.contentType
                                                                  sourceFilename:attachmentProto.fileName
                                                                         caption:caption
                                                                  albumMessageId:albumMessageId
                                                                  attachmentType:attachmentType];
    return pointer;
}

+ (NSArray<TSAttachmentPointer *> *)attachmentPointersFromProtos:
                                        (NSArray<SSKProtoAttachmentPointer *> *)attachmentProtos
                                                    albumMessage:(TSMessage *)albumMessage
{
    OWSAssertDebug(attachmentProtos);
    OWSAssertDebug(albumMessage);

    NSMutableArray *attachmentPointers = [NSMutableArray new];
    for (SSKProtoAttachmentPointer *attachmentProto in attachmentProtos) {
        TSAttachmentPointer *_Nullable attachmentPointer =
            [self attachmentPointerFromProto:attachmentProto albumMessage:albumMessage];
        if (attachmentPointer) {
            [attachmentPointers addObject:attachmentPointer];
        }
    }
    return [attachmentPointers copy];
}

- (BOOL)isDecimalNumberText:(NSString *)text
{
    return [text componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]].count == 1;
}

- (void)upgradeFromAttachmentSchemaVersion:(NSUInteger)attachmentSchemaVersion
{
    // Legacy instances of TSAttachmentPointer apparently used the serverId as their
    // uniqueId.
    if (attachmentSchemaVersion < 2 && self.serverId == 0) {
        OWSAssertDebug([self isDecimalNumberText:self.uniqueId]);
        if ([self isDecimalNumberText:self.uniqueId]) {
            // For legacy instances, try to parse the serverId from the uniqueId.
            self.serverId = [self.uniqueId integerValue];
        } else {
            OWSLogError(@"invalid legacy attachment uniqueId: %@.", self.uniqueId);
        }
    }
}

@end

NS_ASSUME_NONNULL_END
