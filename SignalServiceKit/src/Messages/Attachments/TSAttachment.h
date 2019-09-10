//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSYapDatabaseObject.h"

NS_ASSUME_NONNULL_BEGIN

@class TSMessage;

typedef NS_ENUM(NSUInteger, TSAttachmentType) {
    TSAttachmentTypeDefault = 0,
    TSAttachmentTypeVoiceMessage = 1,
};

@interface TSAttachment : TSYapDatabaseObject {

@protected
    NSString *_contentType;
}

// TSAttachment is a base class for TSAttachmentPointer (a yet-to-be-downloaded
// incoming attachment) and TSAttachmentStream (an outgoing or already-downloaded
// incoming attachment).
//
// The attachmentSchemaVersion and serverId properties only apply to
// TSAttachmentPointer, which can be distinguished by the isDownloaded
// property.
@property (atomic, readwrite) UInt64 serverId;
@property (atomic, readwrite) NSData *encryptionKey;
@property (nonatomic, readonly) NSString *contentType;
@property (atomic, readwrite) BOOL isDownloaded;
@property (nonatomic) TSAttachmentType attachmentType;

// Though now required, may incorrectly be 0 on legacy attachments.
@property (nonatomic, readonly) UInt32 byteCount;

// Represents the "source" filename sent or received in the protos,
// not the filename on disk.
@property (nonatomic, readonly, nullable) NSString *sourceFilename;

#pragma mark - Media Album

@property (nonatomic, readonly, nullable) NSString *caption;
@property (nonatomic, readonly, nullable) NSString *albumMessageId;
- (nullable TSMessage *)fetchAlbumMessageWithTransaction:(YapDatabaseReadTransaction *)transaction;

// `migrateAlbumMessageId` is only used in the migration to the new multi-attachment message scheme,
// and shouldn't be used as a general purpose setter. Instead, `albumMessageId` should be passed as
// an initializer param.
- (void)migrateAlbumMessageId:(NSString *)albumMesssageId;

#pragma mark -

// This constructor is used for new instances of TSAttachmentPointer,
// i.e. undownloaded incoming attachments.
- (instancetype)initWithServerId:(UInt64)serverId
                   encryptionKey:(NSData *)encryptionKey
                       byteCount:(UInt32)byteCount
                     contentType:(NSString *)contentType
                  sourceFilename:(nullable NSString *)sourceFilename
                         caption:(nullable NSString *)caption
                  albumMessageId:(nullable NSString *)albumMessageId;

// This constructor is used for new instances of TSAttachmentStream
// that represent new, un-uploaded outgoing attachments.
- (instancetype)initWithContentType:(NSString *)contentType
                          byteCount:(UInt32)byteCount
                     sourceFilename:(nullable NSString *)sourceFilename
                            caption:(nullable NSString *)caption
                     albumMessageId:(nullable NSString *)albumMessageId;

// This constructor is used for new instances of TSAttachmentStream
// that represent downloaded incoming attachments.
- (instancetype)initWithPointer:(TSAttachment *)pointer;

- (nullable instancetype)initWithCoder:(NSCoder *)coder;

- (void)upgradeFromAttachmentSchemaVersion:(NSUInteger)attachmentSchemaVersion;

@property (nonatomic, readonly) BOOL isAnimated;
@property (nonatomic, readonly) BOOL isImage;
@property (nonatomic, readonly) BOOL isVideo;
@property (nonatomic, readonly) BOOL isAudio;
@property (nonatomic, readonly) BOOL isVoiceMessage;
@property (nonatomic, readonly) BOOL isVisualMedia;

+ (NSString *)emojiForMimeType:(NSString *)contentType;

@end

NS_ASSUME_NONNULL_END
