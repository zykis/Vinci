//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSYapDatabaseObject.h"

NS_ASSUME_NONNULL_BEGIN

// SignalRecipient serves two purposes:
//
// a) It serves as a cache of "known" Signal accounts.  When the service indicates
//    that an account exists, we make sure that an instance of SignalRecipient exists
//    for that recipient id (using mark as registered) and has at least one device.
//    When the service indicates that an account does not exist, we remove any devices
//    from that SignalRecipient - but do not remove it from the database.
//    Note that SignalRecipients without any devices are not considered registered.
//// b) We hang the "known device list" for known signal accounts on this entity.
@interface SignalRecipient : TSYapDatabaseObject

@property (nonatomic, readonly) NSOrderedSet *devices;

- (instancetype)init NS_UNAVAILABLE;

+ (nullable instancetype)registeredRecipientForRecipientId:(NSString *)recipientId
                                           mustHaveDevices:(BOOL)mustHaveDevices
                                               transaction:(YapDatabaseReadTransaction *)transaction;
+ (instancetype)getOrBuildUnsavedRecipientForRecipientId:(NSString *)recipientId
                                             transaction:(YapDatabaseReadTransaction *)transaction;

- (void)updateRegisteredRecipientWithDevicesToAdd:(nullable NSArray *)devicesToAdd
                                  devicesToRemove:(nullable NSArray *)devicesToRemove
                                      transaction:(YapDatabaseReadWriteTransaction *)transaction;

- (NSString *)recipientId;

- (NSComparisonResult)compare:(SignalRecipient *)other;

+ (BOOL)isRegisteredRecipient:(NSString *)recipientId transaction:(YapDatabaseReadTransaction *)transaction;

+ (SignalRecipient *)markRecipientAsRegisteredAndGet:(NSString *)recipientId
                                         transaction:(YapDatabaseReadWriteTransaction *)transaction;
+ (void)markRecipientAsRegistered:(NSString *)recipientId
                         deviceId:(UInt32)deviceId
                      transaction:(YapDatabaseReadWriteTransaction *)transaction;
+ (void)markRecipientAsUnregistered:(NSString *)recipientId transaction:(YapDatabaseReadWriteTransaction *)transaction;

@end

NS_ASSUME_NONNULL_END
