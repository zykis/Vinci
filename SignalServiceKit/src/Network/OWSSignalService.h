//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kNSNotificationName_IsCensorshipCircumventionActiveDidChange;

@class AFHTTPSessionManager;
@class OWSPrimaryStorage;
@class TSAccountManager;

@interface OWSSignalService : NSObject

/// For interacting with the Signal Service
@property (nonatomic, readonly) AFHTTPSessionManager *signalServiceSessionManager;

/// For uploading avatar assets.
@property (nonatomic, readonly) AFHTTPSessionManager *CDNSessionManager;

+ (instancetype)sharedInstance;

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Censorship Circumvention

@property (atomic, readonly) BOOL isCensorshipCircumventionActive;
@property (atomic, readonly) BOOL hasCensoredPhoneNumber;
@property (atomic) BOOL isCensorshipCircumventionManuallyActivated;
@property (atomic, nullable) NSString *manualCensorshipCircumventionCountryCode;

@end

NS_ASSUME_NONNULL_END
