
//
//  VNContactsViewController.swift
//  TestTabbedNavigationWithLargeTitles
//
//  Created by Илья on 05/08/2019.
//  Copyright © 2019 Илья. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

@objc class VNContactsViewController: VinciViewController {
    
    // MARK: Title Views
    let navigationBar = VinciTopMenuController(title: "")
    var navigationBarTopConstraint: NSLayoutConstraint!
    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    
    var searchResultsController: VinciContactsSearchResultsController!
    var hideSearchBarWhenScrolling = true
    
    var headerViewMaxHeight: CGFloat = 128.0
    let headerViewMinHeight: CGFloat = 42.0
    
    //
    
    enum VNContactsSection: Int {
        case sectionReminder = 0
        case sectionInviteFriends = 1
        case sectionVinciContacts = 2
        case sectionVinciUndefined = 3
        
        static let count: Int = {
            var max: Int = 0
            while let _ = VNContactsSection(rawValue: max) { max += 1 }
            
            return max-1 // why minus 1? i don't need Undefined section, but i need it to complete switch-cases
        }()
    }
    
    // MARK: G U I
    var collation: UILocalizedIndexedCollation!
    var modeWithCollation = false {
        didSet {
            updateTableContent()
        }
    }
    
    // vinci
    // The bulk of the content in this view is driven by a YapDB view/mapping.
    // However, we also want to optionally include ReminderView's at the top
    // and an "Archived Conversations" button at the bottom. Rather than introduce
    // index-offsets into the Mapping calculation, we introduce two pseudo groups
    // to add a top and bottom section to the content, and create cells for those
    // sections without consulting the YapMapping.
    // This is a bit of a hack, but it consolidates the hacks into the Reminder/Archive section
    // and allows us to leaves the bulk of the content logic on the happy path.
    let kReminderViewPseudoGroup:String = "kReminderViewPseudoGroup"
    
    // vinci
    var shouldObserveDBModifications:Bool = true
    
    // vinci
    var emptyInboxView:UIView!
    
    var editingDatabaseConnection:YapDatabaseConnection!
    var databaseConnection:YapDatabaseConnection!
    
    // MARK: Search
    var searchBar:UISearchBar!
//    var isSearching = false
    
    // A list of possible phone numbers parsed from the search text as
    // E164 values.
    var searchPhoneNumbers = [String]()
    
    // data
    var vinciAccounts = [SignalAccount]()
    var collatedVinciAccounts = [[SignalAccount]]()
    var globalVinciAccounts = [SignalAccount]()
    var sectionsMap = [VNContactsSection:Int]()
    
    // Dependencies
    
    var accountManager:AccountManager!
    var contactsManager:OWSContactsManager!
    var messageSender:MessageSender!
    var blocklistCache:BlockListCache!
    
    // This set is used to cache the set of non-contact phone numbers
    // which are known to correspond to Signal accounts.
    var nonContactAccountSet: Set<String>!
    var contactsViewHelper: ContactsViewHelper!
    
    // contacts are not allowed for Vinci app
    var isNoContactsModeActive:Bool = false {
        willSet {
            if self.isNoContactsModeActive == newValue {
                return
            }
            
            self.isNoContactsModeActive = newValue
            
            if self.isNoContactsModeActive {
                tableView.isHidden = true
                searchBar.isHidden = true
            } else {
                tableView.isHidden = true
                searchBar.isHidden = true
            }
        }
    }
    
    // Views
    
    var reminderStackView:UIStackView!
    var reminderViewCell:UITableViewCell!
    var deregisteredView:UIView!
    var outageView:UIView!
    var missingContactsPermissionView:UIView!
    
    var hasThemeChanged:Bool = false
    var hasVisibleReminders:Bool = false
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    func commonInit() {
        self.accountManager = AppEnvironment.shared.accountManager
        self.contactsManager = Environment.shared.contactsManager
        self.messageSender = SSKEnvironment.shared.messageSender
        self.blocklistCache = BlockListCache()
        self.blocklistCache.startObservingAndSyncState(delegate: self)
        //        self.callViewModelCache = NSCache()
        
        contactsViewHelper = ContactsViewHelper(delegate: self)
        
        searchBar = navigationBar.searchBar.searchBar
        navigationBar.searchBar.searchDelegate = self
        searchResultsController = VinciContactsSearchResultsController()
        
        // Make sure we have requested contact access at this point if, e.g.
        // the user has no messages in their inbox and they choose to compose
        // a message.
        contactsViewHelper.contactsManager.requestSystemContactsOnce()
        
        collation = UILocalizedIndexedCollation.current()
        
        //        let searchBackground = UIImage(color: UIColor.magenta)
        //        searchBar.setBackgroundImage(searchBackground, for: .any, barMetrics: .default)
        
        // Ensure ExperienceUpgradeFinder has been initialized.
        //#pragma GCC diagnostic push
        //#pragma GCC diagnostic ignored "-Wunused-result"
        let _ = ExperienceUpgradeFinder.shared
        //#pragma GCC diagnostic pop
    }
    
    func defineSection(section: Int) -> VNContactsSection {
        switch section {
        case VNContactsSection.sectionReminder.rawValue:
            return VNContactsSection.sectionReminder
        case VNContactsSection.sectionInviteFriends.rawValue:
            return VNContactsSection.sectionInviteFriends
        case VNContactsSection.sectionVinciContacts.rawValue:
            return VNContactsSection.sectionVinciContacts
        default:
            return VNContactsSection.sectionVinciUndefined
        }
    }
    
    func observeNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(signalAccountsDidChange(notification:)),
                                               name: .OWSContactsManagerSignalAccountsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)),
                                               name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)),
                                               name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)),
                                               name: Notification.Name.UIApplicationWillResignActive, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(yapDatabaseModified(notification:)),
                                               name: .YapDatabaseModified, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(yapDatabaseModifiedExternally(notification:)),
                                               name: .YapDatabaseModifiedExternally, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(registrationStateDidChange(notification:)),
                                               name: .RegistrationStateDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(outageStateDidChange(notification:)),
                                               name: OutageDetection.outageStateDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(localProfileDidChange(notification:)),
                                               name: NSNotification.Name(rawValue: kNSNotificationName_LocalProfileDidChange), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange(notification:)),
                                               name: .ThemeDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications
    
    @objc func signalAccountsDidChange(notification:Notification) {
        //        OWSAssertIsOnMainThread();
        reloadTableViewData()
    }
    
    @objc func registrationStateDidChange(notification:Notification) {
        //        OWSAssertIsOnMainThread();
        updateReminderViews()
    }
    
    @objc func outageStateDidChange(notification:Notification) {
        //        OWSAssertIsOnMainThread();
        updateReminderViews()
    }
    
    @objc func localProfileDidChange(notification:Notification) {
        //        OWSAssertIsOnMainThread();
        updateBarButtonItems()
    }
    
    @objc func themeDidChange(notification: NSNotification) {
        //        OWSAssertIsOnMainThread();
        
        applyTheme()
        tableView.reloadData()
        
        hasThemeChanged = true
    }
    
    func applyTheme() {
        //        OWSAssertIsOnMainThread();
        //        OWSAssertDebug(self.tableView);
        //        OWSAssertDebug(self.searchBar);
        
        view.backgroundColor = Theme.backgroundColor
        tableView.backgroundColor = Theme.backgroundColor
    }
    
    // MARK: View Life Cycle
    override func loadView() {
        super.loadView()
        
        // VINCI do I need this? This VC is not main anymore.
        //        // TODO: Remove this
        //        if ( self.callsViewMode == .callsViewMode_All || self.callsViewMode == .callsViewMode_Missed ) {
        //            SignalApp.shared().vinciCallsViewController = self
        //        }
        
        reminderStackView = UIStackView()
        reminderStackView.axis = .vertical
        reminderStackView.spacing = 0
        
        reminderViewCell = UITableViewCell()
        reminderViewCell.selectionStyle = .none
        reminderViewCell.contentView.addSubview(reminderStackView)
        reminderStackView.autoPinEdgesToSuperviewEdges()
        
        deregisteredView = ReminderView.nag(text: NSLocalizedString("DEREGISTRATION_WARNING", comment: "Label warning the user that they have been de-registered."), tapAction: ({
            RegistrationUtils.showReregistrationUI(from: self)
        }))
        reminderStackView.addArrangedSubview(deregisteredView)
        
        outageView = ReminderView.nag(text: NSLocalizedString("OUTAGE_WARNING", comment: "Label warning the user that the Signal service may be down."), tapAction: nil)
        reminderStackView.addArrangedSubview(outageView)
        
        missingContactsPermissionView = ReminderView.nag(text: NSLocalizedString("INBOX_VIEW_MISSING_CONTACTS_PERMISSION", comment: "Multi-line label explaining how to show names instead of phone numbers in your inbox"), tapAction: ({
            UIApplication.shared.openSystemSettings()
        }))
        reminderStackView.addArrangedSubview(missingContactsPermissionView)
        
        emptyInboxView = createEmptyInboxView()
        view.addSubview(emptyInboxView)
        emptyInboxView.ows_autoPinToSuperviewEdges()
        //        emptyInboxView.autoPinWidthToSuperview()
        //        emptyInboxView.autoVCenterInSuperview()
    }
    
    func createEmptyInboxView() -> UIView {
        let emptyView = UIView()
        emptyView.backgroundColor = Theme.backgroundColor
        
        //        let safeTopOffset = navigationController!.navigationBar.frame.origin.y + navigationController!.navigationBar.frame.size.height
        
        let emptyChatsImageView = UIImageView(image: UIImage(named: "emptyChatsIcon"))
        emptyView.addSubview(emptyChatsImageView)
        emptyChatsImageView.autoVCenterInSuperview()
        emptyChatsImageView.autoPinEdge(.right, to: .right, of: emptyView)
        
        // welcome label
        let welcomeLabel = UILabel()
        welcomeLabel.attributedText = VinciStrings.welcomeAttributedStrings(type: .welcomeVinci)
        welcomeLabel.numberOfLines = 2
        welcomeLabel.sizeToFit()
        emptyView.addSubview(welcomeLabel)
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        let welcomeTopConstraint = welcomeLabel.topAnchor.constraint(greaterThanOrEqualTo: emptyView.topAnchor, constant: 180)
        welcomeTopConstraint.isActive = true
        welcomeLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 16.0).isActive = true
        
        // emplace labels
        let inviteStartLabel = UILabel()
        inviteStartLabel.attributedText = VinciStrings.emptyChatsAttributedStrings(type: .startConversation)
        inviteStartLabel.numberOfLines = 2
        inviteStartLabel.sizeToFit()
        emptyView.addSubview(inviteStartLabel)
        inviteStartLabel.translatesAutoresizingMaskIntoConstraints = false
        inviteStartLabel.topAnchor.constraint(greaterThanOrEqualTo: welcomeLabel.bottomAnchor, constant: -32.0).isActive = true
        inviteStartLabel.leftAnchor.constraint(equalTo: emptyView.leftAnchor, constant: 30.0 + 16.0).isActive = true
        
        let toBeginLabel = UITextView()
        toBeginLabel.backgroundColor = UIColor.clear
        toBeginLabel.isEditable = false
        toBeginLabel.isScrollEnabled = true
        toBeginLabel.dataDetectorTypes = .link
        toBeginLabel.sizeToFit()
        toBeginLabel.isSelectable = false
        emptyView.addSubview(toBeginLabel)
        toBeginLabel.translatesAutoresizingMaskIntoConstraints = false
        toBeginLabel.topAnchor.constraint(equalTo: inviteStartLabel.topAnchor, constant: 69.0).isActive = true
        toBeginLabel.leftAnchor.constraint(equalTo: inviteStartLabel.leftAnchor, constant: 2.0).isActive = true
        toBeginLabel.rightAnchor.constraint(equalTo: emptyView.rightAnchor).isActive = true
        toBeginLabel.heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        toBeginLabel.linkTextAttributes = [NSAttributedString.Key.foregroundColor.rawValue: UIColor.vinciBrandOrange]
        toBeginLabel.attributedText = VinciStrings.emptyChatsAttributedStrings(type: .toBegin)
        
        return emptyView
    }
    
    func updateReminderViews() {
        
        let missingContactsPermissionIsHidden = !self.contactsManager.isSystemContactsDenied
        let deregisteredIsHidden = !TSAccountManager.sharedInstance().isDeregistered()
        let outageIsHidden = !OutageDetection.shared.hasOutage
        
        // App is killed and restarted when the user changes their contact permissions, so need need to "observe" anything
        // to re-render this.
        self.missingContactsPermissionView.isHidden = missingContactsPermissionIsHidden
        self.deregisteredView.isHidden = deregisteredIsHidden
        self.outageView.isHidden = outageIsHidden
        
        self.setHasVisibleReminders(hasVisibleReminders: !self.missingContactsPermissionView.isHidden || !self.deregisteredView.isHidden || !self.outageView.isHidden)
    }
    
    func setHasVisibleReminders(hasVisibleReminders:Bool) {
        if ( self.hasVisibleReminders == hasVisibleReminders ) {
            return
        }
        self.hasVisibleReminders = hasVisibleReminders
        // If the reminders show/hide, reload the table.
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.titleType = .contactsTitle
        
        view.addSubview(navigationBar.view)
        navigationBarTopConstraint = navigationBar.pinToTop()
        
        headerViewMaxHeight = navigationBar.maxBarHeight
        
        if let topTitleView = navigationBar.topTitleView as? VinciTopMenuRowViewController {
            topTitleView.leftBarItems.append(UIBarButtonItem(image: UIImage(named: "vinciSettingsIcon"), style: .plain, target: self, action: #selector(settingsButtonPressed)))
            topTitleView.rightBarItems.append(UIBarButtonItem(image: UIImage(named: "plusAttachmentIcon"), style: .plain, target: self, action: #selector(newContactButtonPressed)))
        }
        
        editingDatabaseConnection = OWSPrimaryStorage.shared().newDatabaseConnection()
        
        // Create the database connection.
        databaseConnection = uiDatabaseConnection()
        
        //        updateMappings()
        updateViewState()
        updateReminderViews()
        observeNotifications()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.register(VinciContactViewCell.self, forCellReuseIdentifier: "VinciContactViewCell")
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: navigationBar.view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        // because this uses the table data source, `tableViewSetup` must happen
        // after mappings have been set up in `showInboxGrouping`
        tableViewSetUp()
        
        //        searchController.searchBar.placeholder = "search chats"
        
//        if traitCollection.responds(to: #selector(getter: traitCollection.forceTouchCapability)) &&
//            traitCollection.forceTouchCapability == UIForceTouchCapability.available {
//            registerForPreviewing(with: self, sourceView: tableView)
//        }
        
        searchBar.placeholder = "Search for contacts or usernames"
        
        searchResultsController.delegate = self
        
        navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        
        self.updateReminderViews()
        self.updateBarButtonItems()
        
        updateTableContent()
        
        self.applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.tabBarController?.tabBar.isHidden = false
        
        if ( hasThemeChanged ) {
            tableView.reloadData()
            hasThemeChanged = false
        }
        
        requestReviewIfAppropriate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.bringSubview(toFront: view)
        
        //        var hasAnyMessages:Bool = false
        //        uiDatabaseConnection().read { (transaction) in
        //            hasAnyMessages = self.hasAnyMessages(withTransaction: transaction)
        //        }
        //
        //        if ( hasAnyMessages ) {
        contactsManager.requestSystemContactsOnce { (error) in
            DispatchQueue.main.async {
                self.updateReminderViews()
            }
        }
        //        }
        
        //        let isShowingSearchResults:Bool = !searchResultsController.view.isHidden
        //        if ( isShowingSearchResults ) {
        //            // OWSAssertDebug(self.searchBar.text.ows_stripped.length > 0);
        //
        //            scrollSearchBarToTopAnimated(animated: false)
        //        } else if ( lastCall != nil ) {
        //            // OWSAssertDebug(self.searchBar.text.ows_stripped.length == 0);
        //
        //            // When returning to home view, try to ensure that the "last" thread is still
        //            // visible.  The threads often change ordering while in conversation view due
        //            // to incoming & outgoing messages.
        //            var indexPathOfLastThread:IndexPath?
        //            uiDatabaseConnection().read { (transaction) in
        //                let extTransaction:YapDatabaseViewTransaction = transaction.extension(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewTransaction
        //                indexPathOfLastThread = extTransaction.indexPath(forKey: self.lastCall!.uniqueId!,
        //                                                                 inCollection: TSThread.collection(),
        //                                                                 with: self.threadMappings)
        //            }
        //
        //            if ( indexPathOfLastThread != nil ) {
        //                tableView.scrollToRow(at: indexPathOfLastThread!, at: .none, animated: false)
        //            }
        //
        //            updateViewState()
        //            applyDefaultBackButton()
        //
        //            searchResultsController.viewWillAppear(animated)
        //        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func updateBarButtonItems() {
        
//        // Settings button.
//        var settingsButton:UIBarButtonItem!
//
//        // VINCI settings button with icon
//        let image = UIImage(named: "vinciSettingsIcon")
//        settingsButton = UIBarButtonItem.init(image: image, style: .plain, target: self, action: #selector(settingsButtonPressed))
//        settingsButton.tintColor = UIColor.vinciBrandBlue
//        settingsButton.accessibilityLabel = CommonStrings.openSettingsButton
//        self.navigationItem.leftBarButtonItem = settingsButton
//        //        SET_SUBVIEW_ACCESSIBILITY_IDENTIFIER(self, settingsButton);
//
//        var rightBarButtons:[UIBarButtonItem] = []
//        let addContactButton = UIBarButtonItem.init(barButtonSystemItem: .add, target: self, action: #selector(newContactButtonPressed))
//        rightBarButtons.append(addContactButton)
//
//        self.navigationItem.rightBarButtonItems = rightBarButtons
    }
    
    func showContactAppropriateViews() {
        if contactsViewHelper.contactsManager.isSystemContactsAuthorized {
            if contactsViewHelper.hasUpdatedContactsAtLeastOnce
                && contactsViewHelper.signalAccounts.count < 1
                && !Environment.shared.preferences.hasDeclinedNoContactsView() {
                isNoContactsModeActive = true
            } else {
                isNoContactsModeActive = false
            }
            
            searchBar.isHidden = false
        } else {
            // don't show "no signal contacts", show "no contact access"
            isNoContactsModeActive = false
            searchBar.isHidden = true
        }
    }
    
    func updateViewState() {
        if ( shouldShowFirstConversationCue() ) {
            self.tableView.isHidden = true
            self.emptyInboxView?.isHidden = false
        } else {
            self.tableView.isHidden = false
            self.emptyInboxView?.isHidden = true
        }
    }
    
    func updateTableContent() {
        
        // vinci update
        let searchText = searchBar.text ?? ""
        vinciAccounts = contactsViewHelper.signalAccounts(matchingSearch: searchText)
        collatedVinciAccounts = collation.partitionObjects(array: vinciAccounts,
                                                           collationStringSelector: #selector(SignalAccount.stringForCollation)) as! [[SignalAccount]]
        
        sectionsMap.removeAll()
        sectionsMap[.sectionReminder] = hasVisibleReminders ? 1 : 0
        sectionsMap[.sectionVinciContacts] = collatedVinciAccounts.count
        sectionsMap[.sectionVinciUndefined] = 0
        
        if self.isNoContactsModeActive {
            // edit here - left current content
            return
        }
        
        // App is killed and restarted when the user changes their contact permissions, so need need to "observe" anything
        // to re-render this.
        if contactsViewHelper.contactsManager.isSystemContactsDenied {
            //            OWSTableItem *contactReminderItem = [OWSTableItem
            //                itemWithCustomCellBlock:^{
            //                UITableViewCell *newCell = [OWSTableItem newCell];
            //
            //                ReminderView *reminderView = [ReminderView
            //                nagWithText:NSLocalizedString(@"COMPOSE_SCREEN_MISSING_CONTACTS_PERMISSION",
            //                @"Multi-line label explaining why compose-screen contact picker is empty.")
            //                tapAction:^{
            //                [[UIApplication sharedApplication] openSystemSettings];
            //                }];
            //                [newCell.contentView addSubview:reminderView];
            //                [reminderView autoPinEdgesToSuperviewEdges];
            //
            //                return newCell;
            //                }
            //                customRowHeight:UITableViewAutomaticDimension
            //                actionBlock:nil];
            //
            //            OWSTableSection *reminderSection = [OWSTableSection new];
            //            [reminderSection addItem:contactReminderItem];
            //            [contents addSection:reminderSection];
        }
        
        //        OWSTableSection *staticSection = [OWSTableSection new];
        
        //        // Find Non-Contacts by Phone Number
        //        [staticSection
        //            addItem:[OWSTableItem disclosureItemWithText:NSLocalizedString(@"NEW_CONVERSATION_FIND_BY_PHONE_NUMBER",
        //            @"A label the cell that lets you add a new member to a group.")
        //            customRowHeight:UITableViewAutomaticDimension
        //            actionBlock:^{
        //            NewNonContactConversationViewController *viewController =
        //            [NewNonContactConversationViewController new];
        //            viewController.nonContactConversationDelegate = weakSelf;
        //            [weakSelf.navigationController pushViewController:viewController
        //            animated:YES];
        //            }]];
        
        if contactsViewHelper.contactsManager.isSystemContactsAuthorized {
            sectionsMap[.sectionInviteFriends] = 1
            // Invite Contacts
            //            [staticSection
            //                addItem:[OWSTableItem
            //                disclosureItemWithText:NSLocalizedString(@"INVITE_FRIENDS_CONTACT_TABLE_BUTTON",
            //                @"Label for the cell that presents the 'invite contacts' workflow.")
            //                customRowHeight:UITableViewAutomaticDimension
            //                actionBlock:^{
            //                [weakSelf presentInviteFlow];
            //                }]];
        }
        
        // update table contents here
        updateViewState()
        tableView.reloadData()
    }
    
    @objc func settingsButtonPressed() {
        let navigationController:OWSNavigationController = AppSettingsViewController.inModalNavigationController()
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func newContactButtonPressed() {
        let newContact = CNMutableContact()
        newContact.phoneNumbers.append(CNLabeledValue(label: "home", value: CNPhoneNumber(stringValue: "123456")))
        let contactVC = CNContactViewController(forNewContact: newContact)
        contactVC.contactStore = CNContactStore()
        contactVC.delegate = self
        contactVC.allowsActions = false
        contactVC.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        
        let navigationController = UINavigationController(rootViewController: contactVC) //For presenting the vc you have to make it navigation controller otherwise it will not work, if you already have navigatiation controllerjust push it you dont have to make it a navigation controller
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func updateShouldObserveDBModifications() {
        let isAppForegroundAndActive:Bool = CurrentAppContext().isAppForegroundAndActive()
        shouldObserveDBModifications = isViewVisible && isAppForegroundAndActive
    }
    
    func setShouldObserveDBModifications(shouldObserveDBModifications: Bool) {
        if ( shouldObserveDBModifications == shouldObserveDBModifications ) {
            return
        }
        
        self.shouldObserveDBModifications = shouldObserveDBModifications
        
        if ( shouldObserveDBModifications ) {
            resetMappings()
        }
    }
    
    func reloadTableViewData() {
        // PERF: come up with a more nuanced cache clearing scheme
        //        callViewModelCache.removeAllObjects()
        tableView.reloadData()
    }
    
    // MARK: Database
    
    func uiDatabaseConnection() -> YapDatabaseConnection {
        if ( self.databaseConnection == nil ) {
            self.databaseConnection = OWSPrimaryStorage.shared().newDatabaseConnection()
            // default is 250
            self.databaseConnection.objectCacheLimit = 500
            self.databaseConnection.beginLongLivedReadTransaction()
        }
        
        return self.databaseConnection
    }
    
    func resetMappings() {
        
    }
    
    @objc func applicationWillEnterForeground(notification: NSNotification) {
        updateViewState()
    }
    
    func hasAnyMessages(withTransaction transaction:YapDatabaseReadTransaction) -> Bool {
        return TSThread.numberOfKeysInCollection(with: transaction) > 0
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        updateShouldObserveDBModifications()
        
        // It's possible a thread was created while we where in the background. But since we don't honor contact
        // requests unless the app is in the foregrond, we must check again here upon becoming active.
        //        var hasAnyMessages:Bool = false
        //        uiDatabaseConnection().read { (transaction) in
        //            hasAnyMessages = self.hasAnyMessages(withTransaction: transaction)
        //        }
        //
        //        if ( hasAnyMessages ) {
        contactsManager.requestSystemContactsOnce { (error) in
            DispatchQueue.main.async {
                self.updateReminderViews()
            }
        }
        //        }
    }
    
    @objc func applicationWillResignActive(notification: NSNotification) {
        self.updateShouldObserveDBModifications()
    }
    
    func tableViewSetUp() {
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    // MARK: Call
    func callTo(recipient: String, withVideo isVideo: Bool) {
        let outboundCallInitiator = AppEnvironment.shared.outboundCallInitiator
        outboundCallInitiator.initiateCall(recipientId: recipient, isVideo: isVideo)
    }
}

extension VNContactsViewController : UITableViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("will begin dragging")
        navigationBar.defineStates()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if !navigationBar.isCollapsed() {
            scrollView.setContentOffset(CGPoint(x: 0.0, y: -navigationBar.scrollToPosition(isSearching: navigationBar.isSearching)), animated: true)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y: CGFloat = scrollView.contentOffset.y
        let newHeaderViewHeight: CGFloat = navigationBar.viewHeightConstraint.constant - y
        
        let minHeaderHeight = navigationBar.isSearching ? headerViewMinHeight + 42.0 : headerViewMinHeight
        
        if newHeaderViewHeight > headerViewMaxHeight {
            navigationBar.update(newHeight: headerViewMaxHeight)
        } else if newHeaderViewHeight < minHeaderHeight {
            navigationBar.update(newHeight: minHeaderHeight)
        } else {
            navigationBar.update(newHeight: newHeaderViewHeight)
            scrollView.contentOffset.y = 0 // block scroll view
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        print("will begin decelerating")
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("will end decelerating")
        navigationBar.defineStates()
    }
}

extension VNContactsViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sectionsCount:Int = VNContactsSection.count - 2 // initial value = - contacts section
        sectionsCount += collatedVinciAccounts.count
        
        return sectionsCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == searchResultsController.tableView {
            return searchResultsController.tableView(tableView, numberOfRowsInSection: section)
        }
        
        switch defineSection(section: section) {
        case .sectionReminder:
            return sectionsMap[.sectionReminder] ?? 0
        case .sectionInviteFriends:
            return sectionsMap[.sectionInviteFriends] ?? 0
        case .sectionVinciContacts:
            // ok, define true section of contacts
            let contactSection = section - VNContactsSection.sectionVinciContacts.rawValue
            let collatedSection = collatedVinciAccounts[contactSection]
            let numberOfAccounts = collatedSection.count
            return numberOfAccounts
        default:
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VNContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            if section > minContactsSection && section < maxContactsSection {
                // ok, define true section of contacts
                let contactSection = section - minContactsSection
                let collatedSection = collatedVinciAccounts[contactSection]
                let numberOfAccounts = collatedSection.count
                
                return numberOfAccounts
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == searchResultsController.tableView {
            return searchResultsController.tableView(tableView, cellForRowAt: indexPath)
        }
        
        switch defineSection(section: indexPath.section) {
        case .sectionReminder:
            return self.reminderViewCell
        case .sectionInviteFriends:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "inviteVinciCell")
            cell.textLabel?.text = "Invite Friends"
            cell.textLabel?.font = VinciStrings.regularFont.withSize(16.0)
            cell.textLabel?.textColor = UIColor.vinciBrandBlue
            cell.imageView?.contentMode = .center
            cell.imageView?.image = UIImage(named: "inviteFriends")?.withAlignmentRectInsets(UIEdgeInsets(top: 0.0, left: 6.0, bottom: 0.0, right: 6.0))
            return cell
        case .sectionVinciContacts:
            let reuseIdentifier = "VinciContactViewCell"
            if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? VinciContactViewCell {
                let vinciAccount: SignalAccount!
                
                // ok, define true section of contacts
                let contactSection = indexPath.section - VNContactsSection.sectionVinciContacts.rawValue
                let collatedSection = collatedVinciAccounts[contactSection]
                vinciAccount = collatedSection[indexPath.row]
                
                cell.configure(recipientId: vinciAccount.recipientId)
                cell.hideChecker(animated: false)
                
                return cell
            }
        default:
            let section = indexPath.section
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VNContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            if section > minContactsSection && section < maxContactsSection {
                // ok, define true section of contacts
                let contactSection = section - minContactsSection
                let newIndexPath = IndexPath(row: indexPath.row, section: contactSection)
                let reuseIdentifier = "VinciContactViewCell"
                if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: newIndexPath) as? VinciContactViewCell {
                    
                    let vinciAccount: SignalAccount!
                    
                    let collatedSection = collatedVinciAccounts[newIndexPath.section]
                    vinciAccount = collatedSection[newIndexPath.row]
                
                    
                    cell.configure(recipientId: vinciAccount.recipientId)
                    cell.hideChecker(animated: false)
                    
                    return cell
                }
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if tableView == searchResultsController.tableView {
            return searchResultsController.tableView(tableView, titleForHeaderInSection: section)
        }
        
        switch defineSection(section: section) {
        case .sectionVinciContacts:
            if modeWithCollation {
                let collatedSection = collatedVinciAccounts[section]
                if collatedSection.count > 0 {
                    return collation.sectionTitles[section]
                }
            }
        default:
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VNContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            if section > minContactsSection && section < maxContactsSection {
                let contactSection = section - VNContactsSection.sectionVinciContacts.rawValue
                if modeWithCollation {
                    let collatedSection = collatedVinciAccounts[contactSection]
                    if collatedSection.count > 0 {
                        return collation.sectionTitles[contactSection]
                    }
                }
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == searchResultsController.tableView {
            return searchResultsController.tableView(tableView, didSelectRowAt: indexPath)
        }
        
        //        let reuseIdentifier = "VinciContactViewCell"
        //        if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? VinciContactViewCell {
        tableView.deselectRow(at: indexPath, animated: true)
        //        }
        
        switch defineSection(section: indexPath.section) {
        case .sectionInviteFriends:
            let inviteFriendsViewController = VinciInviteFriendsViewController()
            inviteFriendsViewController.tabFrame = tabBarController?.tabBar.frame ?? navigationController?.tabBarController?.tabBar.frame ?? CGRect.zero
            navigationController?.pushViewController(inviteFriendsViewController, animated: true)
        default:
            let section = indexPath.section
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VNContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            if section > minContactsSection && section < maxContactsSection {
                // ok, define true section of contacts
                let contactSection = section - minContactsSection
                let newIndexPath = IndexPath(row: indexPath.row, section: contactSection)
                let reuseIdentifier = "VinciContactViewCell"
                if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: newIndexPath) as? VinciContactViewCell {
                    
                    let vinciAccount: SignalAccount!
                    
                    let collatedSection = collatedVinciAccounts[newIndexPath.section]
                    vinciAccount = collatedSection[newIndexPath.row]
                    
                    SignalApp.shared().presentConversation(forRecipientId: vinciAccount.recipientId, action: .compose, animated: true)
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}

// MARK : SearchBar delegate

extension VNContactsViewController : UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        
        navigationBar.searchBar.searchBar.setShowsCancelButton(false, animated: false)
        
        if let searchResultsView = searchResultsController.view {
            searchResultsView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(searchResultsView, belowSubview: tableView)
            
            searchResultsView.topAnchor.constraint(equalTo: navigationBar.view.bottomAnchor).isActive = true
            searchResultsView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            searchResultsView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            searchResultsView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            
            view.layoutIfNeeded()
        }
        
        if let tableView = searchResultsController.tableView {
            tableView.delegate = hideSearchBarWhenScrolling ? self : nil
            tableView.setContentOffset(CGPoint(x: 0.0, y: 0.0), animated: false)
        }
        
        let navBarLargeTitleHeight = navigationBar.largeTitleView.frame.height
        navigationBarTopConstraint.constant = -navigationBar.topTitleView.view.frame.height - navBarLargeTitleHeight
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseInOut, animations: {
            self.navigationBar.topTitleView.view.alpha = 0.0
            self.navigationBar.largeTitleView.alpha = 0.0
            self.tableView.alpha = 0.0
            self.view.layoutIfNeeded()
        }) { (finished) in
            self.navigationBar.searchBar.searchBarIsReady()
        }
        
        return searchBar == self.searchBar
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchResultsController.searchText = searchText
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text?.removeAll()
        searchBar.resignFirstResponder()
        
        searchResultsController.searchText = ""
        
        navigationBarTopConstraint.constant = 0.0
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseInOut, animations: {
            self.navigationBar.topTitleView.view.alpha = 1.0
            self.navigationBar.largeTitleView.alpha = 1.0
            self.tableView.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { (finished) in
            if let searchResultsView = self.searchResultsController.view {
                searchResultsView.removeFromSuperview()
            }
        }
    }
    
    // Data
    // function need refaction
    func callingCodesToCountryCodeMap() -> [String:String] {
        var result = [String:String]()
        let onceToken: String = "callingCodesToCountryCodeMap"
        DispatchQueue.once(token: onceToken) {
            for countryCode in PhoneNumberUtil.countryCodes(forSearchTerm: nil) {
                if let callingCode = PhoneNumberUtil.callingCode(fromCountryCode: countryCode as? String) {
                    result[callingCode] = countryCode as? String
                }
            }
        }
        
        return result
    }
    
    func callingCode(possiblePhoneNumber: String) -> String? {
        for callingCode:String in callingCodesToCountryCodeMap().keys {
            if possiblePhoneNumber.hasPrefix(callingCode) {
                return callingCode
            }
        }
        
        return nil
    }
    
    func parsePossibleSearchPhoneNumbers() -> [String] {
        let searchText = searchBar.text ?? ""
        
        if searchText.count < 8 {
            return []
        }
        
        var parsedPhoneNumbers = [String]()
        for phoneNumber in PhoneNumber.tryParsePhoneNumbersFromsUserSpecifiedText(searchText, clientPhoneNumber: TSAccountManager.localNumber()) {
            guard let phoneNumberString = phoneNumber.toE164() else {
                continue
            }
            
            // Ignore phone numbers with an unrecognized calling code.
            guard let callingCode = callingCode(possiblePhoneNumber: phoneNumberString) else {
                continue
            }
            
            // Ignore phone numbers which are too long.
            let callingCodeIndex = callingCode.index(after: callingCode.endIndex)
            let phoneNumberWithoutCallingCode = phoneNumberString[callingCodeIndex...]
            if phoneNumberWithoutCallingCode.count < 1 || phoneNumberWithoutCallingCode.count > 15 {
                continue
            }
            parsedPhoneNumbers.append(phoneNumberString)
        }
        
        return parsedPhoneNumbers
    }
    
    func updateSearchPhoneNumbers() {
        checkForAccounts(for: parsePossibleSearchPhoneNumbers())
    }
    
    func checkForAccounts(for phoneNumbers:[String]) {
        var unknownPhoneNumbers = [String]()
        for phoneNumber in phoneNumbers {
            if !nonContactAccountSet.contains(phoneNumber) {
                unknownPhoneNumbers.append(phoneNumber)
            }
        }
        
        if unknownPhoneNumbers.count < 1 {
            return
        }
        
        ContactsUpdater.shared().lookupIdentifiers(unknownPhoneNumbers,
                                                   success: { (recipients) in
                                                    self.updateNonContact(accountSet: recipients)
        }) { (error) in
            // Ignore.
        }
    }
    
    func updateNonContact(accountSet recipients:[SignalRecipient]) {
        var didUpdate = false
        for recipient in recipients {
            if self.nonContactAccountSet.contains(recipient.recipientId()) {
                continue
            }
            //            self.nonContactAccountSet.addObject
            didUpdate = true
        }
        if didUpdate {
            updateTableContent()
        }
    }
}

extension VNContactsViewController : ContactsViewHelperDelegate {
    
    func contactsViewHelperDidUpdateContacts() {
        updateTableContent()
        showContactAppropriateViews()
    }
    
    func shouldHideLocalNumber() -> Bool {
        return false
    }
}

extension VNContactsViewController : CNContactViewControllerDelegate {
    // dismiss CNContactViewController when pressed Done or Cancel
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        self.dismiss(animated: true, completion: nil)
    }
}


//// MARK:  UIScrollViewDelegate
//extension VNContactsViewController : UIScrollViewDelegate {
//    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
//        searchBar.resignFirstResponder()
//        //        OWSAssertDebug(!self.searchBar.isFirstResponder);
//    }
//}

// MARK: HomeFeedTableViewCellDelegate
extension VNContactsViewController {
}

// MARK: Grouping
extension VNContactsViewController {
}

// MARK: Database delegates
extension VNContactsViewController {
    
    @objc func yapDatabaseModifiedExternally(notification:NSNotification) {
        //    OWSAssertIsOnMainThread();
        //    OWSLogVerbose(@"");
        
        if ( shouldObserveDBModifications ) {
            // External database modifications can't be converted into incremental updates,
            // so rebuild everything.  This is expensive and usually isn't necessary, but
            // there's no alternative.
            
            // We don't need to do this if we're not observing db modifications since we'll
            // do it when we resume.
            resetMappings()
        }
    }
    
    @objc func yapDatabaseModified(notification:NSNotification) {
        //        OWSAssertIsOnMainThread();
        //
        //        if ( !shouldObserveDBModifications ) {
        //            return
        //        }
        //
        //        let notifications = databaseConnection.beginLongLivedReadTransaction()
        //        let extDBConnection:YapDatabaseViewConnection = databaseConnection.extension(currentDatabaseExtensionName()) as! YapDatabaseViewConnection
        //        let hasChangesForGroup:Bool = extDBConnection.hasChanges(forGroup: currentGrouping(), in: notifications)
        //        if ( !hasChangesForGroup ) {
        //            databaseConnection.read { (transaction) in
        //                self.threadMappings.update(with: transaction)
        //            }
        //            updateViewState()
        //
        //            return
        //        }
        //
        //        // If the user hasn't already granted contact access
        //        // we don't want to request until they receive a message.
        //        //        var hasAnyMessages:Bool = false
        //        //        databaseConnection.read { (transaction) in
        //        //            hasAnyMessages = self.hasAnyMessages(withTransaction: transaction)
        //        //        }
        //        //
        //        //        if ( hasAnyMessages ) {
        //        contactsManager.requestSystemContactsOnce()
        //        //        }
        //
        //        var sectionChanges:NSArray = []
        //        var rowChanges:NSArray = []
        //
        //        extDBConnection.getSectionChanges(&sectionChanges, rowChanges: &rowChanges,
        //                                          for: notifications, with: threadMappings)
        //
        //        // We want this regardless of if we're currently viewing the archive.
        //        // So we run it before the early return
        //        updateViewState()
        //
        //        if ( sectionChanges.count == 0 && rowChanges.count == 0 ) {
        //            return
        //        }
        //
        //        tableView.beginUpdates()
        //
        //        let typedSecChanges:[YapDatabaseViewSectionChange] = sectionChanges as! [YapDatabaseViewSectionChange]
        //        for sectionChange:YapDatabaseViewSectionChange in typedSecChanges {
        //
        //            switch sectionChange.type {
        //            case .delete:
        //                tableView.deleteSections(IndexSet(integer: IndexSet.Element(sectionChange.index)),
        //                                         with: .automatic)
        //            case .insert:
        //                tableView.insertSections(IndexSet(integer: IndexSet.Element(sectionChange.index)),
        //                                         with: .automatic)
        //                break
        //            case .update:
        //                break
        //            case .move:
        //                break
        //            @unknown default:
        //                break
        //            }
        //        }
        //
        //        let typedRowChanges:[YapDatabaseViewRowChange] = rowChanges as! [YapDatabaseViewRowChange]
        //        for rowChange:YapDatabaseViewRowChange in typedRowChanges {
        //            let key:NSString = rowChange.collectionKey.key as NSString
        //            //            OWSAssertDebug(key);
        //            self.callViewModelCache.removeObject(forKey: key)
        //
        //            switch rowChange.type {
        //            case .delete:
        //                let indexPath = IndexPath(row: Int(rowChange.originalIndex), section: Int(rowChange.originalSection))
        //                tableView.deleteRows(at: [rowChange.indexPath ?? indexPath], with: .automatic)
        //                break
        //            case .insert:
        //                let indexPath = IndexPath(row: Int(rowChange.finalIndex), section: Int(rowChange.finalSection))
        //                tableView.insertRows(at: [rowChange.indexPath ?? indexPath], with: .automatic)
        //                break
        //            case .move:
        //                tableView.deleteRows(at: [rowChange.indexPath!], with: .automatic)
        //                tableView.insertRows(at: [rowChange.newIndexPath!], with: .automatic)
        //                break
        //            case .update:
        //                let indexPath = IndexPath(row: Int(rowChange.originalIndex), section: Int(rowChange.originalSection))
        //                tableView.reloadRows(at: [rowChange.indexPath ?? indexPath], with: .automatic)
        //                break
        //            @unknown default:
        //                break
        //            }
        //        }
        //
        //        self.tableView.endUpdates()
    }
    
    func shouldShowFirstConversationCue() -> Bool {
        return false// self.callsViewMode == VNCallsViewMode.callsViewMode_All && numberOfInboxThreads() == 0
    }
    
    // We want to delay asking for a review until an opportune time.
    // If the user has *just* launched Signal they intend to do something, we don't want to interrupt them.
    // If the user hasn't sent a message, we don't want to ask them for a review yet.
    func requestReviewIfAppropriate() {
        if ( self.hasEverAppeared && Environment.shared.preferences.hasSentAMessage() ) {
            //            OWSLogDebug(@"requesting review");
            if #available(iOS 10, *) {
                //                 In Debug this pops up *every* time, which is helpful, but annoying.
                //                 In Production this will pop up at most 3 times per 365 days.
                //#ifndef DEBUG
                //                static dispatch_once_t onceToken;
                //                // Despite `SKStoreReviewController` docs, some people have reported seeing the "request review" prompt
                //                // repeatedly after first installation. Let's make sure it only happens at most once per launch.
                //                dispatch_once(&onceToken, ^{
                //                [SKStoreReviewController requestReview];
                //                });
                //#endif
            }
        } else {
            //            OWSLogDebug(@"not requesting review");
        }
    }
}

// MARK: OWSBlockListCacheDelegate
extension VNContactsViewController : BlockListCacheDelegate {
    func blockListCacheDidUpdate(_ blocklistCache:BlockListCache) {
        //        OWSLogVerbose(@"");
        reloadTableViewData()
    }
}

extension VNContactsViewController : VinciTabEditPanelDelegate {
    
    func readButtonPressed() {
        return
    }
    
    func archiveButtonPressed() {
        return
    }
    
    func deleteButtonPressed() {
        return
    }
}

// MARK: ConversationSearchViewDelegate
extension VNContactsViewController : VinciSearchResultsViewDelegate {
    func conversationSearchViewWillBeginDragging() {
        searchBar.resignFirstResponder()
        // OWSAssertDebug(!self.searchBar.isFirstResponder);
    }
    
    func didSelect(rowWith vinciAccount: SignalAccount) {
        SignalApp.shared().presentConversation(forRecipientId: vinciAccount.recipientId, action: .compose, animated: true)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
