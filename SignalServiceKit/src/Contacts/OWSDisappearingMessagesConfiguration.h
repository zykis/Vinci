//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSYapDatabaseObject.h"

NS_ASSUME_NONNULL_BEGIN

#define OWSDisappearingMessagesConfigurationDefaultExpirationDuration kDayInterval

@class YapDatabaseReadTransaction;

@interface OWSDisappearingMessagesConfiguration : TSYapDatabaseObject

- (instancetype)initDefaultWithThreadId:(NSString *)threadId;

- (instancetype)initWithThreadId:(NSString *)threadId enabled:(BOOL)isEnabled durationSeconds:(uint32_t)seconds;

@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic) uint32_t durationSeconds;
@property (nonatomic, readonly) NSUInteger durationIndex;
@property (nonatomic, readonly) NSString *durationString;
@property (nonatomic, readonly) BOOL dictionaryValueDidChange;
@property (readonly, getter=isNewRecord) BOOL newRecord;

+ (instancetype)fetchOrBuildDefaultWithThreadId:(NSString *)threadId
                                    transaction:(YapDatabaseReadTransaction *)transaction;

+ (NSArray<NSNumber *> *)validDurationsSeconds;
+ (uint32_t)maxDurationSeconds;

@end

NS_ASSUME_NONNULL_END
