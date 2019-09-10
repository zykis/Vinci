//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSYapDatabaseObject.h"

NS_ASSUME_NONNULL_BEGIN

@class TSThread;

typedef NS_ENUM(NSInteger, OWSInteractionType) {
    OWSInteractionType_Unknown,
    OWSInteractionType_IncomingMessage,
    OWSInteractionType_OutgoingMessage,
    OWSInteractionType_Error,
    OWSInteractionType_Call,
    OWSInteractionType_Info,
    OWSInteractionType_Offer,
    OWSInteractionType_TypingIndicator,
};

NSString *NSStringFromOWSInteractionType(OWSInteractionType value);

@protocol OWSPreviewText

- (NSString *)previewTextWithTransaction:(YapDatabaseReadTransaction *)transaction;

@end

@interface TSInteraction : TSYapDatabaseObject

- (instancetype)initInteractionWithUniqueId:(NSString *)uniqueId
                                  timestamp:(uint64_t)timestamp
                                   inThread:(TSThread *)thread;
- (instancetype)initInteractionWithTimestamp:(uint64_t)timestamp inThread:(TSThread *)thread;

@property (nonatomic, readonly) NSString *uniqueThreadId;
@property (nonatomic, readonly) TSThread *thread;
@property (nonatomic, readonly) uint64_t timestamp;
@property (nonatomic, readonly) uint64_t sortId;
@property (nonatomic, readonly) uint64_t receivedAtTimestamp;
- (NSDate *)receivedAtDate;

- (OWSInteractionType)interactionType;

- (TSThread *)threadWithTransaction:(YapDatabaseReadTransaction *)transaction;

/**
 * When an interaction is updated, it often affects the UI for it's containing thread. Touching it's thread will notify
 * any observers so they can redraw any related UI.
 */
- (void)touchThreadWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;

#pragma mark Utility Method

+ (NSArray<TSInteraction *> *)interactionsWithTimestamp:(uint64_t)timestamp
                                                ofClass:(Class)clazz
                                        withTransaction:(YapDatabaseReadTransaction *)transaction;

+ (NSArray<TSInteraction *> *)interactionsWithTimestamp:(uint64_t)timestamp
                                                 filter:(BOOL (^_Nonnull)(TSInteraction *))filter
                                        withTransaction:(YapDatabaseReadTransaction *)transaction;

- (NSDate *)dateForSorting;
- (uint64_t)timestampForSorting;
- (NSComparisonResult)compareForSorting:(TSInteraction *)other;

// "Dynamic" interactions are not messages or static events (like
// info messages, error messages, etc.).  They are interactions
// created, updated and deleted by the views.
//
// These include block offers, "add to contact" offers,
// unseen message indicators, etc.
- (BOOL)isDynamicInteraction;

- (void)saveNextSortIdWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
NS_SWIFT_NAME(saveNextSortId(transaction:));

@end

NS_ASSUME_NONNULL_END
