//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "PrivacySettingsTableViewController.h"
#import "BlockListViewController.h"
#import "OWS2FASettingsViewController.h"
#import "Vinci-Swift.h"
#import <SignalCoreKit/NSString+SSK.h>
#import <SignalMessaging/Environment.h>
#import <SignalMessaging/OWSPreferences.h>
#import <SignalMessaging/ThreadUtil.h>
#import <SignalMessaging/UIColor+OWS.h>
#import <SignalServiceKit/OWS2FAManager.h>
#import <SignalServiceKit/OWSReadReceiptManager.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const kSealedSenderInfoURL = @"https://signal.org/blog/sealed-sender/";

@implementation PrivacySettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"SETTINGS_PRIVACY_TITLE", @"");

    [self observeNotifications];

    [self updateTableContents];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateTableContents];
}

- (void)observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenLockDidChange:)
                                                 name:OWSScreenLock.ScreenLockDidChange
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Dependencies

- (id<OWSUDManager>)udManager
{
    return SSKEnvironment.shared.udManager;
}

- (OWSPreferences *)preferences
{
    return Environment.shared.preferences;
}

- (OWSReadReceiptManager *)readReceiptManager
{
    return OWSReadReceiptManager.sharedManager;
}

- (id<OWSTypingIndicators>)typingIndicators
{
    return SSKEnvironment.shared.typingIndicators;
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak PrivacySettingsTableViewController *weakSelf = self;

    OWSTableSection *blocklistSection = [OWSTableSection new];
    blocklistSection.headerTitle
        = NSLocalizedString(@"SETTINGS_BLOCK_LIST_TITLE", @"Label for the block list section of the settings view");
    [blocklistSection
        addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_BLOCK_LIST_TITLE",
                                                         @"Label for the block list section of the settings view")
                                         actionBlock:^{
                                             [weakSelf showBlocklist];
                                         }]];
    [contents addSection:blocklistSection];

    OWSTableSection *readReceiptsSection = [OWSTableSection new];
    readReceiptsSection.headerTitle
        = NSLocalizedString(@"SETTINGS_READ_RECEIPT", @"Label for the 'read receipts' setting.");
    readReceiptsSection.footerTitle = NSLocalizedString(
        @"SETTINGS_READ_RECEIPTS_SECTION_FOOTER", @"An explanation of the 'read receipts' setting.");
    [readReceiptsSection addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"SETTINGS_READ_RECEIPT",
                                                                      @"Label for the 'read receipts' setting.")
                                                             isOn:[self.readReceiptManager areReadReceiptsEnabled]
                                                           target:weakSelf
                                                         selector:@selector(didToggleReadReceiptsSwitch:)]];
    [contents addSection:readReceiptsSection];

    OWSTableSection *typingIndicatorsSection = [OWSTableSection new];
    typingIndicatorsSection.headerTitle
        = NSLocalizedString(@"SETTINGS_TYPING_INDICATORS", @"Label for the 'typing indicators' setting.");
    typingIndicatorsSection.footerTitle = NSLocalizedString(
        @"SETTINGS_TYPING_INDICATORS_FOOTER", @"An explanation of the 'typing indicators' setting.");
    [typingIndicatorsSection addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"SETTINGS_TYPING_INDICATORS",
                                                                          @"Label for the 'typing indicators' setting.")
                                                                 isOn:[self.typingIndicators areTypingIndicatorsEnabled]
                                                               target:weakSelf
                                                             selector:@selector(didToggleTypingIndicatorsSwitch:)]];
    [contents addSection:typingIndicatorsSection];

    OWSTableSection *screenLockSection = [OWSTableSection new];
    screenLockSection.headerTitle = NSLocalizedString(
        @"SETTINGS_SCREEN_LOCK_SECTION_TITLE", @"Title for the 'screen lock' section of the privacy settings.");
    screenLockSection.footerTitle = NSLocalizedString(
        @"SETTINGS_SCREEN_LOCK_SECTION_FOOTER", @"Footer for the 'screen lock' section of the privacy settings.");
    [screenLockSection
        addItem:[OWSTableItem
                    switchItemWithText:NSLocalizedString(@"SETTINGS_SCREEN_LOCK_SWITCH_LABEL",
                                           @"Label for the 'enable screen lock' switch of the privacy settings.")
                                  isOn:OWSScreenLock.sharedManager.isScreenLockEnabled
                                target:self
                              selector:@selector(isScreenLockEnabledDidChange:)]];
    [contents addSection:screenLockSection];

    if (OWSScreenLock.sharedManager.isScreenLockEnabled) {
        OWSTableSection *screenLockTimeoutSection = [OWSTableSection new];
        uint32_t screenLockTimeout = (uint32_t)round(OWSScreenLock.sharedManager.screenLockTimeout);
        NSString *screenLockTimeoutString = [self formatScreenLockTimeout:screenLockTimeout useShortFormat:YES];
        [screenLockTimeoutSection
            addItem:[OWSTableItem
                        disclosureItemWithText:
                            NSLocalizedString(@"SETTINGS_SCREEN_LOCK_ACTIVITY_TIMEOUT",
                                @"Label for the 'screen lock activity timeout' setting of the privacy settings.")
                                    detailText:screenLockTimeoutString
                                   actionBlock:^{
                                       [weakSelf showScreenLockTimeoutUI];
                                   }]];
        [contents addSection:screenLockTimeoutSection];
    }

    OWSTableSection *screenSecuritySection = [OWSTableSection new];
    screenSecuritySection.headerTitle = NSLocalizedString(@"SETTINGS_SECURITY_TITLE", @"Section header");
    screenSecuritySection.footerTitle = NSLocalizedString(@"SETTINGS_SCREEN_SECURITY_DETAIL", nil);
    [screenSecuritySection addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"SETTINGS_SCREEN_SECURITY", @"")
                                                               isOn:[self.preferences screenSecurityIsEnabled]
                                                             target:weakSelf
                                                           selector:@selector(didToggleScreenSecuritySwitch:)]];
    [contents addSection:screenSecuritySection];
    
    // Allow calls to connect directly vs. using TURN exclusively
    OWSTableSection *callingSection = [OWSTableSection new];
    callingSection.headerTitle
        = NSLocalizedString(@"SETTINGS_SECTION_TITLE_CALLING", @"settings topic header for table section");
    callingSection.footerTitle = NSLocalizedString(@"SETTINGS_CALLING_HIDES_IP_ADDRESS_PREFERENCE_TITLE_DETAIL",
        @"User settings section footer, a detailed explanation");
    [callingSection addItem:[OWSTableItem switchItemWithText:NSLocalizedString(
                                                                 @"SETTINGS_CALLING_HIDES_IP_ADDRESS_PREFERENCE_TITLE",
                                                                 @"Table cell label")
                                                        isOn:[self.preferences doCallsHideIPAddress]
                                                      target:weakSelf
                                                    selector:@selector(didToggleCallsHideIPAddressSwitch:)]];
    [contents addSection:callingSection];

    if (@available(iOS 11, *)) {
        OWSTableSection *callKitSection = [OWSTableSection new];
        [callKitSection
            addItem:[OWSTableItem switchItemWithText:NSLocalizedString(
                                                         @"SETTINGS_PRIVACY_CALLKIT_SYSTEM_CALL_LOG_PREFERENCE_TITLE",
                                                         @"Short table cell label")
                                                isOn:[self.preferences isSystemCallLogEnabled]
                                              target:weakSelf
                                            selector:@selector(didToggleEnableSystemCallLogSwitch:)]];
        callKitSection.footerTitle = NSLocalizedString(
            @"SETTINGS_PRIVACY_CALLKIT_SYSTEM_CALL_LOG_PREFERENCE_DESCRIPTION", @"Settings table section footer.");
        [contents addSection:callKitSection];
    } else if (@available(iOS 10, *)) {
        OWSTableSection *callKitSection = [OWSTableSection new];
        callKitSection.footerTitle
            = NSLocalizedString(@"SETTINGS_SECTION_CALL_KIT_DESCRIPTION", @"Settings table section footer.");
        [callKitSection addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"SETTINGS_PRIVACY_CALLKIT_TITLE",
                                                                     @"Short table cell label")
                                                            isOn:[self.preferences isCallKitEnabled]
                                                          target:weakSelf
                                                        selector:@selector(didToggleEnableCallKitSwitch:)]];
        if (self.preferences.isCallKitEnabled) {
            [callKitSection
                addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"SETTINGS_PRIVACY_CALLKIT_PRIVACY_TITLE",
                                                             @"Label for 'CallKit privacy' preference")
                                                    isOn:![self.preferences isCallKitPrivacyEnabled]
                                                  target:weakSelf
                                                selector:@selector(didToggleEnableCallKitPrivacySwitch:)]];
        }
        [contents addSection:callKitSection];
    }

    OWSTableSection *twoFactorAuthSection = [OWSTableSection new];
    twoFactorAuthSection.headerTitle = NSLocalizedString(
        @"SETTINGS_TWO_FACTOR_AUTH_TITLE", @"Title for the 'two factor auth' section of the privacy settings.");
    [twoFactorAuthSection
        addItem:
            [OWSTableItem
                disclosureItemWithText:NSLocalizedString(@"SETTINGS_TWO_FACTOR_AUTH_ITEM",
                                           @"Label for the 'two factor auth' item of the privacy settings.")
                            detailText:
                                ([OWS2FAManager.sharedManager is2FAEnabled]
                                        ? NSLocalizedString(@"SETTINGS_TWO_FACTOR_AUTH_ENABLED",
                                              @"Indicates that 'two factor auth' is enabled in the privacy settings.")
                                        : NSLocalizedString(@"SETTINGS_TWO_FACTOR_AUTH_DISABLED",
                                              @"Indicates that 'two factor auth' is disabled in the privacy settings."))
                            actionBlock:^{
                                [weakSelf show2FASettings];
                            }]];
    [contents addSection:twoFactorAuthSection];

    OWSTableSection *historyLogsSection = [OWSTableSection new];
    historyLogsSection.headerTitle = NSLocalizedString(@"SETTINGS_HISTORYLOG_TITLE", @"Section header");
    [historyLogsSection addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_CLEAR_HISTORY", @"")
                                                         actionBlock:^{
                                                             [weakSelf clearHistoryLogs];
                                                         }]];
    [contents addSection:historyLogsSection];

    OWSTableSection *unidentifiedDeliveryIndicatorsSection = [OWSTableSection new];
    unidentifiedDeliveryIndicatorsSection.headerTitle
        = NSLocalizedString(@"SETTINGS_UNIDENTIFIED_DELIVERY_SECTION_TITLE", @"table section label");
    [unidentifiedDeliveryIndicatorsSection
        addItem:[OWSTableItem
                    itemWithCustomCellBlock:^UITableViewCell * {
                        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                                       reuseIdentifier:@"UITableViewCellStyleValue1"];
                        [OWSTableItem configureCell:cell];
                        cell.preservesSuperviewLayoutMargins = YES;
                        cell.contentView.preservesSuperviewLayoutMargins = YES;
                        cell.selectionStyle = UITableViewCellSelectionStyleNone;

                        UILabel *label = [UILabel new];
                        label.text
                            = NSLocalizedString(@"SETTINGS_UNIDENTIFIED_DELIVERY_SHOW_INDICATORS", @"switch label");
                        label.font = [UIFont ows_regularFontWithSize:18.f];
                        label.textColor = [Theme primaryColor];
                        [label setContentHuggingHorizontalHigh];

                        UIImage *icon = [UIImage imageNamed:@"ic_secret_sender_indicator"];
                        UIImageView *iconView = [[UIImageView alloc]
                            initWithImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                        iconView.tintColor = Theme.secondaryColor;
                        [iconView setContentHuggingHorizontalHigh];

                        UIView *spacer = [UIView new];
                        [spacer setContentHuggingHorizontalLow];

                        UISwitch *cellSwitch = [UISwitch new];
                        cell.accessoryView = cellSwitch;
                        [cellSwitch setOn:weakSelf.preferences.shouldShowUnidentifiedDeliveryIndicators];
                        [cellSwitch addTarget:weakSelf
                                       action:@selector(didToggleUDShowIndicatorsSwitch:)
                             forControlEvents:UIControlEventValueChanged];
                        [cellSwitch setContentHuggingHorizontalHigh];

                        UIStackView *stackView =
                            [[UIStackView alloc] initWithArrangedSubviews:@[ label, iconView, spacer, cellSwitch ]];
                        stackView.axis = UILayoutConstraintAxisHorizontal;
                        stackView.spacing = 10;
                        stackView.alignment = UIStackViewAlignmentCenter;

                        [cell.contentView addSubview:stackView];
                        [stackView ows_autoPinToSuperviewMargins];
                        return cell;
                    }
                    customRowHeight:UITableViewAutomaticDimension
                    actionBlock:^{
                        NSURL *url = [NSURL URLWithString:kSealedSenderInfoURL];
                        OWSAssertDebug(url);
                        [UIApplication.sharedApplication openURL:url];
                    }]];

    unidentifiedDeliveryIndicatorsSection.footerTitle
        = NSLocalizedString(@"SETTINGS_UNIDENTIFIED_DELIVERY_SHOW_INDICATORS_FOOTER", @"table section footer");
    [contents addSection:unidentifiedDeliveryIndicatorsSection];

    OWSTableSection *unidentifiedDeliveryUnrestrictedSection = [OWSTableSection new];
    OWSTableItem *unrestrictedAccessItem = [OWSTableItem
        switchItemWithText:NSLocalizedString(@"SETTINGS_UNIDENTIFIED_DELIVERY_UNRESTRICTED_ACCESS", @"switch label")
                      isOn:weakSelf.udManager.shouldAllowUnrestrictedAccessLocal
                    target:weakSelf
                  selector:@selector(didToggleUDUnrestrictedAccessSwitch:)];
    [unidentifiedDeliveryUnrestrictedSection addItem:unrestrictedAccessItem];
    unidentifiedDeliveryUnrestrictedSection.footerTitle
        = NSLocalizedString(@"SETTINGS_UNIDENTIFIED_DELIVERY_UNRESTRICTED_ACCESS_FOOTER", @"table section footer");
    [contents addSection:unidentifiedDeliveryUnrestrictedSection];

    OWSTableSection *unidentifiedDeliveryLearnMoreSection = [OWSTableSection new];
    [unidentifiedDeliveryLearnMoreSection
        addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"SETTINGS_UNIDENTIFIED_DELIVERY_LEARN_MORE",
                                                         @"Label for a link to more info about unidentified delivery.")
                                         actionBlock:^{
                                             NSURL *url = [NSURL URLWithString:kSealedSenderInfoURL];
                                             OWSAssertDebug(url);
                                             [UIApplication.sharedApplication openURL:url];
                                         }]];
    [contents addSection:unidentifiedDeliveryLearnMoreSection];

    self.contents = contents;
}

#pragma mark - Events

- (void)showBlocklist
{
    BlockListViewController *vc = [BlockListViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)clearHistoryLogs
{
    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:nil
                                            message:NSLocalizedString(@"SETTINGS_DELETE_HISTORYLOG_CONFIRMATION",
                                                        @"Alert message before user confirms clearing history")
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[OWSAlerts cancelAction]];

    UIAlertAction *deleteAction = [UIAlertAction
        actionWithTitle:NSLocalizedString(@"SETTINGS_DELETE_HISTORYLOG_CONFIRMATION_BUTTON",
                            @"Confirmation text for button which deletes all message, calling, attachments, etc.")
                  style:UIAlertActionStyleDestructive
                handler:^(UIAlertAction *_Nonnull action) {
                    [self deleteThreadsAndMessages];
                }];
    [alertController addAction:deleteAction];

    [self presentViewController:alertController animated:true completion:nil];
}

- (void)deleteThreadsAndMessages
{
    [ThreadUtil deleteAllContent];
}

- (void)didToggleScreenSecuritySwitch:(UISwitch *)sender
{
    BOOL enabled = sender.isOn;
    OWSLogInfo(@"toggled screen security: %@", enabled ? @"ON" : @"OFF");
    [self.preferences setScreenSecurity:enabled];
}

- (void)didToggleReadReceiptsSwitch:(UISwitch *)sender
{
    BOOL enabled = sender.isOn;
    OWSLogInfo(@"toggled areReadReceiptsEnabled: %@", enabled ? @"ON" : @"OFF");
    [self.readReceiptManager setAreReadReceiptsEnabled:enabled];
}

- (void)didToggleTypingIndicatorsSwitch:(UISwitch *)sender
{
    BOOL enabled = sender.isOn;
    OWSLogInfo(@"toggled areTypingIndicatorsEnabled: %@", enabled ? @"ON" : @"OFF");
    [self.typingIndicators setTypingIndicatorsEnabledWithValue:enabled];
}

- (void)didToggleCallsHideIPAddressSwitch:(UISwitch *)sender
{
    BOOL enabled = sender.isOn;
    OWSLogInfo(@"toggled callsHideIPAddress: %@", enabled ? @"ON" : @"OFF");
    [self.preferences setDoCallsHideIPAddress:enabled];
}

- (void)didToggleEnableSystemCallLogSwitch:(UISwitch *)sender
{
    OWSLogInfo(@"user toggled call kit preference: %@", (sender.isOn ? @"ON" : @"OFF"));
    [self.preferences setIsSystemCallLogEnabled:sender.isOn];

    // rebuild callUIAdapter since CallKit configuration changed.
    [AppEnvironment.shared.callService createCallUIAdapter];
}

- (void)didToggleEnableCallKitSwitch:(UISwitch *)sender
{
    OWSLogInfo(@"user toggled call kit preference: %@", (sender.isOn ? @"ON" : @"OFF"));
    [self.preferences setIsCallKitEnabled:sender.isOn];

    // rebuild callUIAdapter since CallKit vs not changed.
    [AppEnvironment.shared.callService createCallUIAdapter];

    // Show/Hide dependent switch: CallKit privacy
    [self updateTableContents];
}

- (void)didToggleEnableCallKitPrivacySwitch:(UISwitch *)sender
{
    OWSLogInfo(@"user toggled call kit privacy preference: %@", (sender.isOn ? @"ON" : @"OFF"));
    [self.preferences setIsCallKitPrivacyEnabled:!sender.isOn];

    // rebuild callUIAdapter since CallKit configuration changed.
    [AppEnvironment.shared.callService createCallUIAdapter];
}

- (void)didToggleUDUnrestrictedAccessSwitch:(UISwitch *)sender
{
    OWSLogInfo(@"toggled to: %@", (sender.isOn ? @"ON" : @"OFF"));
    [self.udManager setShouldAllowUnrestrictedAccessLocal:sender.isOn];
}

- (void)didToggleUDShowIndicatorsSwitch:(UISwitch *)sender
{
    OWSLogInfo(@"toggled to: %@", (sender.isOn ? @"ON" : @"OFF"));
    [self.preferences setShouldShowUnidentifiedDeliveryIndicators:sender.isOn];
}

- (void)show2FASettings
{
    OWSLogInfo(@"");

    OWS2FASettingsViewController *vc = [OWS2FASettingsViewController new];
    vc.mode = OWS2FASettingsMode_Status;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)isScreenLockEnabledDidChange:(UISwitch *)sender
{
    BOOL shouldBeEnabled = sender.isOn;

    if (shouldBeEnabled == OWSScreenLock.sharedManager.isScreenLockEnabled) {
        OWSLogError(@"ignoring redundant screen lock.");
        return;
    }

    OWSLogInfo(@"trying to set is screen lock enabled: %@", @(shouldBeEnabled));

    [OWSScreenLock.sharedManager setIsScreenLockEnabled:shouldBeEnabled];
}

- (void)screenLockDidChange:(NSNotification *)notification
{
    OWSLogInfo(@"");

    [self updateTableContents];
}

- (void)showScreenLockTimeoutUI
{
    OWSLogInfo(@"");

    UIAlertController *controller = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"SETTINGS_SCREEN_LOCK_ACTIVITY_TIMEOUT",
                                     @"Label for the 'screen lock activity timeout' setting of the privacy settings.")
                         message:nil
                  preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSNumber *timeoutValue in OWSScreenLock.sharedManager.screenLockTimeouts) {
        uint32_t screenLockTimeout = (uint32_t)round(timeoutValue.doubleValue);
        NSString *screenLockTimeoutString = [self formatScreenLockTimeout:screenLockTimeout useShortFormat:NO];

        [controller addAction:[UIAlertAction actionWithTitle:screenLockTimeoutString
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                         [OWSScreenLock.sharedManager
                                                             setScreenLockTimeout:screenLockTimeout];
                                                     }]];
    }
    [controller addAction:[OWSAlerts cancelAction]];
    UIViewController *fromViewController = [[UIApplication sharedApplication] frontmostViewController];
    [fromViewController presentViewController:controller animated:YES completion:nil];
}

- (NSString *)formatScreenLockTimeout:(NSInteger)value useShortFormat:(BOOL)useShortFormat
{
    if (value <= 1) {
        return NSLocalizedString(@"SCREEN_LOCK_ACTIVITY_TIMEOUT_NONE",
            @"Indicates a delay of zero seconds, and that 'screen lock activity' will timeout immediately.");
    }
    return [NSString formatDurationSeconds:(uint32_t)value useShortFormat:useShortFormat];
}

@end

NS_ASSUME_NONNULL_END
