//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#ifndef TextSecureKit_Constants_h
#define TextSecureKit_Constants_h

typedef NS_ENUM(NSInteger, TSWhisperMessageType) {
    TSUnknownMessageType = 0,
    TSEncryptedWhisperMessageType = 1,
    TSIgnoreOnIOSWhisperMessageType = 2, // on droid this is the prekey bundle message irrelevant for us
    TSPreKeyWhisperMessageType = 3,
    TSUnencryptedWhisperMessageType = 4,
    TSUnidentifiedSenderMessageType = 6,
};

#pragma mark Server Address

#define textSecureHTTPTimeOut 10

#define kLegalTermsUrlString @"https://signal.org/legal/"
#define SHOW_LEGAL_TERMS_LINK

// VINCI CONSTANTS
#define USING_VINCI_INTERFACE

// 0 - Calls page, 1 - Chats page, 2 - Contacts page, 3 - Wallet page
#define VINCI_START_PAGE_NUMBER 1

//#ifndef DEBUG

// Production
#define textSecureWebSocketAPI @"wss://18.185.134.209:8080/dev/v1/websocket/"
#define textSecureServerURL @"https://18.185.134.209:8080/dev/"
#define textSecureCDNServerURL @"https://18.185.134.209:8080/cdn"

//#define textSecureWebSocketAPI @"wss://35.181.159.25:8080/v1/websocket/"
//#define textSecureServerURL @"https://35.181.159.25:8080/"
//#define textSecureCDNServerURL @"https://35.181.159.25:8080/cdn"

// Production
//#define textSecureWebSocketAPI @"wss://textsecure-service.whispersystems.org/v1/websocket/"
//#define textSecureServerURL @"https://textsecure-service.whispersystems.org/"
//#define textSecureCDNServerURL @"https://cdn.signal.org"
// Use same reflector for service and CDN
#define textSecureServiceReflectorHost @"textsecure-service-reflected.whispersystems.org"
#define textSecureCDNReflectorHost @"textsecure-service-reflected.whispersystems.org"
#define contactDiscoveryURL @"https://api.directory.signal.org"
#define kUDTrustRoot @"BXu6QIKVz5MA8gstzfOgRQGqyLqOwNKHL6INkv3IHWMF"
#define USING_PRODUCTION_SERVICE

//#else

// Staging
//#define textSecureWebSocketAPI @"wss://textsecure-service-staging.whispersystems.org/v1/websocket/"
//#define textSecureServerURL @"https://textsecure-service-staging.whispersystems.org/"
//#define textSecureCDNServerURL @"https://cdn-staging.signal.org"
//#define textSecureServiceReflectorHost @"meek-signal-service-staging.appspot.com";
//#define textSecureCDNReflectorHost @"meek-signal-cdn-staging.appspot.com";
//#define contactDiscoveryURL @"https://api-staging.directory.signal.org"
//#define kUDTrustRoot @"BbqY1DzohE4NUZoVF+L18oUPrK3kILllLEJh2UnPSsEx"

//#endif

BOOL IsUsingProductionService(void);

#define textSecureAccountsAPI @"v1/accounts"
#define textSecureAttributesAPI @"/attributes/"

#define textSecureMessagesAPI @"v1/messages/"
#define textSecureKeysAPI @"v2/keys"
#define textSecureSignedKeysAPI @"v2/keys/signed"
#define textSecureDirectoryAPI @"v1/directory"
#define textSecureAttachmentsAPI @"v1/attachments"
#define textSecureDeviceProvisioningCodeAPI @"v1/devices/provisioning/code"
#define textSecureDeviceProvisioningAPIFormat @"v1/provisioning/%@"
#define textSecureDevicesAPIFormat @"v1/devices/%@"
#define textSecureProfileAPIFormat @"v1/profile/%@"
#define textSecureSetProfileNameAPIFormat @"v1/profile/name/%@"
#define textSecureProfileAvatarFormAPI @"v1/profile/form/avatar"
#define textSecure2FAAPI @"/v1/accounts/pin"

#define SignalApplicationGroup @"group.id.vinci.messenger"

#endif
