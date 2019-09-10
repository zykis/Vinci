//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSErrorMessage.h"

NS_ASSUME_NONNULL_BEGIN

@class OWSFingerprint;

@interface TSInvalidIdentityKeyErrorMessage : TSErrorMessage

- (void)throws_acceptNewIdentityKey NS_SWIFT_UNAVAILABLE("throws objc exceptions");
- (nullable NSData *)throws_newIdentityKey NS_SWIFT_UNAVAILABLE("throws objc exceptions");
- (NSString *)theirSignalId;

@end

NS_ASSUME_NONNULL_END
