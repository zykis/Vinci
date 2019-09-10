//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "SSKBaseTestObjC.h"
#import "OWSPrimaryStorage.h"
#import "SSKEnvironment.h"
#import "TestAppContext.h"

@import CocoaLumberjack;
#import <CocoaLumberjack/DDTTYLogger.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef DEBUG

@implementation SSKBaseTestObjC

- (void)setUp
{
    OWSLogInfo(@"%@ setUp", self.logTag);

    [super setUp];

    [DDLog addLogger:DDTTYLogger.sharedInstance];

    ClearCurrentAppContextForTests();
    SetCurrentAppContext([TestAppContext new]);

    [MockSSKEnvironment activate];
}

- (void)tearDown
{
    OWSLogInfo(@"%@ tearDown", self.logTag);

    [super tearDown];
}

- (void)readWithBlock:(void (^)(YapDatabaseReadTransaction *transaction))block
{
    OWSAssert(block);

    [[SSKEnvironment.shared.primaryStorage newDatabaseConnection] readWithBlock:block];
}


- (void)readWriteWithBlock:(void (^)(YapDatabaseReadWriteTransaction *transaction))block
{
    OWSAssert(block);

    [[SSKEnvironment.shared.primaryStorage newDatabaseConnection] readWriteWithBlock:block];
}

@end

#endif

NS_ASSUME_NONNULL_END
