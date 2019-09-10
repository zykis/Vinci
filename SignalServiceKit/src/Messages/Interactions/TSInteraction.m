//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSInteraction.h"
#import "TSDatabaseSecondaryIndexes.h"
#import "TSThread.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>
#import <SignalCoreKit/NSDate+OWS.h>

NS_ASSUME_NONNULL_BEGIN

NSString *NSStringFromOWSInteractionType(OWSInteractionType value)
{
    switch (value) {
        case OWSInteractionType_Unknown:
            return @"OWSInteractionType_Unknown";
        case OWSInteractionType_IncomingMessage:
            return @"OWSInteractionType_IncomingMessage";
        case OWSInteractionType_OutgoingMessage:
            return @"OWSInteractionType_OutgoingMessage";
        case OWSInteractionType_Error:
            return @"OWSInteractionType_Error";
        case OWSInteractionType_Call:
            return @"OWSInteractionType_Call";
        case OWSInteractionType_Info:
            return @"OWSInteractionType_Info";
        case OWSInteractionType_Offer:
            return @"OWSInteractionType_Offer";
        case OWSInteractionType_TypingIndicator:
            return @"OWSInteractionType_TypingIndicator";
    }
}

@interface TSInteraction ()

@property (nonatomic) uint64_t sortId;

@end

@implementation TSInteraction

+ (NSArray<TSInteraction *> *)interactionsWithTimestamp:(uint64_t)timestamp
                                                ofClass:(Class)clazz
                                        withTransaction:(YapDatabaseReadTransaction *)transaction
{
    OWSAssertDebug(timestamp > 0);

    // Accept any interaction.
    return [self interactionsWithTimestamp:timestamp
                                    filter:^(TSInteraction *interaction) {
                                        return [interaction isKindOfClass:clazz];
                                    }
                           withTransaction:transaction];
}

+ (NSArray<TSInteraction *> *)interactionsWithTimestamp:(uint64_t)timestamp
                                                 filter:(BOOL (^_Nonnull)(TSInteraction *))filter
                                        withTransaction:(YapDatabaseReadTransaction *)transaction
{
    OWSAssertDebug(timestamp > 0);

    NSMutableArray<TSInteraction *> *interactions = [NSMutableArray new];

    [TSDatabaseSecondaryIndexes
        enumerateMessagesWithTimestamp:timestamp
                             withBlock:^(NSString *collection, NSString *key, BOOL *stop) {

                                 TSInteraction *interaction =
                                     [TSInteraction fetchObjectWithUniqueID:key transaction:transaction];
                                 if (!filter(interaction)) {
                                     return;
                                 }
                                 [interactions addObject:interaction];
                             }
                      usingTransaction:transaction];

    return [interactions copy];
}

+ (NSString *)collection {
    return @"TSInteraction";
}

- (instancetype)initInteractionWithUniqueId:(NSString *)uniqueId
                                  timestamp:(uint64_t)timestamp
                                   inThread:(TSThread *)thread
{
    OWSAssertDebug(timestamp > 0);

    self = [super initWithUniqueId:uniqueId];

    if (!self) {
        return self;
    }

    _timestamp = timestamp;
    _uniqueThreadId = thread.uniqueId;

    return self;
}

- (instancetype)initInteractionWithTimestamp:(uint64_t)timestamp inThread:(TSThread *)thread
{
    OWSAssertDebug(timestamp > 0);

    self = [super initWithUniqueId:[[NSUUID UUID] UUIDString]];

    if (!self) {
        return self;
    }

    _timestamp = timestamp;
    _uniqueThreadId = thread.uniqueId;
    _receivedAtTimestamp = [NSDate ows_millisecondTimeStamp];

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }
    
    // Previously the receivedAtTimestamp field lived on TSMessage, but we've moved it up
    // to the TSInteraction superclass.
    if (_receivedAtTimestamp == 0) {
        // Upgrade from the older "TSMessage.receivedAtDate" and "TSMessage.receivedAt" properties if
        // necessary.
        NSDate *receivedAtDate = [coder decodeObjectForKey:@"receivedAtDate"];
        if (!receivedAtDate) {
            receivedAtDate = [coder decodeObjectForKey:@"receivedAt"];
        }
        
        if (receivedAtDate) {
            _receivedAtTimestamp = [NSDate ows_millisecondsSince1970ForDate:receivedAtDate];
        }
        
        // For TSInteractions which are not TSMessage's, the timestamp *is* the receivedAtTimestamp
        if (_receivedAtTimestamp == 0) {
            _receivedAtTimestamp = _timestamp;
        }
    }
    
    return self;
}

#pragma mark Thread

- (TSThread *)thread
{
    return [TSThread fetchObjectWithUniqueID:self.uniqueThreadId];
}

- (TSThread *)threadWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [TSThread fetchObjectWithUniqueID:self.uniqueThreadId transaction:transaction];
}

- (void)touchThreadWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    TSThread *thread = [TSThread fetchObjectWithUniqueID:self.uniqueThreadId transaction:transaction];
    [thread touchWithTransaction:transaction];
}

#pragma mark Date operations

- (NSDate *)dateForSorting
{
    return [NSDate ows_dateWithMillisecondsSince1970:self.timestampForSorting];
}

- (uint64_t)timestampForSorting
{
    return self.timestamp;
}

- (NSDate *)receivedAtDate
{
    return [NSDate ows_dateWithMillisecondsSince1970:self.receivedAtTimestamp];
}

- (NSComparisonResult)compareForSorting:(TSInteraction *)other
{
//    OWSAssertDebug(other);
//
//    uint64_t timestamp1 = self.timestampForSorting;
//    uint64_t timestamp2 = other.timestampForSorting;
//
//    if (timestamp1 > timestamp2) {
//        return NSOrderedDescending;
//    } else if (timestamp1 < timestamp2) {
//        return NSOrderedAscending;
//    } else {
//        return NSOrderedSame;
//    }
    
    OWSAssertDebug(other);
    
    uint64_t sortId1 = self.sortId;
    uint64_t sortId2 = other.sortId;
    
    if (sortId1 > sortId2) {
        return NSOrderedDescending;
    } else if (sortId1 < sortId2) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}

- (OWSInteractionType)interactionType
{
    OWSFailDebug(@"unknown interaction type.");

    return OWSInteractionType_Unknown;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ in thread: %@ timestamp: %lu",
                     [super description],
                     self.uniqueThreadId,
                     (unsigned long)self.timestamp];
}

- (void)saveWithTransaction:(YapDatabaseReadWriteTransaction *)transaction {
    if (!self.uniqueId) {
        OWSFailDebug(self.uniqueId);
        self.uniqueId = [NSUUID new];
    }
    if (self.sortId == 0) {
        self.sortId = [SSKIncrementingIdFinder nextIdWithKey:[TSInteraction collection] transaction:transaction];
    }

    [super saveWithTransaction:transaction];

    TSThread *fetchedThread = [TSThread fetchObjectWithUniqueID:self.uniqueThreadId transaction:transaction];

    [fetchedThread updateWithLastMessage:self transaction:transaction];
}

- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    [super removeWithTransaction:transaction];

    [self touchThreadWithTransaction:transaction];
}

- (BOOL)isDynamicInteraction
{
    return NO;
}

#pragma mark - sorting migration

- (void)saveNextSortIdWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    if (self.sortId != 0) {
        // This could happen if something else in our startup process saved the interaction
        // e.g. another migration ran.
        // During the migration, since we're enumerating the interactions in the proper order,
        // we want to ignore any previously assigned sortId
        self.sortId = 0;
    }
    [self saveWithTransaction:transaction];
}

@end

NS_ASSUME_NONNULL_END
