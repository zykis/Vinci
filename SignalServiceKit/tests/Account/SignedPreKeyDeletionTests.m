//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSPrimaryStorage+SignedPreKeyStore.h"
#import "SSKBaseTestObjC.h"
#import "TSPreKeyManager.h"
#import <AxolotlKit/SignedPrekeyRecord.h>

@interface  TSPreKeyManager (Testing)

+ (void)clearSignedPreKeyRecordsWithKeyId:(NSNumber *)keyId;

@end

@interface SignedPreKeyDeletionTests : SSKBaseTestObjC

@end

@implementation SignedPreKeyDeletionTests

#ifdef BROKEN_TESTS

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSignedPreKeyDeletion {
    [self readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        XCTAssertEqual(0, [transaction numberOfKeysInCollection:OWSPrimaryStorageSignedPreKeyStoreCollection]);
    }];

    int days = 20;
    int lastPreKeyId = days;

    for (int i = 0; i <= days; i++) { // 21 signed keys are generated, one per day from now until 20 days ago.
        int secondsAgo = (i - days) * 24 * 60 * 60;
        NSAssert(secondsAgo <= 0, @"Time in past must be negative");
        NSDate *generatedAt = [NSDate dateWithTimeIntervalSinceNow:secondsAgo];
        SignedPreKeyRecord *record = [[SignedPreKeyRecord alloc] initWithId:i
                                                                    keyPair:[Curve25519 generateKeyPair]
                                                                  signature:[NSData new]
                                                                generatedAt:generatedAt];
        [[OWSPrimaryStorage sharedManager] storeSignedPreKey:i signedPreKeyRecord:record];
    }

    NSArray<SignedPreKeyRecord *> *signedPreKeys = [[OWSPrimaryStorage sharedManager] loadSignedPreKeys];
    // Sanity check
    XCTAssert(signedPreKeys.count == 21);

    [TSPreKeyManager clearSignedPreKeyRecordsWithKeyId:@(lastPreKeyId)];
    XCTAssert([[OWSPrimaryStorage sharedManager] loadSignedPrekey:lastPreKeyId] != nil);

    // We'll delete every key created 7 or more days ago.
    signedPreKeys = [[OWSPrimaryStorage sharedManager] loadSignedPreKeys];
    XCTAssert(signedPreKeys.count == 7);
}

- (void)testSignedPreKeyDeletionKeepsSomeOldKeys
{
    [self readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        XCTAssertEqual(0, [transaction numberOfKeysInCollection:OWSPrimaryStorageSignedPreKeyStoreCollection]);
    }];

    int lastPreKeyId = 10;
    for (int i = 0; i <= 10; i++) {
        // All these keys will be considered "old", since they were created more than 7 days ago.
        int secondsAgo = (i - 20) * 24 * 60 * 60;
        NSAssert(secondsAgo <= 0, @"Time in past must be negative");
        NSDate *generatedAt = [NSDate dateWithTimeIntervalSinceNow:secondsAgo];
        SignedPreKeyRecord *record = [[SignedPreKeyRecord alloc] initWithId:i
                                                                    keyPair:[Curve25519 generateKeyPair]
                                                                  signature:[NSData new]
                                                                generatedAt:generatedAt];
        // we only retain accepted keys
        [record markAsAcceptedByService];
        [[OWSPrimaryStorage sharedManager] storeSignedPreKey:i signedPreKeyRecord:record];
    }


    NSArray<SignedPreKeyRecord *> *signedPreKeys = [[OWSPrimaryStorage sharedManager] loadSignedPreKeys];
    // Sanity check
    XCTAssert(signedPreKeys.count == 11);

    [TSPreKeyManager clearSignedPreKeyRecordsWithKeyId:@(lastPreKeyId)];

    XCTAssert([[OWSPrimaryStorage sharedManager] loadSignedPrekey:lastPreKeyId] != nil);

    signedPreKeys = [[OWSPrimaryStorage sharedManager] loadSignedPreKeys];

    // We need to keep 3 "old" keys, plus the "current" key
    XCTAssert(signedPreKeys.count == 4);
}

- (void)testOlderRecordsNotDeletedIfNoReplacement {

    [self readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        XCTAssertEqual(0, [transaction numberOfKeysInCollection:OWSPrimaryStorageSignedPreKeyStoreCollection]);
    }];

    int days = 3;
    int lastPreKeyId = days;

    for (int i = 0; i <= days; i++) { // 4 signed keys are generated, one per day from now until 3 days ago.
        int secondsAgo = (i - days) * 24 * 60 * 60;
        NSAssert(secondsAgo <= 0, @"Time in past must be negative");
        NSDate *generatedAt = [NSDate dateWithTimeIntervalSinceNow:secondsAgo];
        SignedPreKeyRecord *record = [[SignedPreKeyRecord alloc] initWithId:i
                                                                    keyPair:[Curve25519 generateKeyPair]
                                                                  signature:[NSData new]
                                                                generatedAt:generatedAt];
        [[OWSPrimaryStorage sharedManager] storeSignedPreKey:i signedPreKeyRecord:record];
    }

    NSArray<SignedPreKeyRecord *> *signedPreKeys = [[OWSPrimaryStorage sharedManager] loadSignedPreKeys];
    // Sanity check
    XCTAssert(signedPreKeys.count == 4);

    [TSPreKeyManager clearSignedPreKeyRecordsWithKeyId:@(lastPreKeyId)];
    XCTAssert([[OWSPrimaryStorage sharedManager] loadSignedPrekey:lastPreKeyId] != nil);

    // All three records should still be stored.
    signedPreKeys = [[OWSPrimaryStorage sharedManager] loadSignedPreKeys];
    XCTAssert(signedPreKeys.count == 4);
}

#endif

@end
