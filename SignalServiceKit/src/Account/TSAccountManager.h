//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSConstants.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const TSRegistrationErrorDomain;
extern NSString *const TSRegistrationErrorUserInfoHTTPStatus;
extern NSString *const RegistrationStateDidChangeNotification;
extern NSString *const DeregistrationStateDidChangeNotification;
extern NSString *const kNSNotificationName_LocalNumberDidChange;

@class AnyPromise;
@class OWSPrimaryStorage;
@class TSNetworkManager;
@class YapDatabaseReadWriteTransaction;

@interface TSAccountManager : NSObject

// This property is exposed for testing purposes only.
#ifdef DEBUG
@property (nonatomic, nullable) NSString *phoneNumberAwaitingVerification;
#endif

#pragma mark - Initializers

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithPrimaryStorage:(OWSPrimaryStorage *)primaryStorage NS_DESIGNATED_INITIALIZER;

+ (instancetype)sharedInstance;

/**
 *  Returns if a user is registered or not
 *
 *  @return registered or not
 */
+ (BOOL)isRegistered;
- (BOOL)isRegistered;

/**
 *  Returns current phone number for this device, which may not yet have been registered.
 *
 *  @return E164 formatted phone number
 */
+ (nullable NSString *)localNumber;
- (nullable NSString *)localNumber;

/**
 *  Symmetric key that's used to encrypt message payloads from the server,
 *
 *  @return signaling key
 */
+ (nullable NSString *)signalingKey;
- (nullable NSString *)signalingKey;

/**
 *  The server auth token allows the Signal client to connect to the Signal server
 *
 *  @return server authentication token
 */
+ (nullable NSString *)serverAuthToken;
- (nullable NSString *)serverAuthToken;

/**
 *  The registration ID is unique to an installation of TextSecure, it allows to know if the app was reinstalled
 *
 *  @return registrationID;
 */

+ (uint32_t)getOrGenerateRegistrationId:(YapDatabaseReadWriteTransaction *)transaction;
- (uint32_t)getOrGenerateRegistrationId;
- (uint32_t)getOrGenerateRegistrationId:(YapDatabaseReadWriteTransaction *)transaction;

#pragma mark - Register with phone number

+ (void)registerWithPhoneNumber:(NSString *)phoneNumber
                        success:(void (^)(void))successBlock
                        failure:(void (^)(NSError *error))failureBlock
                smsVerification:(BOOL)isSMS;

+ (void)rerequestSMSWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock;

+ (void)rerequestVoiceWithSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)verifyAccountWithCode:(NSString *)verificationCode
                          pin:(nullable NSString *)pin
                      success:(void (^)(void))successBlock
                      failure:(void (^)(NSError *error))failureBlock;

// Called once registration is complete - meaning the following have succeeded:
// - obtained signal server credentials
// - uploaded pre-keys
// - uploaded push tokens
- (void)didRegister;

#if TARGET_OS_IPHONE

/**
 *  Register's the device's push notification token with the server
 *
 *  @param pushToken Apple's Push Token
 */
- (void)registerForPushNotificationsWithPushToken:(NSString *)pushToken
                                        voipToken:(NSString *)voipToken
                                          success:(void (^)(void))successHandler
                                          failure:(void (^)(NSError *error))failureHandler
    NS_SWIFT_NAME(registerForPushNotifications(pushToken:voipToken:success:failure:));

#endif

+ (void)unregisterTextSecureWithSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failureBlock;

#pragma mark - De-Registration

// De-registration reflects whether or not the "last known contact"
// with the service was:
//
// * A 403 from the service, indicating de-registration.
// * A successful auth'd request _or_ websocket connection indicating
//   valid registration.
- (BOOL)isDeregistered;
- (void)setIsDeregistered:(BOOL)isDeregistered;

#pragma mark - Re-registration

// Re-registration is the process of re-registering _with the same phone number_.

// Returns YES on success.
- (BOOL)resetForReregistration;
- (NSString *)reregisterationPhoneNumber;
- (BOOL)isReregistering;

#pragma mark - Manual Message Fetch

- (BOOL)isManualMessageFetchEnabled;
- (AnyPromise *)setIsManualMessageFetchEnabled:(BOOL)value;

#ifdef DEBUG
- (void)registerForTestsWithLocalNumber:(NSString *)localNumber;
#endif

- (AnyPromise *)updateAccountAttributes;

@end

NS_ASSUME_NONNULL_END
