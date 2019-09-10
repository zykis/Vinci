//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "HomeViewController.h"
#import "AppDelegate.h"
#import "AppSettingsViewController.h"
#import "HomeViewCell.h"
#import "NewContactThreadViewController.h"
#import "OWSNavigationController.h"
#import "OWSPrimaryStorage.h"
#import "ProfileViewController.h"
#import "PushManager.h"
#import "RegistrationUtils.h"
#import "Vinci-Swift.h"
#import "SignalApp.h"
#import "TSAccountManager.h"
#import "TSDatabaseView.h"
#import "TSGroupThread.h"
#import "ViewControllerUtils.h"
#import <PromiseKit/AnyPromise.h>
#import <SignalCoreKit/NSDate+OWS.h>
#import <SignalCoreKit/Threading.h>
#import <SignalCoreKit/iOSVersions.h>
#import <SignalMessaging/OWSContactsManager.h>
#import <SignalMessaging/OWSFormat.h>
#import <SignalMessaging/SignalMessaging-Swift.h>
#import <SignalMessaging/UIUtil.h>
#import <SignalServiceKit/OWSMessageSender.h>
#import <SignalServiceKit/OWSMessageUtils.h>
#import <SignalServiceKit/TSAccountManager.h>
#import <SignalServiceKit/TSOutgoingMessage.h>
#import <StoreKit/StoreKit.h>
#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseViewChange.h>
#import <YapDatabase/YapDatabaseViewConnection.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HomeViewMode) {
    HomeViewMode_Archive,
    HomeViewMode_Inbox,
};

// The bulk of the content in this view is driven by a YapDB view/mapping.
// However, we also want to optionally include ReminderView's at the top
// and an "Archived Conversations" button at the bottom. Rather than introduce
// index-offsets into the Mapping calculation, we introduce two pseudo groups
// to add a top and bottom section to the content, and create cells for those
// sections without consulting the YapMapping.
// This is a bit of a hack, but it consolidates the hacks into the Reminder/Archive section
// and allows us to leaves the bulk of the content logic on the happy path.
NSString *const kReminderViewPseudoGroup = @"kReminderViewPseudoGroup";
NSString *const kArchiveButtonPseudoGroup = @"kArchiveButtonPseudoGroup";

typedef NS_ENUM(NSInteger, HomeViewControllerSection) {
    HomeViewControllerSectionReminders,
    HomeViewControllerSectionConversations,
    HomeViewControllerSectionArchiveButton,
};

NSString *const kArchivedConversationsReuseIdentifier = @"kArchivedConversationsReuseIdentifier";

@interface HomeViewController () <UITableViewDelegate,
    UITableViewDataSource,
    UIViewControllerPreviewingDelegate,
    UISearchBarDelegate,
    ConversationSearchViewDelegate,
    OWSBlockListCacheDelegate>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UILabel *emptyBoxLabel;

@property (nonatomic) YapDatabaseConnection *editingDbConnection;
@property (nonatomic) YapDatabaseConnection *uiDatabaseConnection;
@property (nonatomic) YapDatabaseViewMappings *threadMappings;
@property (nonatomic) HomeViewMode homeViewMode;
@property (nonatomic) id previewingContext;
@property (nonatomic, readonly) NSCache<NSString *, ThreadViewModel *> *threadViewModelCache;
@property (nonatomic) BOOL isViewVisible;
@property (nonatomic) BOOL shouldObserveDBModifications;
@property (nonatomic) BOOL hasEverAppeared;

// Mark: Search

@property (nonatomic, readonly) UISearchBar *searchBar;
@property (nonatomic) ConversationSearchViewController *searchResultsController;

// Dependencies

@property (nonatomic, readonly) AccountManager *accountManager;
@property (nonatomic, readonly) OWSContactsManager *contactsManager;
@property (nonatomic, readonly) OWSMessageSender *messageSender;
@property (nonatomic, readonly) OWSBlockListCache *blocklistCache;

// Views

@property (nonatomic, readonly) UIStackView *reminderStackView;
@property (nonatomic, readonly) UITableViewCell *reminderViewCell;
@property (nonatomic, readonly) UIView *deregisteredView;
@property (nonatomic, readonly) UIView *outageView;
@property (nonatomic, readonly) UIView *archiveReminderView;
@property (nonatomic, readonly) UIView *missingContactsPermissionView;

@property (nonatomic) TSThread *lastThread;

@property (nonatomic) BOOL hasArchivedThreadsRow;
@property (nonatomic) BOOL hasThemeChanged;
@property (nonatomic) BOOL hasVisibleReminders;

@end

#pragma mark -

@implementation HomeViewController

#pragma mark - Init

- (instancetype)init
{
    self = [super init];
    if (!self) {
        return self;
    }

    _homeViewMode = HomeViewMode_Inbox;

    [self commonInit];

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    OWSFailDebug(@"Do not load this from the storyboard.");

    self = [super initWithCoder:aDecoder];
    if (!self) {
        return self;
    }

    [self commonInit];

    return self;
}

- (void)commonInit
{
    _accountManager = AppEnvironment.shared.accountManager;
    _contactsManager = Environment.shared.contactsManager;
    _messageSender = SSKEnvironment.shared.messageSender;
    _blocklistCache = [OWSBlockListCache new];
    [_blocklistCache startObservingAndSyncStateWithDelegate:self];
    _threadViewModelCache = [NSCache new];

    // Ensure ExperienceUpgradeFinder has been initialized.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-result"
    [ExperienceUpgradeFinder sharedManager];
#pragma GCC diagnostic pop
}

- (void)observeNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(signalAccountsDidChange:)
                                                 name:OWSContactsManagerSignalAccountsDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:OWSApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:OWSApplicationDidBecomeActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:OWSApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:OWSPrimaryStorage.sharedManager.dbNotificationObject];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModifiedExternally:)
                                                 name:YapDatabaseModifiedExternallyNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deregistrationStateDidChange:)
                                                 name:DeregistrationStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(outageStateDidChange:)
                                                 name:OutageDetection.outageStateDidChange
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeDidChange:)
                                                 name:ThemeDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(localProfileDidChange:)
                                                 name:kNSNotificationName_LocalProfileDidChange
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notifications

- (void)signalAccountsDidChange:(id)notification
{
    OWSAssertIsOnMainThread();

    [self reloadTableViewData];
}

- (void)deregistrationStateDidChange:(id)notification
{
    OWSAssertIsOnMainThread();

    [self updateReminderViews];
}

- (void)outageStateDidChange:(id)notification
{
    OWSAssertIsOnMainThread();

    [self updateReminderViews];
}

- (void)localProfileDidChange:(id)notification
{
    OWSAssertIsOnMainThread();

    [self updateBarButtonItems];
}

#pragma mark - Theme

- (void)themeDidChange:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    [self applyTheme];
    [self.tableView reloadData];

    self.hasThemeChanged = YES;
}

- (void)applyTheme
{
    OWSAssertIsOnMainThread();
    OWSAssertDebug(self.tableView);
    OWSAssertDebug(self.searchBar);

    self.view.backgroundColor = Theme.backgroundColor;
    self.tableView.backgroundColor = Theme.backgroundColor;
}

#pragma mark - View Life Cycle

- (void)loadView
{
    [super loadView];

    // TODO: Remove this.
    if (self.homeViewMode == HomeViewMode_Inbox) {
        [SignalApp.sharedApp setHomeViewController:self];
    }

    UIStackView *reminderStackView = [UIStackView new];
    _reminderStackView = reminderStackView;
    reminderStackView.axis = UILayoutConstraintAxisVertical;
    reminderStackView.spacing = 0;
    _reminderViewCell = [UITableViewCell new];
    self.reminderViewCell.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.reminderViewCell.contentView addSubview:reminderStackView];
    [reminderStackView autoPinEdgesToSuperviewEdges];

    __weak HomeViewController *weakSelf = self;
    ReminderView *deregisteredView =
        [ReminderView nagWithText:NSLocalizedString(@"DEREGISTRATION_WARNING",
                                      @"Label warning the user that they have been de-registered.")
                        tapAction:^{
                            HomeViewController *strongSelf = weakSelf;
                            if (!strongSelf) {
                                return;
                            }
                            [RegistrationUtils showReregistrationUIFromViewController:strongSelf];
                        }];
    _deregisteredView = deregisteredView;
    [reminderStackView addArrangedSubview:deregisteredView];

    ReminderView *outageView = [ReminderView
        nagWithText:NSLocalizedString(@"OUTAGE_WARNING", @"Label warning the user that the Signal service may be down.")
          tapAction:nil];
    _outageView = outageView;
    [reminderStackView addArrangedSubview:outageView];

    ReminderView *archiveReminderView =
        [ReminderView explanationWithText:NSLocalizedString(@"INBOX_VIEW_ARCHIVE_MODE_REMINDER",
                                              @"Label reminding the user that they are in archive mode.")];
    _archiveReminderView = archiveReminderView;
    [reminderStackView addArrangedSubview:archiveReminderView];

    ReminderView *missingContactsPermissionView = [ReminderView
        nagWithText:NSLocalizedString(@"INBOX_VIEW_MISSING_CONTACTS_PERMISSION",
                        @"Multi-line label explaining how to show names instead of phone numbers in your inbox")
          tapAction:^{
              [[UIApplication sharedApplication] openSystemSettings];
          }];
    _missingContactsPermissionView = missingContactsPermissionView;
    [reminderStackView addArrangedSubview:missingContactsPermissionView];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = Theme.cellSeparatorColor;
    [self.tableView registerClass:[HomeViewCell class] forCellReuseIdentifier:HomeViewCell.cellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kArchivedConversationsReuseIdentifier];
    [self.view addSubview:self.tableView];
    [self.tableView autoPinEdgesToSuperviewEdges];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;

    UILabel *emptyBoxLabel = [UILabel new];
    self.emptyBoxLabel = emptyBoxLabel;
    [self.view addSubview:emptyBoxLabel];

    //  Let the label use as many lines as needed. It will very rarely be more than 2 but may happen for verbose locs.
    [emptyBoxLabel setNumberOfLines:0];
    emptyBoxLabel.lineBreakMode = NSLineBreakByWordWrapping;

    [emptyBoxLabel autoPinLeadingToSuperviewMargin];
    [emptyBoxLabel autoPinTrailingToSuperviewMargin];
    [emptyBoxLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];

    UIRefreshControl *pullToRefreshView = [UIRefreshControl new];
    pullToRefreshView.tintColor = [UIColor grayColor];
    [pullToRefreshView addTarget:self
                          action:@selector(pullToRefreshPerformed:)
                forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:pullToRefreshView atIndex:0];
}

- (void)updateReminderViews
{
    self.archiveReminderView.hidden = self.homeViewMode != HomeViewMode_Archive;
    // App is killed and restarted when the user changes their contact permissions, so need need to "observe" anything
    // to re-render this.
    self.missingContactsPermissionView.hidden = !self.contactsManager.isSystemContactsDenied;
    self.deregisteredView.hidden = !TSAccountManager.sharedInstance.isDeregistered;
    self.outageView.hidden = !OutageDetection.sharedManager.hasOutage;

    self.hasVisibleReminders = !self.archiveReminderView.isHidden || !self.missingContactsPermissionView.isHidden
        || !self.deregisteredView.isHidden || !self.outageView.isHidden;
}

- (void)setHasVisibleReminders:(BOOL)hasVisibleReminders
{
    if (_hasVisibleReminders == hasVisibleReminders) {
        return;
    }
    _hasVisibleReminders = hasVisibleReminders;
    // If the reminders show/hide, reload the table.
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.editingDbConnection = OWSPrimaryStorage.sharedManager.newDatabaseConnection;
    
    // Create the database connection.
    [self uiDatabaseConnection];

    [self updateMappings];
    [self checkIfEmptyView];
    [self updateReminderViews];
    [self observeNotifications];

    // because this uses the table data source, `tableViewSetup` must happen
    // after mappings have been set up in `showInboxGrouping`
    [self tableViewSetUp];

    switch (self.homeViewMode) {
        case HomeViewMode_Inbox:
            // TODO: Should our app name be translated?  Probably not.
            self.title = NSLocalizedString(@"HOME_VIEW_TITLE_INBOX", @"Title for the home view's default mode.");
            break;
        case HomeViewMode_Archive:
            self.title = NSLocalizedString(@"HOME_VIEW_TITLE_ARCHIVE", @"Title for the home view's 'archive' mode.");
            break;
    }

    [self applyDefaultBackButton];

    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]
        && (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable)) {
        [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    }
    
    // Search

    UISearchBar *searchBar = [OWSSearchBar new];
    _searchBar = searchBar;
    searchBar.placeholder = NSLocalizedString(@"HOME_VIEW_CONVERSATION_SEARCHBAR_PLACEHOLDER",
        @"Placeholder text for search bar which filters conversations.");
    searchBar.delegate = self;
    [searchBar sizeToFit];

    // Setting tableHeader calls numberOfSections, which must happen after updateMappings has been called at least once.
    OWSAssertDebug(self.tableView.tableHeaderView == nil);
    self.tableView.tableHeaderView = self.searchBar;
    // Hide search bar by default.  User can pull down to search.
    self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(searchBar.frame));

    ConversationSearchViewController *searchResultsController = [ConversationSearchViewController new];
    searchResultsController.delegate = self;
    self.searchResultsController = searchResultsController;
    [self addChildViewController:searchResultsController];
    [self.view addSubview:searchResultsController.view];
    [searchResultsController.view autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    if (@available(iOS 11, *)) {
        [searchResultsController.view autoPinTopToSuperviewMarginWithInset:56];
    } else {
        [searchResultsController.view autoPinToTopLayoutGuideOfViewController:self withInset:40];
    }
    searchResultsController.view.hidden = YES;

    [self updateReminderViews];
    [self updateBarButtonItems];

    [self applyTheme];
}

- (void)applyDefaultBackButton
{
    // We don't show any text for the back button, so there's no need to localize it. But because we left align the
    // conversation title view, we add a little tappable padding after the back button, by having a title of spaces.
    // Admittedly this is kind of a hack and not super fine grained, but it's simple and results in the interactive pop
    // gesture animating our title view nicely vs. creating our own back button bar item with custom padding, which does
    // not properly animate with the "swipe to go back" or "swipe left for info" gestures.
    NSUInteger paddingLength = 3;
    NSString *paddingString = [@"" stringByPaddingToLength:paddingLength withString:@" " startingAtIndex:0];

    self.navigationItem.backBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:paddingString style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (void)applyArchiveBackButton
{
    self.navigationItem.backBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BACK_BUTTON", @"button text for back button")
                                         style:UIBarButtonItemStylePlain
                                        target:nil
                                        action:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self displayAnyUnseenUpgradeExperience];
    [self applyDefaultBackButton];

    if (self.hasThemeChanged) {
        [self.tableView reloadData];
        self.hasThemeChanged = NO;
    }

    [self requestReviewIfAppropriate];

    [self.searchResultsController viewDidAppear:animated];

    self.hasEverAppeared = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    [self.searchResultsController viewDidDisappear:animated];
}

- (void)updateBarButtonItems
{
    if (self.homeViewMode != HomeViewMode_Inbox) {
        return;
    }

    //  Settings button.
    UIBarButtonItem *settingsButton;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(11, 0)) {
        const NSUInteger kAvatarSize = 28;
        UIImage *_Nullable localProfileAvatarImage = [OWSProfileManager.sharedManager localProfileAvatarImage];
        UIImage *avatarImage = (localProfileAvatarImage
                ?: [[[OWSContactAvatarBuilder alloc] initForLocalUserWithDiameter:kAvatarSize] buildDefaultImage]);
        OWSAssertDebug(avatarImage);

        UIButton *avatarButton = [AvatarImageButton buttonWithType:UIButtonTypeCustom];
        [avatarButton addTarget:self
                         action:@selector(settingsButtonPressed:)
               forControlEvents:UIControlEventTouchUpInside];
        [avatarButton setImage:avatarImage forState:UIControlStateNormal];
        [avatarButton autoSetDimension:ALDimensionWidth toSize:kAvatarSize];
        [avatarButton autoSetDimension:ALDimensionHeight toSize:kAvatarSize];

        settingsButton = [[UIBarButtonItem alloc] initWithCustomView:avatarButton];
    } else {
        // iOS 9 and 10 have a bug around layout of custom views in UIBarButtonItem,
        // so we just use a simple icon.
        UIImage *image = [UIImage imageNamed:@"button_settings_white"];
        settingsButton = [[UIBarButtonItem alloc] initWithImage:image
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(settingsButtonPressed:)];
    }
    settingsButton.accessibilityLabel = CommonStrings.openSettingsButton;
    self.navigationItem.leftBarButtonItem = settingsButton;

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                      target:self
                                                      action:@selector(showNewConversationView)];
}

- (void)settingsButtonPressed:(id)sender
{
    OWSNavigationController *navigationController = [AppSettingsViewController inModalNavigationController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (nullable UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
                       viewControllerForLocation:(CGPoint)location
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];

    if (!indexPath) {
        return nil;
    }

    if (indexPath.section != HomeViewControllerSectionConversations) {
        return nil;
    }

    [previewingContext setSourceRect:[self.tableView rectForRowAtIndexPath:indexPath]];

    ConversationViewController *vc = [ConversationViewController new];
    TSThread *thread = [self threadForIndexPath:indexPath];
    self.lastThread = thread;
    [vc configureForThread:thread action:ConversationViewActionNone focusMessageId:nil];
    [vc peekSetup];

    return vc;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext
     commitViewController:(UIViewController *)viewControllerToCommit
{
    ConversationViewController *vc = (ConversationViewController *)viewControllerToCommit;
    [vc popped];

    [self.navigationController pushViewController:vc animated:NO];
}

- (void)showNewConversationView
{
    OWSAssertIsOnMainThread();

    OWSLogInfo(@"");

    NewContactThreadViewController *viewController = [NewContactThreadViewController new];

    [self.contactsManager requestSystemContactsOnceWithCompletion:^(NSError *_Nullable error) {
        if (error) {
            OWSLogError(@"Error when requesting contacts: %@", error);
        }
        // Even if there is an error fetching contacts we proceed to the next screen.
        // As the compose view will present the proper thing depending on contact access.
        //
        // We just want to make sure contact access is *complete* before showing the compose
        // screen to avoid flicker.
        OWSNavigationController *modal = [[OWSNavigationController alloc] initWithRootViewController:viewController];
        [self.navigationController presentViewController:modal animated:YES completion:nil];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    __block BOOL hasAnyMessages;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        hasAnyMessages = [self hasAnyMessagesWithTransaction:transaction];
    }];
    if (hasAnyMessages) {
        [self.contactsManager requestSystemContactsOnceWithCompletion:^(NSError *_Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateReminderViews];
            });
        }];
    }

    self.isViewVisible = YES;

    BOOL isShowingSearchResults = !self.searchResultsController.view.hidden;
    if (isShowingSearchResults) {
        OWSAssertDebug(self.searchBar.text.ows_stripped.length > 0);
        [self scrollSearchBarToTopAnimated:NO];
    } else if (self.lastThread) {
        OWSAssertDebug(self.searchBar.text.ows_stripped.length == 0);
        
        // When returning to home view, try to ensure that the "last" thread is still
        // visible.  The threads often change ordering while in conversation view due
        // to incoming & outgoing messages.
        __block NSIndexPath *indexPathOfLastThread = nil;
        [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            indexPathOfLastThread =
            [[transaction extension:TSThreadDatabaseViewExtensionName] indexPathForKey:self.lastThread.uniqueId
                                                                          inCollection:[TSThread collection]
                                                                          withMappings:self.threadMappings];
        }];
        
        if (indexPathOfLastThread) {
            [self.tableView scrollToRowAtIndexPath:indexPathOfLastThread
                                  atScrollPosition:UITableViewScrollPositionNone
                                          animated:NO];
        }
    }

    [self checkIfEmptyView];
    [self applyDefaultBackButton];
    if ([self updateHasArchivedThreadsRow]) {
        [self.tableView reloadData];
    }

    [self.searchResultsController viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.isViewVisible = NO;

    [self.searchResultsController viewWillDisappear:animated];
}

- (void)setIsViewVisible:(BOOL)isViewVisible
{
    _isViewVisible = isViewVisible;

    [self updateShouldObserveDBModifications];
}

- (void)updateShouldObserveDBModifications
{
    BOOL isAppForegroundAndActive = CurrentAppContext().isAppForegroundAndActive;
    self.shouldObserveDBModifications = self.isViewVisible && isAppForegroundAndActive;
}

- (void)setShouldObserveDBModifications:(BOOL)shouldObserveDBModifications
{
    if (_shouldObserveDBModifications == shouldObserveDBModifications) {
        return;
    }

    _shouldObserveDBModifications = shouldObserveDBModifications;

    if (self.shouldObserveDBModifications) {
        [self resetMappings];
    }
}

- (void)reloadTableViewData
{
    // PERF: come up with a more nuanced cache clearing scheme
    [self.threadViewModelCache removeAllObjects];
    [self.tableView reloadData];
}

- (void)resetMappings
{
    // If we're entering "active" mode (e.g. view is visible and app is in foreground),
    // reset all state updated by yapDatabaseModified:.
    if (self.threadMappings != nil) {
        // Before we begin observing database modifications, make sure
        // our mapping and table state is up-to-date.
        //
        // We need to `beginLongLivedReadTransaction` before we update our
        // mapping in order to jump to the most recent commit.
        [self.uiDatabaseConnection beginLongLivedReadTransaction];
        [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [self.threadMappings updateWithTransaction:transaction];
        }];
    }

    [self updateHasArchivedThreadsRow];
    [self reloadTableViewData];

    [self checkIfEmptyView];

    // If the user hasn't already granted contact access
    // we don't want to request until they receive a message.
    __block BOOL hasAnyMessages;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        hasAnyMessages = [self hasAnyMessagesWithTransaction:transaction];
    }];
    if (hasAnyMessages) {
        [self.contactsManager requestSystemContactsOnce];
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self checkIfEmptyView];
}

- (BOOL)hasAnyMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [TSThread numberOfKeysInCollectionWithTransaction:transaction] > 0;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self updateShouldObserveDBModifications];

    // It's possible a thread was created while we where in the background. But since we don't honor contact
    // requests unless the app is in the foregrond, we must check again here upon becoming active.
    __block BOOL hasAnyMessages;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        hasAnyMessages = [self hasAnyMessagesWithTransaction:transaction];
    }];
    
    if (hasAnyMessages) {
        [self.contactsManager requestSystemContactsOnceWithCompletion:^(NSError *_Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateReminderViews];
            });
        }];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self updateShouldObserveDBModifications];
}

#pragma mark - startup

- (NSArray<ExperienceUpgrade *> *)unseenUpgradeExperiences
{
    OWSAssertIsOnMainThread();

    __block NSArray<ExperienceUpgrade *> *unseenUpgrades;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        unseenUpgrades = [ExperienceUpgradeFinder.sharedManager allUnseenWithTransaction:transaction];
    }];
    return unseenUpgrades;
}

- (void)displayAnyUnseenUpgradeExperience
{
    OWSAssertIsOnMainThread();

    NSArray<ExperienceUpgrade *> *unseenUpgrades = [self unseenUpgradeExperiences];

    if (unseenUpgrades.count > 0) {
        ExperienceUpgradesPageViewController *experienceUpgradeViewController =
            [[ExperienceUpgradesPageViewController alloc] initWithExperienceUpgrades:unseenUpgrades];
        [self presentViewController:experienceUpgradeViewController animated:YES completion:nil];
    } else {
        [OWSAlerts showIOSUpgradeNagIfNecessary];
    }
}

- (void)tableViewSetUp
{
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

#pragma mark - Table View Data Source

// Returns YES IFF this value changes.
- (BOOL)updateHasArchivedThreadsRow
{
    BOOL hasArchivedThreadsRow = (self.homeViewMode == HomeViewMode_Inbox && self.numberOfArchivedThreads > 0);
    if (self.hasArchivedThreadsRow == hasArchivedThreadsRow) {
        return NO;
    }
    self.hasArchivedThreadsRow = hasArchivedThreadsRow;

    return YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (NSInteger)[self.threadMappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)aSection
{
    HomeViewControllerSection section = (HomeViewControllerSection)aSection;
    switch (section) {
        case HomeViewControllerSectionReminders: {
            return self.hasVisibleReminders ? 1 : 0;
        }
        case HomeViewControllerSectionConversations: {
            NSInteger result = (NSInteger)[self.threadMappings numberOfItemsInSection:(NSUInteger)section];
            return result;
        }
        case HomeViewControllerSectionArchiveButton: {
            return self.hasArchivedThreadsRow ? 1 : 0;
        }
    }

    OWSFailDebug(@"failure: unexpected section: %lu", (unsigned long)section);
    return 0;
}

- (ThreadViewModel *)threadViewModelForIndexPath:(NSIndexPath *)indexPath
{
    TSThread *threadRecord = [self threadForIndexPath:indexPath];
    OWSAssertDebug(threadRecord);

    ThreadViewModel *_Nullable cachedThreadViewModel = [self.threadViewModelCache objectForKey:threadRecord.uniqueId];
    if (cachedThreadViewModel) {
        return cachedThreadViewModel;
    }

    __block ThreadViewModel *_Nullable newThreadViewModel;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        newThreadViewModel = [[ThreadViewModel alloc] initWithThread:threadRecord transaction:transaction];
    }];
    [self.threadViewModelCache setObject:newThreadViewModel forKey:threadRecord.uniqueId];
    return newThreadViewModel;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeViewControllerSection section = (HomeViewControllerSection)indexPath.section;
    switch (section) {
        case HomeViewControllerSectionReminders: {
            OWSAssert(self.reminderStackView);

            return self.reminderViewCell;
        }
        case HomeViewControllerSectionConversations: {
            return [self tableView:tableView cellForConversationAtIndexPath:indexPath];
        }
        case HomeViewControllerSectionArchiveButton: {
            return [self cellForArchivedConversationsRow:tableView];
        }
    }

    OWSFailDebug(@"failure: unexpected section: %lu", (unsigned long)section);
    return [UITableViewCell new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForConversationAtIndexPath:(NSIndexPath *)indexPath
{
    HomeViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:HomeViewCell.cellReuseIdentifier];
    OWSAssertDebug(cell);

    ThreadViewModel *thread = [self threadViewModelForIndexPath:indexPath];

    BOOL isBlocked = [self.blocklistCache isThreadBlocked:thread.threadRecord];
    [cell configureWithThread:thread isBlocked:isBlocked];

    return cell;
}

- (UITableViewCell *)cellForArchivedConversationsRow:(UITableView *)tableView
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kArchivedConversationsReuseIdentifier];
    OWSAssertDebug(cell);
    [OWSTableItem configureCell:cell];

    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }

    UIImage *disclosureImage = [UIImage imageNamed:(CurrentAppContext().isRTL ? @"NavBarBack" : @"NavBarBackRTL")];
    OWSAssertDebug(disclosureImage);
    UIImageView *disclosureImageView = [UIImageView new];
    disclosureImageView.image = [disclosureImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    disclosureImageView.tintColor = [UIColor colorWithRGBHex:0xd1d1d6];
    [disclosureImageView setContentHuggingHigh];
    [disclosureImageView setCompressionResistanceHigh];

    UILabel *label = [UILabel new];
    label.text = NSLocalizedString(@"HOME_VIEW_ARCHIVED_CONVERSATIONS", @"Label for 'archived conversations' button.");
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont ows_dynamicTypeBodyFont];
    label.textColor = Theme.primaryColor;

    UIStackView *stackView = [UIStackView new];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = 5;
    // If alignment isn't set, UIStackView uses the height of
    // disclosureImageView, even if label has a higher desired height.
    stackView.alignment = UIStackViewAlignmentCenter;
    [stackView addArrangedSubview:label];
    [stackView addArrangedSubview:disclosureImageView];
    [cell.contentView addSubview:stackView];
    [stackView autoCenterInSuperview];
    // Constrain to cell margins.
    [stackView autoPinEdgeToSuperviewMargin:ALEdgeLeading relation:NSLayoutRelationGreaterThanOrEqual];
    [stackView autoPinEdgeToSuperviewMargin:ALEdgeTrailing relation:NSLayoutRelationGreaterThanOrEqual];
    [stackView autoPinEdgeToSuperviewMargin:ALEdgeTop];
    [stackView autoPinEdgeToSuperviewMargin:ALEdgeBottom];

    return cell;
}

- (TSThread *)threadForIndexPath:(NSIndexPath *)indexPath
{
    __block TSThread *thread = nil;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        thread = [[transaction extension:TSThreadDatabaseViewExtensionName] objectAtIndexPath:indexPath
                                                                                 withMappings:self.threadMappings];
    }];

    if (![thread isKindOfClass:[TSThread class]]) {
        OWSLogError(@"Invalid object in thread view: %@", [thread class]);
        [OWSStorage incrementVersionOfDatabaseExtension:TSThreadDatabaseViewExtensionName];
    }

    return thread;
}

- (void)pullToRefreshPerformed:(UIRefreshControl *)refreshControl
{
    OWSAssertIsOnMainThread();
    OWSLogInfo(@"beggining refreshing.");
    [AppEnvironment.shared.messageFetcherJob run].ensure(^{
        OWSLogInfo(@"ending refreshing.");
        [refreshControl endRefreshing];
    });
}

#pragma mark Table Swipe to Delete

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath
{
    return;
}

- (nullable NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeViewControllerSection section = (HomeViewControllerSection)indexPath.section;
    switch (section) {
        case HomeViewControllerSectionReminders: {
            return @[];
        }
        case HomeViewControllerSectionConversations: {
            UITableViewRowAction *deleteAction =
                [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault
                                                   title:NSLocalizedString(@"TXT_DELETE_TITLE", nil)
                                                 handler:^(UITableViewRowAction *action, NSIndexPath *swipedIndexPath) {
                                                     [self tableViewCellTappedDelete:swipedIndexPath];
                                                 }];

            UITableViewRowAction *archiveAction;
            if (self.homeViewMode == HomeViewMode_Inbox) {
                archiveAction = [UITableViewRowAction
                    rowActionWithStyle:UITableViewRowActionStyleNormal
                                 title:NSLocalizedString(@"ARCHIVE_ACTION",
                                           @"Pressing this button moves a thread from the inbox to the archive")
                               handler:^(UITableViewRowAction *_Nonnull action, NSIndexPath *_Nonnull tappedIndexPath) {
                                   [self archiveIndexPath:tappedIndexPath];
                               }];

            } else {
                archiveAction = [UITableViewRowAction
                    rowActionWithStyle:UITableViewRowActionStyleNormal
                                 title:NSLocalizedString(@"UNARCHIVE_ACTION",
                                           @"Pressing this button moves an archived thread from the archive back to "
                                           @"the inbox")
                               handler:^(UITableViewRowAction *_Nonnull action, NSIndexPath *_Nonnull tappedIndexPath) {
                                   [self archiveIndexPath:tappedIndexPath];
                               }];
            }

            return @[ deleteAction, archiveAction ];
        }
        case HomeViewControllerSectionArchiveButton: {
            return @[];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeViewControllerSection section = (HomeViewControllerSection)indexPath.section;
    switch (section) {
        case HomeViewControllerSectionReminders: {
            return NO;
        }
        case HomeViewControllerSectionConversations: {
            return YES;
        }
        case HomeViewControllerSectionArchiveButton: {
            return NO;
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self scrollSearchBarToTopAnimated:NO];

    [self updateSearchResultsVisibility];

    [self ensureSearchBarCancelButton];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self updateSearchResultsVisibility];

    [self ensureSearchBarCancelButton];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self updateSearchResultsVisibility];

    [self ensureSearchBarCancelButton];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self updateSearchResultsVisibility];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.text = nil;

    [self.searchBar resignFirstResponder];
    OWSAssertDebug(!self.searchBar.isFirstResponder);

    [self updateSearchResultsVisibility];

    [self ensureSearchBarCancelButton];
}

- (void)ensureSearchBarCancelButton
{
    self.searchBar.showsCancelButton = (self.searchBar.isFirstResponder || self.searchBar.text.length > 0);
}

- (void)updateSearchResultsVisibility
{
    OWSAssertIsOnMainThread();

    NSString *searchText = self.searchBar.text.ows_stripped;
    self.searchResultsController.searchText = searchText;
    BOOL isSearching = searchText.length > 0;
    self.searchResultsController.view.hidden = !isSearching;

    if (isSearching) {
        [self scrollSearchBarToTopAnimated:NO];
        self.tableView.scrollEnabled = NO;
    } else {
        self.tableView.scrollEnabled = YES;
    }
}

- (void)scrollSearchBarToTopAnimated:(BOOL)isAnimated
{
    CGFloat topInset = self.topLayoutGuide.length;
    [self.tableView setContentOffset:CGPointMake(0, -topInset) animated:isAnimated];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
    OWSAssertDebug(!self.searchBar.isFirstResponder);
}

#pragma mark - ConversationSearchViewDelegate

- (void)conversationSearchViewWillBeginDragging
{
    [self.searchBar resignFirstResponder];
    OWSAssertDebug(!self.searchBar.isFirstResponder);
}

#pragma mark - HomeFeedTableViewCellDelegate

- (void)tableViewCellTappedDelete:(NSIndexPath *)indexPath
{
    if (indexPath.section != HomeViewControllerSectionConversations) {
        OWSFailDebug(@"failure: unexpected section: %lu", (unsigned long)indexPath.section);
        return;
    }

    TSThread *thread = [self threadForIndexPath:indexPath];

    if (![thread isKindOfClass:[TSGroupThread class]]) {
        [self deleteThread:thread];
        return;
    }

    TSGroupThread *gThread = (TSGroupThread *)thread;
    if (![gThread.groupModel.groupMemberIds containsObject:[TSAccountManager localNumber]]) {
        [self deleteThread:thread];
        return;
    }

    [ThreadUtil enqueueLeaveGroupMessageInThread:gThread];

    // MJK TODO - DURABLE TESTPLAN is this safe to delete the gThread when the outgoing message hasn't completed
    // sending?
    [self deleteThread:thread];
}

- (void)deleteThread:(TSThread *)thread
{
    [self.editingDbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [thread removeWithTransaction:transaction];
    }];

    [self checkIfEmptyView];
}

- (void)archiveIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != HomeViewControllerSectionConversations) {
        OWSFailDebug(@"failure: unexpected section: %lu", (unsigned long)indexPath.section);
        return;
    }

    TSThread *thread = [self threadForIndexPath:indexPath];

    [self.editingDbConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        switch (self.homeViewMode) {
            case HomeViewMode_Inbox:
                [thread archiveThreadWithTransaction:transaction];
                break;
            case HomeViewMode_Archive:
                [thread unarchiveThreadWithTransaction:transaction];
                break;
        }
    }];
    [self checkIfEmptyView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OWSLogInfo(@"%ld %ld", (long)indexPath.row, (long)indexPath.section);

    [self.searchBar resignFirstResponder];
    HomeViewControllerSection section = (HomeViewControllerSection)indexPath.section;
    switch (section) {
        case HomeViewControllerSectionReminders: {
            break;
        }
        case HomeViewControllerSectionConversations: {
            TSThread *thread = [self threadForIndexPath:indexPath];
            [self presentThread:thread action:ConversationViewActionNone animated:YES];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        case HomeViewControllerSectionArchiveButton: {
            [self showArchivedConversations];
            break;
        }
    }
}

- (void)presentThread:(TSThread *)thread action:(ConversationViewAction)action animated:(BOOL)isAnimated
{
    [self presentThread:thread action:action focusMessageId:nil animated:isAnimated];
}

- (void)presentThread:(TSThread *)thread
               action:(ConversationViewAction)action
       focusMessageId:(nullable NSString *)focusMessageId
             animated:(BOOL)isAnimated
{
    if (thread == nil) {
        OWSFailDebug(@"Thread unexpectedly nil");
        return;
    }

    DispatchMainThreadSafe(^{
        ConversationViewController *conversationVC = [ConversationViewController new];
        [conversationVC configureForThread:thread action:action focusMessageId:focusMessageId];
        self.lastThread = thread;

        if (self.homeViewMode == HomeViewMode_Archive) {
            [self.navigationController pushViewController:conversationVC animated:isAnimated];
        } else {
            [self.navigationController setViewControllers:@[ self, conversationVC ] animated:isAnimated];
        }
    });
}

#pragma mark - Groupings
- (YapDatabaseViewMappings *)threadMappings
{
    OWSAssertDebug(_threadMappings != nil);
    return _threadMappings;
}

- (void)showInboxGrouping
{
    OWSAssertDebug(self.homeViewMode == HomeViewMode_Archive);

    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)showArchivedConversations
{
    OWSAssertDebug(self.homeViewMode == HomeViewMode_Inbox);

    // When showing archived conversations, we want to use a conventional "back" button
    // to return to the "inbox" home view.
    [self applyArchiveBackButton];

    // Push a separate instance of this view using "archive" mode.
    HomeViewController *homeView = [HomeViewController new];
    homeView.homeViewMode = HomeViewMode_Archive;
    [self.navigationController pushViewController:homeView animated:YES];
}

- (NSString *)currentGrouping
{
    switch (self.homeViewMode) {
        case HomeViewMode_Inbox:
            return TSInboxGroup;
        case HomeViewMode_Archive:
            return TSArchiveGroup;
    }
}

- (void)updateMappings
{
    OWSAssertIsOnMainThread();

    self.threadMappings = [[YapDatabaseViewMappings alloc]
        initWithGroups:@[ kReminderViewPseudoGroup, self.currentGrouping, kArchiveButtonPseudoGroup ]
                  view:TSThreadDatabaseViewExtensionName];
    [self.threadMappings setIsReversed:YES forGroup:self.currentGrouping];

    [self resetMappings];

    [self reloadTableViewData];
    [self checkIfEmptyView];
    [self updateReminderViews];
}

#pragma mark Database delegates

- (YapDatabaseConnection *)uiDatabaseConnection
{
    OWSAssertIsOnMainThread();

    if (!_uiDatabaseConnection) {
        _uiDatabaseConnection = [OWSPrimaryStorage.sharedManager newDatabaseConnection];
        // default is 250
        _uiDatabaseConnection.objectCacheLimit = 500;
        [_uiDatabaseConnection beginLongLivedReadTransaction];
    }
    return _uiDatabaseConnection;
}

- (void)yapDatabaseModifiedExternally:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    OWSLogVerbose(@"");

    if (self.shouldObserveDBModifications) {
        // External database modifications can't be converted into incremental updates,
        // so rebuild everything.  This is expensive and usually isn't necessary, but
        // there's no alternative.
        //
        // We don't need to do this if we're not observing db modifications since we'll
        // do it when we resume.
        [self resetMappings];
    }
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    OWSAssertIsOnMainThread();

    if (!self.shouldObserveDBModifications) {
        return;
    }

    OWSLogVerbose(@"");

    NSArray *notifications = [self.uiDatabaseConnection beginLongLivedReadTransaction];

    if (![[self.uiDatabaseConnection ext:TSThreadDatabaseViewExtensionName] hasChangesForGroup:self.currentGrouping
                                                                               inNotifications:notifications]) {
        [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [self.threadMappings updateWithTransaction:transaction];
        }];
        [self checkIfEmptyView];

        return;
    }

    // If the user hasn't already granted contact access
    // we don't want to request until they receive a message.
    __block BOOL hasAnyMessages;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *_Nonnull transaction) {
        hasAnyMessages = [self hasAnyMessagesWithTransaction:transaction];
    }];

    if (hasAnyMessages) {
        [self.contactsManager requestSystemContactsOnce];
    }

    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    [[self.uiDatabaseConnection ext:TSThreadDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                              rowChanges:&rowChanges
                                                                        forNotifications:notifications
                                                                            withMappings:self.threadMappings];

    // We want this regardless of if we're currently viewing the archive.
    // So we run it before the early return
    [self checkIfEmptyView];

    if ([sectionChanges count] == 0 && [rowChanges count] == 0) {
        return;
    }

    if ([self updateHasArchivedThreadsRow]) {
        [self.tableView reloadData];
        return;
    }

    [self.tableView beginUpdates];

    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges) {
        switch (sectionChange.type) {
            case YapDatabaseViewChangeDelete: {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert: {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate:
            case YapDatabaseViewChangeMove:
                break;
        }
    }

    for (YapDatabaseViewRowChange *rowChange in rowChanges) {
        NSString *key = rowChange.collectionKey.key;
        OWSAssertDebug(key);
        [self.threadViewModelCache removeObjectForKey:key];

        switch (rowChange.type) {
            case YapDatabaseViewChangeDelete: {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert: {
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove: {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate: {
                [self.tableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }

    [self.tableView endUpdates];
}

- (NSUInteger)numberOfThreadsInGroup:(NSString *)group
{
    // We need to consult the db view, not the mapping since the mapping only knows about
    // the current group.
    __block NSUInteger result;
    [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        YapDatabaseViewTransaction *viewTransaction = [transaction ext:TSThreadDatabaseViewExtensionName];
        result = [viewTransaction numberOfItemsInGroup:group];
    }];
    return result;
}

- (NSUInteger)numberOfInboxThreads
{
    return [self numberOfThreadsInGroup:TSInboxGroup];
}

- (NSUInteger)numberOfArchivedThreads
{
    return [self numberOfThreadsInGroup:TSArchiveGroup];
}

- (void)checkIfEmptyView
{
    NSUInteger inboxCount = self.numberOfInboxThreads;
    NSUInteger archiveCount = self.numberOfArchivedThreads;

    if (self.homeViewMode == HomeViewMode_Inbox && inboxCount == 0 && archiveCount == 0) {
        [self updateEmptyBoxText];
        [_tableView setHidden:YES];
        [_emptyBoxLabel setHidden:NO];
    } else if (self.homeViewMode == HomeViewMode_Archive && archiveCount == 0) {
        [self updateEmptyBoxText];
        [_tableView setHidden:YES];
        [_emptyBoxLabel setHidden:NO];
    } else {
        [_emptyBoxLabel setHidden:YES];
        [_tableView setHidden:NO];
    }
}

- (void)updateEmptyBoxText
{
    // TODO: Theme, review with design.
    _emptyBoxLabel.textColor = [UIColor grayColor];
    _emptyBoxLabel.font = [UIFont ows_regularFontWithSize:18.f];
    _emptyBoxLabel.textAlignment = NSTextAlignmentCenter;

    NSString *firstLine = @"";
    NSString *secondLine = @"";

    if (self.homeViewMode == HomeViewMode_Inbox) {
        if ([Environment.shared.preferences hasSentAMessage]) {
            firstLine = NSLocalizedString(
                @"EMPTY_INBOX_TITLE", @"Header text an existing user sees when viewing an empty inbox");
            secondLine = NSLocalizedString(
                @"EMPTY_INBOX_TEXT", @"Body text an existing user sees when viewing an empty inbox");
        } else {
            firstLine = NSLocalizedString(
                @"EMPTY_INBOX_NEW_USER_TITLE", @"Header text a new user sees when viewing an empty inbox");
            secondLine = NSLocalizedString(
                @"EMPTY_INBOX_NEW_USER_TEXT", @"Body text a new user sees when viewing an empty inbox");
        }
    } else {
        OWSAssertDebug(self.homeViewMode == HomeViewMode_Archive);
        firstLine = NSLocalizedString(
            @"EMPTY_ARCHIVE_TITLE", @"Header text an existing user sees when viewing an empty archive");
        secondLine = NSLocalizedString(
            @"EMPTY_ARCHIVE_TEXT", @"Body text an existing user sees when viewing an empty archive");
    }
    NSMutableAttributedString *fullLabelString =
        [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n%@", firstLine, secondLine]];

    [fullLabelString addAttribute:NSFontAttributeName
                            value:[UIFont ows_boldFontWithSize:15.f]
                            range:NSMakeRange(0, firstLine.length)];
    [fullLabelString addAttribute:NSFontAttributeName
                            value:[UIFont ows_regularFontWithSize:14.f]
                            range:NSMakeRange(firstLine.length + 1, secondLine.length)];
    [fullLabelString addAttribute:NSForegroundColorAttributeName
                            value:Theme.primaryColor
                            range:NSMakeRange(0, firstLine.length)];
    // TODO: Theme, Review with design.
    [fullLabelString addAttribute:NSForegroundColorAttributeName
                            value:Theme.secondaryColor
                            range:NSMakeRange(firstLine.length + 1, secondLine.length)];
    _emptyBoxLabel.attributedText = fullLabelString;
}

// We want to delay asking for a review until an opportune time.
// If the user has *just* launched Signal they intend to do something, we don't want to interrupt them.
// If the user hasn't sent a message, we don't want to ask them for a review yet.
- (void)requestReviewIfAppropriate
{
    if (self.hasEverAppeared && Environment.shared.preferences.hasSentAMessage) {
        OWSLogDebug(@"requesting review");
        if (@available(iOS 10, *)) {
            // In Debug this pops up *every* time, which is helpful, but annoying.
            // In Production this will pop up at most 3 times per 365 days.
#ifndef DEBUG
            static dispatch_once_t onceToken;
            // Despite `SKStoreReviewController` docs, some people have reported seeing the "request review" prompt
            // repeatedly after first installation. Let's make sure it only happens at most once per launch.
            dispatch_once(&onceToken, ^{
                [SKStoreReviewController requestReview];
            });
#endif
        }
    } else {
        OWSLogDebug(@"not requesting review");
    }
}

#pragma mark - OWSBlockListCacheDelegate

- (void)blockListCacheDidUpdate:(OWSBlockListCache *_Nonnull)blocklistCache
{
    OWSLogVerbose(@"");
    [self reloadTableViewData];
}

@end

NS_ASSUME_NONNULL_END
