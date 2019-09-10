//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSAccountManager.h"
#import "AppContext.h"
#import "AppReadiness.h"
#import "NSNotificationCenter+OWS.h"
#import "NSURLSessionDataTask+StatusCode.h"
#import "OWSError.h"
#import "OWSPrimaryStorage+SessionStore.h"
#import "OWSRequestFactory.h"
#import "ProfileManagerProtocol.h"
#import "SSKEnvironment.h"
#import "TSNetworkManager.h"
#import "TSPreKeyManager.h"
#import "YapDatabaseConnection+OWS.h"
#import "YapDatabaseTransaction+OWS.h"
#import <PromiseKit/AnyPromise.h>
#import <Reachability/Reachability.h>
#import <SignalCoreKit/NSData+OWS.h>
#import <SignalCoreKit/Randomness.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>
#import <YapDatabase/YapDatabase.h>

NS_ASSUME_NONNULL_BEGIN

NSString *const TSRegistrationErrorDomain = @"TSRegistrationErrorDomain";
NSString *const TSRegistrationErrorUserInfoHTTPStatus = @"TSHTTPStatus";
NSString *const RegistrationStateDidChangeNotification = @"RegistrationStateDidChangeNotification";
NSString *const DeregistrationStateDidChangeNotification = @"DeregistrationStateDidChangeNotification";
NSString *const kNSNotificationName_LocalNumberDidChange = @"kNSNotificationName_LocalNumberDidChange";

NSString *const TSAccountManager_RegisteredNumberKey = @"TSStorageRegisteredNumberKey";
NSString *const TSAccountManager_IsDeregisteredKey = @"TSAccountManager_IsDeregisteredKey";
NSString *const TSAccountManager_ReregisteringPhoneNumberKey = @"TSAccountManager_ReregisteringPhoneNumberKey";
NSString *const TSAccountManager_LocalRegistrationIdKey = @"TSStorageLocalRegistrationId";

NSString *const TSAccountManager_UserAccountCollection = @"TSStorageUserAccountCollection";
NSString *const TSAccountManager_ServerAuthToken = @"TSStorageServerAuthToken";
NSString *const TSAccountManager_ServerSignalingKey = @"TSStorageServerSignalingKey";
NSString *const TSAccountManager_ManualMessageFetchKey = @"TSAccountManager_ManualMessageFetchKey";
NSString *const TSAccountManager_NeedsAccountAttributesUpdateKey = @"TSAccountManager_NeedsAccountAttributesUpdateKey";

@interface TSAccountManager ()

@property (atomic, readonly) BOOL isRegistered;

// This property is exposed publicly for testing purposes only.
#ifndef DEBUG
@property (nonatomic, nullable) NSString *phoneNumberAwaitingVerification;
#endif

@property (nonatomic, nullable) NSString *cachedLocalNumber;
@property (nonatomic, readonly) YapDatabaseConnection *dbConnection;

@property (nonatomic, nullable) NSNumber *cachedIsDeregistered;

@property (nonatomic) Reachability *reachability;

@end

#pragma mark -

@implementation TSAccountManager

@synthesize isRegistered = _isRegistered;

- (instancetype)initWithPrimaryStorage:(OWSPrimaryStorage *)primaryStorage
{
    self = [super init];
    if (!self) {
        return self;
    }

    _dbConnection = [primaryStorage newDatabaseConnection];
    self.reachability = [Reachability reachabilityForInternetConnection];

    OWSSingletonAssert();

    if (!CurrentAppContext().isMainApp) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(yapDatabaseModifiedExternally:)
                                                     name:YapDatabaseModifiedExternallyNotification
                                                   object:nil];
    }

    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        [self updateAccountAttributesIfNecessary];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged)
                                                 name:kReachabilityChangedNotification
                                               object:nil];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)sharedInstance
{
    OWSAssertDebug(SSKEnvironment.shared.tsAccountManager);
    
    return SSKEnvironment.shared.tsAccountManager;
}

#pragma mark - Dependencies

- (TSNetworkManager *)networkManager
{
    OWSAssertDebug(SSKEnvironment.shared.networkManager);
    
    return SSKEnvironment.shared.networkManager;
}

- (id<ProfileManagerProtocol>)profileManager {
    OWSAssertDebug(SSKEnvironment.shared.profileManager);

    return SSKEnvironment.shared.profileManager;
}

#pragma mark -

- (void)setPhoneNumberAwaitingVerification:(NSString *_Nullable)phoneNumberAwaitingVerification
{
    _phoneNumberAwaitingVerification = phoneNumberAwaitingVerification;

    [[NSNotificationCenter defaultCenter] postNotificationNameAsync:kNSNotificationName_LocalNumberDidChange
                                                             object:nil
                                                           userInfo:nil];
}

+ (BOOL)isRegistered
{
    return [[self sharedInstance] isRegistered];
}

- (BOOL)isRegistered
{
    @synchronized (self) {
        if (_isRegistered) {
            return YES;
        } else {
            // Cache this once it's true since it's called alot, involves a dbLookup, and once set - it doesn't change.
            _isRegistered = [self storedLocalNumber] != nil;
        }
        return _isRegistered;
    }
}

- (void)didRegister
{
    OWSLogInfo(@"didRegister");
    NSString *phoneNumber = self.phoneNumberAwaitingVerification;

    if (!phoneNumber) {
        OWSFail(@"phoneNumber was unexpectedly nil");
    }

    [self storeLocalNumber:phoneNumber];

    [[NSNotificationCenter defaultCenter] postNotificationNameAsync:RegistrationStateDidChangeNotification
                                                             object:nil
                                                           userInfo:nil];

    // Warm these cached values.
    [self isRegistered];
    [self localNumber];
    [self isDeregistered];
}

+ (nullable NSString *)localNumber
{
    return [[self sharedInstance] localNumber];
}

- (nullable NSString *)localNumber
{
    NSString *awaitingVerif = self.phoneNumberAwaitingVerification;
    if (awaitingVerif) {
        return awaitingVerif;
    }

    // Cache this since we access this a lot, and once set it will not change.
    @synchronized(self)
    {
        if (self.cachedLocalNumber == nil) {
            self.cachedLocalNumber = self.storedLocalNumber;
        }
    }

    return self.cachedLocalNumber;
}

- (nullable NSString *)storedLocalNumber
{
    @synchronized (self) {
        return [self.dbConnection stringForKey:TSAccountManager_RegisteredNumberKey
                                  inCollection:TSAccountManager_UserAccountCollection];
    }
}

- (void)storeLocalNumber:(NSString *)localNumber
{
    @synchronized (self) {
        [self.dbConnection setObject:localNumber
                              forKey:TSAccountManager_RegisteredNumberKey
                        inCollection:TSAccountManager_UserAccountCollection];

        [self.dbConnection removeObjectForKey:TSAccountManager_ReregisteringPhoneNumberKey
                                 inCollection:TSAccountManager_UserAccountCollection];

        self.phoneNumberAwaitingVerification = nil;

        self.cachedLocalNumber = localNumber;
    }
}

+ (uint32_t)getOrGenerateRegistrationId:(YapDatabaseReadWriteTransaction *)transaction
{
    return [[self sharedInstance] getOrGenerateRegistrationId:transaction];
}

- (uint32_t)getOrGenerateRegistrationId
{
    __block uint32_t result;
    [self.dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        result = [self getOrGenerateRegistrationId:transaction];
    }];
    return result;
}

- (uint32_t)getOrGenerateRegistrationId:(YapDatabaseReadWriteTransaction *)transaction
{
    @synchronized(self)
    {
        uint32_t registrationID = [[transaction objectForKey:TSAccountManager_LocalRegistrationIdKey
                                                inCollection:TSAccountManager_UserAccountCollection] unsignedIntValue];

        if (registrationID == 0) {
            registrationID = (uint32_t)arc4random_uniform(16380) + 1;
            OWSLogWarn(@"Generated a new registrationID: %u", registrationID);

            [transaction setObject:[NSNumber numberWithUnsignedInteger:registrationID]
                            forKey:TSAccountManager_LocalRegistrationIdKey
                      inCollection:TSAccountManager_UserAccountCollection];
        }
        return registrationID;
    }
}

- (void)registerForPushNotificationsWithPushToken:(NSString *)pushToken
                                        voipToken:(NSString *)voipToken
                                          success:(void (^)(void))successHandler
                                          failure:(void (^)(NSError *))failureHandler
{
    [self registerForPushNotificationsWithPushToken:pushToken
                                          voipToken:voipToken
                                            success:successHandler
                                            failure:failureHandler
                                   remainingRetries:3];
}

- (void)registerForPushNotificationsWithPushToken:(NSString *)pushToken
                                        voipToken:(NSString *)voipToken
                                          success:(void (^)(void))successHandler
                                          failure:(void (^)(NSError *))failureHandler
                                 remainingRetries:(int)remainingRetries
{
    TSRequest *request =
        [OWSRequestFactory registerForPushRequestWithPushIdentifier:pushToken voipIdentifier:voipToken];
    [self.networkManager makeRequest:request
        success:^(NSURLSessionDataTask *task, id responseObject) {
            successHandler();
        }
        failure:^(NSURLSessionDataTask *task, NSError *error) {
            if (remainingRetries > 0) {
                [self registerForPushNotificationsWithPushToken:pushToken
                                                      voipToken:voipToken
                                                        success:successHandler
                                                        failure:failureHandler
                                               remainingRetries:remainingRetries - 1];
            } else {
                if (!IsNSErrorNetworkFailure(error)) {
                    OWSProdError([OWSAnalyticsEvents accountsErrorRegisterPushTokensFailed]);
                }
                failureHandler(error);
            }
        }];
}

+ (void)registerWithPhoneNumber:(NSString *)phoneNumber
                        success:(void (^)(void))successBlock
                        failure:(void (^)(NSError *error))failureBlock
                smsVerification:(BOOL)isSMS

{
    if ([self isRegistered]) {
        failureBlock([NSError errorWithDomain:@"tsaccountmanager.verify" code:4000 userInfo:nil]);
        return;
    }

    // The country code of TSAccountManager.phoneNumberAwaitingVerification is used to
    // determine whether or not to use domain fronting, so it needs to be set _before_
    // we make our verification code request.
    TSAccountManager *manager = [self sharedInstance];
    manager.phoneNumberAwaitingVerification = phoneNumber;

    TSRequest *request =
        [OWSRequestFactory requestVerificationCodeRequestWithPhoneNumber:phoneNumber
                                                               transport:(isSMS ? TSVerificationTransportSMS
                                                                                : TSVerificationTransportVoice)];
    [[TSNetworkManager sharedManager] makeRequest:request
        success:^(NSURLSessionDataTask *task, id responseObject) {
            OWSLogInfo(@"Successfully requested verification code request for number: %@ method:%@",
                phoneNumber,
                isSMS ? @"SMS" : @"Voice");
            successBlock();
        }
        failure:^(NSURLSessionDataTask *task, NSError *error) {
            if (!IsNSErrorNetworkFailure(error)) {
                OWSProdError([OWSAnalyticsEvents accountsErrorVerificationCodeRequestFailed]);
            }
            OWSLogError(@"Failed to request verification code request with error:%@", error);
            failureBlock(error);
        }];
}

+ (void)rerequestSMSWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock
{
    TSAccountManager *manager = [self sharedInstance];
    NSString *number          = manager.phoneNumberAwaitingVerification;

    OWSAssertDebug(number);

    [self registerWithPhoneNumber:number success:successBlock failure:failureBlock smsVerification:YES];
}

+ (void)rerequestVoiceWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock
{
    TSAccountManager *manager = [self sharedInstance];
    NSString *number          = manager.phoneNumberAwaitingVerification;

    OWSAssertDebug(number);

    [self registerWithPhoneNumber:number success:successBlock failure:failureBlock smsVerification:NO];
}

- (void)verifyAccountWithCode:(NSString *)verificationCode
                          pin:(nullable NSString *)pin
                      success:(void (^)(void))successBlock
                      failure:(void (^)(NSError *error))failureBlock
{
    NSString *authToken = [[self class] generateNewAccountAuthenticationToken];
    NSString *signalingKey = [[self class] generateNewSignalingKeyToken];
    NSString *phoneNumber = self.phoneNumberAwaitingVerification;

    OWSAssertDebug(signalingKey);
    OWSAssertDebug(authToken);
    OWSAssertDebug(phoneNumber);

    TSRequest *request = [OWSRequestFactory verifyCodeRequestWithVerificationCode:verificationCode
                                                                        forNumber:phoneNumber
                                                                              pin:pin
                                                                     signalingKey:signalingKey
                                                                          authKey:authToken];

    [self.networkManager makeRequest:request
        success:^(NSURLSessionDataTask *task, id responseObject) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            long statuscode = response.statusCode;

            switch (statuscode) {
                case 200:
                case 204: {
                    OWSLogInfo(@"Verification code accepted.");
                    [self storeServerAuthToken:authToken signalingKey:signalingKey];
                    [TSPreKeyManager createPreKeysWithSuccess:successBlock failure:failureBlock];
                    [self.profileManager fetchLocalUsersProfile];
                    break;
                }
                default: {
                    OWSLogError(@"Unexpected status while verifying code: %ld", statuscode);
                    NSError *error = OWSErrorMakeUnableToProcessServerResponseError();
                    failureBlock(error);
                    break;
                }
            }
        }
        failure:^(NSURLSessionDataTask *task, NSError *error) {
            if (!IsNSErrorNetworkFailure(error)) {
                OWSProdError([OWSAnalyticsEvents accountsErrorVerifyAccountRequestFailed]);
            }
            OWSAssertDebug([error.domain isEqualToString:TSNetworkManagerErrorDomain]);

            OWSLogWarn(@"Error verifying code: %@", error.debugDescription);

            switch (error.code) {
                case 403: {
                    NSError *userError = OWSErrorWithCodeDescription(OWSErrorCodeUserError,
                        NSLocalizedString(@"REGISTRATION_VERIFICATION_FAILED_WRONG_CODE_DESCRIPTION",
                            "Error message indicating that registration failed due to a missing or incorrect "
                            "verification code."));
                    failureBlock(userError);
                    break;
                }
                case 413: {
                    // In the case of the "rate limiting" error, we want to show the
                    // "recovery suggestion", not the error's "description."
                    NSError *userError
                        = OWSErrorWithCodeDescription(OWSErrorCodeUserError, error.localizedRecoverySuggestion);
                    failureBlock(userError);
                    break;
                }
                case 423: {
                    NSString *localizedMessage = NSLocalizedString(@"REGISTRATION_VERIFICATION_FAILED_WRONG_PIN",
                        "Error message indicating that registration failed due to a missing or incorrect 2FA PIN.");
                    OWSLogError(@"2FA PIN required: %ld", (long)error.code);
                    NSError *error
                        = OWSErrorWithCodeDescription(OWSErrorCodeRegistrationMissing2FAPIN, localizedMessage);
                    failureBlock(error);
                    break;
                }
                default: {
                    OWSLogError(@"verifying code failed with unknown error: %@", error);
                    failureBlock(error);
                    break;
                }
            }
        }];
}

#pragma mark Server keying material

+ (NSString *)generateNewAccountAuthenticationToken {
    NSData *authToken = [Randomness generateRandomBytes:16];
    NSString *authTokenPrint = [[NSData dataWithData:authToken] hexadecimalString];
    return authTokenPrint;
}

+ (NSString *)generateNewSignalingKeyToken {
    /*The signalingKey is 32 bytes of AES material (256bit AES) and 20 bytes of
     * Hmac key material (HmacSHA1) concatenated into a 52 byte slug that is
     * base64 encoded. */
    NSData *signalingKeyToken = [Randomness generateRandomBytes:52];
    NSString *signalingKeyTokenPrint = [[NSData dataWithData:signalingKeyToken] base64EncodedString];
    return signalingKeyTokenPrint;
}

+ (nullable NSString *)signalingKey
{
    return [[self sharedInstance] signalingKey];
}

- (nullable NSString *)signalingKey
{
    return [self.dbConnection stringForKey:TSAccountManager_ServerSignalingKey
                              inCollection:TSAccountManager_UserAccountCollection];
}

+ (nullable NSString *)serverAuthToken
{
    return [[self sharedInstance] serverAuthToken];
}

- (nullable NSString *)serverAuthToken
{
    return [self.dbConnection stringForKey:TSAccountManager_ServerAuthToken
                              inCollection:TSAccountManager_UserAccountCollection];
}

- (void)storeServerAuthToken:(NSString *)authToken signalingKey:(NSString *)signalingKey
{
    [self.dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:authToken
                        forKey:TSAccountManager_ServerAuthToken
                  inCollection:TSAccountManager_UserAccountCollection];
        [transaction setObject:signalingKey
                        forKey:TSAccountManager_ServerSignalingKey
                  inCollection:TSAccountManager_UserAccountCollection];

    }];
}

+ (void)unregisterTextSecureWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failureBlock
{
    TSRequest *request = [OWSRequestFactory unregisterAccountRequest];
    [[TSNetworkManager sharedManager] makeRequest:request
        success:^(NSURLSessionDataTask *task, id responseObject) {
            OWSLogInfo(@"Successfully unregistered");
            success();

            // This is called from `[AppSettingsViewController proceedToUnregistration]` whose
            // success handler calls `[Environment resetAppData]`.
            // This method, after calling that success handler, fires
            // `RegistrationStateDidChangeNotification` which is only safe to fire after
            // the data store is reset.

            [[NSNotificationCenter defaultCenter] postNotificationNameAsync:RegistrationStateDidChangeNotification
                                                                     object:nil
                                                                   userInfo:nil];
        }
        failure:^(NSURLSessionDataTask *task, NSError *error) {
            if (!IsNSErrorNetworkFailure(error)) {
                OWSProdError([OWSAnalyticsEvents accountsErrorUnregisterAccountRequestFailed]);
            }
            OWSLogError(@"Failed to unregister with error: %@", error);
            failureBlock(error);
        }];
}

- (void)yapDatabaseModifiedExternally:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    OWSLogVerbose(@"");

    // Any database write by the main app might reflect a deregistration,
    // so clear the cached "is registered" state.  This will significantly
    // erode the value of this cache in the SAE.
    @synchronized(self)
    {
        _isRegistered = NO;
    }
}

#pragma mark - De-Registration

- (BOOL)isDeregistered
{
    // Cache this since we access this a lot, and once set it will not change.
    @synchronized(self) {
        if (self.cachedIsDeregistered == nil) {
            self.cachedIsDeregistered = @([self.dbConnection boolForKey:TSAccountManager_IsDeregisteredKey
                                                           inCollection:TSAccountManager_UserAccountCollection
                                                           defaultValue:NO]);
        }

        OWSAssertDebug(self.cachedIsDeregistered);
        return self.cachedIsDeregistered.boolValue;
    }
}

- (void)setIsDeregistered:(BOOL)isDeregistered
{
    @synchronized(self) {
        if (self.cachedIsDeregistered && self.cachedIsDeregistered.boolValue == isDeregistered) {
            return;
        }

        OWSLogWarn(@"isDeregistered: %d", isDeregistered);

        self.cachedIsDeregistered = @(isDeregistered);
    }

    [self.dbConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [transaction setObject:@(isDeregistered)
                        forKey:TSAccountManager_IsDeregisteredKey
                  inCollection:TSAccountManager_UserAccountCollection];
    }];

    [[NSNotificationCenter defaultCenter] postNotificationNameAsync:DeregistrationStateDidChangeNotification
                                                             object:nil
                                                           userInfo:nil];
}

#pragma mark - Re-registration

- (BOOL)resetForReregistration
{
    @synchronized(self) {
        NSString *_Nullable localNumber = self.localNumber;
        if (!localNumber) {
            OWSFailDebug(@"can't re-register without valid local number.");
            return NO;
        }

        _isRegistered = NO;
        _cachedLocalNumber = nil;
        _phoneNumberAwaitingVerification = nil;
        _cachedIsDeregistered = nil;
        [self.dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [transaction removeAllObjectsInCollection:TSAccountManager_UserAccountCollection];

            [[OWSPrimaryStorage sharedManager] resetSessionStore:transaction];

            [transaction setObject:localNumber
                            forKey:TSAccountManager_ReregisteringPhoneNumberKey
                      inCollection:TSAccountManager_UserAccountCollection];
        }];
        return YES;
    }
}

- (NSString *)reregisterationPhoneNumber
{
    OWSAssertDebug([self isReregistering]);

    NSString *_Nullable result = [self.dbConnection stringForKey:TSAccountManager_ReregisteringPhoneNumberKey
                                                    inCollection:TSAccountManager_UserAccountCollection];
    OWSAssertDebug(result);
    return result;
}

- (BOOL)isReregistering
{
    return nil !=
        [self.dbConnection stringForKey:TSAccountManager_ReregisteringPhoneNumberKey
                           inCollection:TSAccountManager_UserAccountCollection];
}

- (BOOL)isManualMessageFetchEnabled
{
    return [self.dbConnection boolForKey:TSAccountManager_ManualMessageFetchKey
                            inCollection:TSAccountManager_UserAccountCollection
                            defaultValue:NO];
}

- (AnyPromise *)setIsManualMessageFetchEnabled:(BOOL)value {
    [self.dbConnection setBool:value
                        forKey:TSAccountManager_ManualMessageFetchKey
                  inCollection:TSAccountManager_UserAccountCollection];

    // Try to update the account attributes to reflect this change.
    return [self updateAccountAttributes];
}

- (void)registerForTestsWithLocalNumber:(NSString *)localNumber
{
    OWSAssertDebug(localNumber.length > 0);
    
    [self storeLocalNumber:localNumber];
}

#pragma mark - Account Attributes

- (AnyPromise *)updateAccountAttributes {
    // Enqueue a "account attribute update", recording the "request time".
    [self.dbConnection setObject:[NSDate new]
                          forKey:TSAccountManager_NeedsAccountAttributesUpdateKey
                    inCollection:TSAccountManager_UserAccountCollection];

    return [self updateAccountAttributesIfNecessary];
}

- (AnyPromise *)updateAccountAttributesIfNecessary {
    if (!self.isRegistered) {
        return [AnyPromise promiseWithValue:@(1)];
    }

    NSDate *_Nullable updateRequestDate =
        [self.dbConnection objectForKey:TSAccountManager_NeedsAccountAttributesUpdateKey
                           inCollection:TSAccountManager_UserAccountCollection];
    if (!updateRequestDate) {
        return [AnyPromise promiseWithValue:@(1)];
    }

    AnyPromise *promise = [[SignalServiceRestClient new] updateAccountAttributesObjC];
    promise = promise.then(^(id value) {
        [self.dbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            // Clear the update request unless a new update has been requested
            // while this update was in flight.
            NSDate *_Nullable latestUpdateRequestDate =
                [transaction objectForKey:TSAccountManager_NeedsAccountAttributesUpdateKey
                             inCollection:TSAccountManager_UserAccountCollection];
            if (latestUpdateRequestDate && [latestUpdateRequestDate isEqual:updateRequestDate]) {
                [transaction removeObjectForKey:TSAccountManager_NeedsAccountAttributesUpdateKey
                                   inCollection:TSAccountManager_UserAccountCollection];
            }
        }];

        // Fetch the local profile, as we may have changed its
        // account attributes.  Specifically, we need to determine
        // if all devices for our account now support UD for sync
        // messages.
        [self.profileManager fetchLocalUsersProfile];
    });
    [promise retainUntilComplete];
    return promise;
}

- (void)reachabilityChanged {
    OWSAssertIsOnMainThread();

    [AppReadiness runNowOrWhenAppDidBecomeReady:^{
        [self updateAccountAttributesIfNecessary];
    }];
}

@end

NS_ASSUME_NONNULL_END
