//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSSoundSettingsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <SignalMessaging/OWSAudioPlayer.h>
#import <SignalMessaging/OWSSounds.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSSoundSettingsViewController ()

@property (nonatomic) BOOL isDirty;

@property (nonatomic) OWSSound currentSound;

@property (nonatomic, nullable) OWSAudioPlayer *audioPlayer;

@end

#pragma mark -

@implementation OWSSoundSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setTitle:NSLocalizedString(@"SETTINGS_ITEM_NOTIFICATION_SOUND",
                       @"Label for settings view that allows user to change the notification sound.")];
    self.currentSound
        = (self.thread ? [OWSSounds notificationSoundForThread:self.thread] : [OWSSounds globalNotificationSound]);

    [self updateTableContents];
    [self updateNavigationItems];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateTableContents];
}

- (void)updateNavigationItems
{
    self.navigationItem.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                      target:self
                                                      action:@selector(cancelWasPressed:)];

    if (self.isDirty) {
        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                          target:self
                                                          action:@selector(saveWasPressed:)];
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];

    __weak OWSSoundSettingsViewController *weakSelf = self;

    OWSTableSection *soundsSection = [OWSTableSection new];
    soundsSection.headerTitle = NSLocalizedString(
        @"NOTIFICATIONS_SECTION_SOUNDS", @"Label for settings UI that allows user to change the notification sound.");

    NSArray<NSNumber *> *allSounds = [OWSSounds allNotificationSounds];
    for (NSNumber *nsValue in allSounds) {
        OWSSound sound = (OWSSound)nsValue.intValue;
        OWSTableItem *item;

        NSString *soundLabelText = ^{
            NSString *baseName = [OWSSounds displayNameForSound:sound];
            if (sound == OWSSound_Note) {
                NSString *noteStringFormat = NSLocalizedString(@"SETTINGS_AUDIO_DEFAULT_TONE_LABEL_FORMAT",
                    @"Format string for the default 'Note' sound. Embeds the system {{sound name}}.");
                return [NSString stringWithFormat:noteStringFormat, baseName];
            } else {
                return [OWSSounds displayNameForSound:sound];
            }
        }();

        if (sound == self.currentSound) {
            item = [OWSTableItem checkmarkItemWithText:soundLabelText
                                           actionBlock:^{
                                               [weakSelf soundWasSelected:sound];
                                           }];
        } else {
            item = [OWSTableItem actionItemWithText:soundLabelText
                                        actionBlock:^{
                                            [weakSelf soundWasSelected:sound];
                                        }];
        }
        [soundsSection addItem:item];
    }

    [contents addSection:soundsSection];

    self.contents = contents;
}

#pragma mark - Events

- (void)soundWasSelected:(OWSSound)sound
{
    [self.audioPlayer stop];
    self.audioPlayer = [OWSSounds audioPlayerForSound:sound audioBehavior:OWSAudioBehavior_Playback];
    // Suppress looping in this view.
    self.audioPlayer.isLooping = NO;
    [self.audioPlayer play];

    if (self.currentSound == sound) {
        return;
    }

    self.currentSound = sound;
    self.isDirty = YES;
    [self updateTableContents];
    [self updateNavigationItems];
}

- (void)cancelWasPressed:(id)sender
{
    // TODO: Add "discard changes?" alert.
    [self.audioPlayer stop];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveWasPressed:(id)sender
{
    if (self.thread) {
        [OWSSounds setNotificationSound:self.currentSound forThread:self.thread];
    } else {
        [OWSSounds setGlobalNotificationSound:self.currentSound];
    }

    [self.audioPlayer stop];
    [self.navigationController popViewControllerAnimated:YES];
}

@end

NS_ASSUME_NONNULL_END
