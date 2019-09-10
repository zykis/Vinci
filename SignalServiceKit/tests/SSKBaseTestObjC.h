//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import <SignalServiceKit/MockSSKEnvironment.h>
#import <XCTest/XCTest.h>
#import <YapDatabase/YapDatabaseConnection.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG

@interface SSKBaseTestObjC : XCTestCase

- (void)readWithBlock:(void (^)(YapDatabaseReadTransaction *transaction))block;

- (void)readWriteWithBlock:(void (^)(YapDatabaseReadWriteTransaction *transaction))block;

@end

#endif

NS_ASSUME_NONNULL_END
