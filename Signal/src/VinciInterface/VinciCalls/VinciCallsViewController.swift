
//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc class VinciCallsViewController: VinciViewController {
    
    let kArchivedConversationsReuseIdentifier = "kArchivedConversationsReuseIdentifier";
    
    @objc enum VinciCallsViewMode:Int {
        case callsViewMode_all
        case callsViewMode_missed
    }
    
    // The bulk of the content in this view is driven by a YapDB view/mapping.
    // However, we also want to optionally include ReminderView's at the top
    // and an "Archived Conversations" button at the bottom. Rather than introduce
    // index-offsets into the Mapping calculation, we introduce two pseudo groups
    // to add a top and bottom section to the content, and create cells for those
    // sections without consulting the YapMapping.
    // This is a bit of a hack, but it consolidates the hacks into the Reminder/Archive section
    // and allows us to leaves the bulk of the content logic on the happy path.
    let kReminderViewPseudoGroup:String = "kReminderViewPseudoGroup"
    let kArchiveButtonPseudoGroup:String = "kArchiveButtonPseudoGroup"
    
    @objc enum CallsViewConrollerSection:Int {
        case CallsViewControllerSectionReminders = 0
        case CallsViewControllerSectionConversations = 1
    }
    
    var tableView:UITableView!
    var emptyInboxView:UIView!
    
    var editModePanel:VinciTabEditPanel!
    
    var firstConversationCueView:UIView!
    var firstConversationLabel:UILabel!
    
    var editingDatabaseConnection:YapDatabaseConnection!
    var databaseConnection:YapDatabaseConnection!
    var threadMappings:YapDatabaseViewMappings!
    
    var callsViewMode:VinciCallsViewMode = .callsViewMode_all
    @objc var previewingContext:Any?
    var threadViewModelCache:NSCache<NSString,ThreadViewModel> = NSCache()
    var shouldObserveDBModifications:Bool = false
    
    // MARK: Title Views
    
    var allCallsTitleSize:CGSize?
    var spacesTitleSize:CGSize?
    var missedCallsTitleSize:CGSize?
    
    var chatsLargeTitleSize:CGSize?
    var spacesLargeTitleSize:CGSize?
    var groupsLargeTitleSize:CGSize?
    
    var selfTitle = ""
    
    // MARK: Search
    
    var searchShadowView:UIView!
    var searchShadowViewConstraints = [NSLayoutConstraint]()
    
    var searchBar:UISearchBar!
    var searchController:UISearchController!
    var searchResultsController:ConversationSearchViewController!
    
    // Dependencies
    
    var accountManager:AccountManager!
    var contactsManager:OWSContactsManager!
    var messageSender:MessageSender!
    var blocklistCache:BlockListCache!
    
    // Views
    
    var reminderStackView:UIStackView!
    var reminderViewCell:UITableViewCell!
    var deregisteredView:UIView!
    var outageView:UIView!
    var missingContactsPermissionView:UIView!
    
    var lastThread:TSThread?
    
    var hasVisibleReminders:Bool = false
    var hasThemeChanged:Bool = false
    
    // VINCI extension
    var chatsEditModeOn:Bool = false
    var selectedThreads:[TSThread] = []
    
    var trashButton: UIBarButtonItem!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.callsViewMode = .callsViewMode_all
        
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
        self.threadViewModelCache = NSCache()
        
//        self.title = "All calls   Missed Calls"
        selfTitle = "All calls   Missed Calls"
        
        // Ensure ExperienceUpgradeFinder has been initialized.
        //#pragma GCC diagnostic push
        //#pragma GCC diagnostic ignored "-Wunused-result"
        let _ = ExperienceUpgradeFinder.shared
        //#pragma GCC diagnostic pop
    }
    
//    override var title: String? {
//        didSet {
//            applyColorStyle(toLabels: findTitleLabels())
//        }
//    }
    
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
        self.reloadTableViewData()
        
        if ( !self.firstConversationCueView.isHidden ) {
            self.updateFirstConversationLabel()
        }
    }
    
    @objc func registrationStateDidChange(notification:Notification) {
        //        OWSAssertIsOnMainThread();
        
        self.updateReminderViews()
    }
    
    @objc func outageStateDidChange(notification:Notification) {
        //        OWSAssertIsOnMainThread();
        
        self.updateReminderViews()
    }
    
    @objc func localProfileDidChange(notification:Notification) {
        //        OWSAssertIsOnMainThread();
        
        self.updateBarButtonItems()
    }
    
    @objc func themeDidChange(notification: NSNotification) {
        //        OWSAssertIsOnMainThread();
        
        self.applyTheme()
        self.tableView.reloadData()
        
        self.hasThemeChanged = true
    }
    
    func applyTheme() {
        //        OWSAssertIsOnMainThread();
        //        OWSAssertDebug(self.tableView);
        //        OWSAssertDebug(self.searchBar);
        
        self.view.backgroundColor = Theme.backgroundColor
        self.tableView.backgroundColor = Theme.backgroundColor
    }
    
    // MARK: View Life Cycle
    override func loadView() {
        super.loadView()
        
        // VINCI do I need this? This VC is not main anymore.
        // TODO: Remove this
//        if ( self.callsViewMode == .callsViewMode_all ) {
//            SignalApp.shared().VinciCallsViewController = self
//        }
        
        reminderStackView = UIStackView()
        reminderStackView.axis = .vertical
        reminderStackView.spacing = 0
        
        reminderViewCell = UITableViewCell()
        reminderViewCell.selectionStyle = .none
        reminderViewCell.contentView.addSubview(reminderStackView)
        reminderStackView.autoPinEdgesToSuperviewEdges()
        //        reminderViewCell.accessibilityIdentifier = String(format: "%@.%@", self, "reminderViewCell")
        //        reminderStackView.accessibilityIdentifier = String(format: "%@.%@", self, "reminderStackView")
        
        deregisteredView = ReminderView.nag(text: NSLocalizedString("DEREGISTRATION_WARNING", comment: "Label warning the user that they have been de-registered."), tapAction: ({
            RegistrationUtils.showReregistrationUI(from: self)
        }))
        reminderStackView.addArrangedSubview(deregisteredView)
        //        deregisteredView.accessibilityIdentifier = String(format: "%@.%@", self, "deregisteredView")
        
        outageView = ReminderView.nag(text: NSLocalizedString("OUTAGE_WARNING", comment: "Label warning the user that the Signal service may be down."), tapAction: nil)
        reminderStackView.addArrangedSubview(outageView)
        //        outageView.accessibilityIdentifier = String(format: "%@.%@", self, "outageView")
        
        missingContactsPermissionView = ReminderView.nag(text: NSLocalizedString("INBOX_VIEW_MISSING_CONTACTS_PERMISSION", comment: "Multi-line label explaining how to show names instead of phone numbers in your inbox"), tapAction: ({
            UIApplication.shared.openSystemSettings()
        }))
        reminderStackView.addArrangedSubview(missingContactsPermissionView)
        //        missingContactsPermissionView.accessibilityIdentifier = String(format: "%@.%@", self, "missingContactsPermissionView")
        
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.separatorColor = Theme.cellSeparatorColor
        tableView.register(VinciChatViewCell.self, forCellReuseIdentifier: VinciChatViewCell.cellReuseIdentifier())
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: kArchivedConversationsReuseIdentifier)
        self.view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
        
        //        tableView.accessibilityIdentifier = String(format: "%@.%@", self, "tableView")
        //        searchBar.accessibilityIdentifier = String(format: "%@.%@", self, "searchBar")
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        
        self.emptyInboxView = self.createEmptyInboxView()
        self.view.addSubview(emptyInboxView)
        emptyInboxView.autoPinWidthToSuperview()
        emptyInboxView.autoVCenterInSuperview()
        //        emptyInboxView.accessibilityIdentifier = String(format: "%@.%@", self, "emptyInboxView")
        
        self.createFirstConversationCueView()
        self.view.addSubview(self.firstConversationCueView)
        self.firstConversationCueView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        // This inset bakes in assumptions about UINavigationBar layout, but I'm not sure
        // there's a better way to do it, since it isn't safe to use iOS auto layout with
        // UINavigationBar contents.
        self.firstConversationCueView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 6.0)
        self.firstConversationCueView.autoPinEdge(toSuperviewEdge: .leading, withInset: 10, relation: .greaterThanOrEqual)
        self.firstConversationCueView.autoPinEdge(toSuperviewMargin: .bottom, relation: .greaterThanOrEqual)
        
        //        firstConversationCueView.accessibilityIdentifier = String(format: "%@.%@", self, "firstConversationCueView")
        //        firstConversationLabel.accessibilityIdentifier = String(format: "%@.%@", self, "firstConversationLabel")
        
        //    UIRefreshControl *pullToRefreshView = [UIRefreshControl new];
        //    pullToRefreshView.tintColor = [UIColor grayColor];
        //    [pullToRefreshView addTarget:self
        //        action:@selector(pullToRefreshPerformed:)
        //        forControlEvents:UIControlEventValueChanged];
        //    [self.tableView insertSubview:pullToRefreshView atIndex:0];
        //    SET_SUBVIEW_ACCESSIBILITY_IDENTIFIER(self, pullToRefreshView);
    }
    
    func createEmptyInboxView() -> UIView {
        let emptyInboxImageNames = ["home_empty_splash_1"
            , "home_empty_splash_2"
            , "home_empty_splash_3"
            , "home_empty_splash_4"
            , "home_empty_splash_5"]
        
        let randomIndex:Int = Int(arc4random_uniform(UInt32(emptyInboxImageNames.count)))
        let emptyInboxImageName = emptyInboxImageNames[randomIndex]
        let emptyInboxImageView = UIImageView()
        emptyInboxImageView.image = UIImage(named: emptyInboxImageName)
        //        emptyInboxImageView.layer.minificationFilter = CALayerContentsFilter.trilinear
        //        emptyInboxImageView.layer.magnificationFilter = CALayerContentsFilter.trilinear
        //        emptyInboxImageView.autoPinToAspectRatio(emptyInboxImageView.image!.size)
        let screenSize = UIScreen.main.bounds.size
        let emptyInboxImageSize = min(screenSize.width, screenSize.height) * 0.65
        emptyInboxImageView.autoSetDimension(.width, toSize: emptyInboxImageSize)
        
        let emptyInboxLabel = UILabel()
        emptyInboxLabel.text = NSLocalizedString("INBOX_VIEW_EMPTY_INBOX",
                                                 comment: "Message shown in the home view when the inbox is empty.")
        emptyInboxLabel.font = UIFont.ows_dynamicTypeBody
        emptyInboxLabel.textColor = Theme.secondaryColor
        emptyInboxLabel.textAlignment = .center
        emptyInboxLabel.numberOfLines = 0
        emptyInboxLabel.lineBreakMode = .byWordWrapping
        
        let emptyInboxStack = UIStackView(arrangedSubviews: [emptyInboxImageView, emptyInboxLabel])
        emptyInboxStack.axis = .vertical
        emptyInboxStack.alignment = .center
        emptyInboxStack.spacing = 12
        emptyInboxStack.layoutMargins = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
        emptyInboxStack.isLayoutMarginsRelativeArrangement = true
        
        return emptyInboxStack
    }
    
    func createFirstConversationCueView() {
        let kTailWidth:CGFloat = 16.0
        let kTailHeight:CGFloat = 8.0
        let kTailHMargin:CGFloat = 12.0
        
        let label:UILabel = UILabel()
        label.textColor = UIColor.ows_white
        label.font = UIFont.ows_dynamicTypeBody
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        
        let layerView:OWSLayerView = OWSLayerView()
        //        layerView.layoutMargins = UIEdgeInsets.init(top: 11 + kTailHeight, left: 16, bottom: 11, right: 16)
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        shapeLayer.fillColor = UIColor.ows_signalBlue.cgColor;
        layerView.layer.addSublayer(shapeLayer)
        layerView.layoutCallback = { _ in
            let bezierPath = UIBezierPath()
            
            // Bubble
            var bubbleBounds:CGRect = self.view.bounds
            bubbleBounds.origin.y += kTailHeight
            bubbleBounds.size.height -= kTailHeight
            bezierPath.append(UIBezierPath(roundedRect: bubbleBounds, cornerRadius: 8))
            
            // Tail
            var tailTop:CGPoint = CGPoint(x: kTailHMargin + kTailWidth * 0.5, y: 0.0)
            var tailLeft:CGPoint = CGPoint(x: kTailHMargin, y: kTailHeight)
            var tailRight:CGPoint = CGPoint(x: kTailHMargin + kTailWidth, y: kTailHeight)
            
            if ( !CurrentAppContext().isRTL ) {
                tailTop.x = self.view.width() - tailTop.x
                tailLeft.x = self.view.width() - tailLeft.x
                tailRight.x = self.view.width() - tailRight.x
            }
            
            bezierPath.move(to: tailTop)
            bezierPath.addLine(to: tailLeft)
            bezierPath.addLine(to: tailRight)
            bezierPath.addLine(to: tailTop)
            
            shapeLayer.path = bezierPath.cgPath
            shapeLayer.frame = self.view.bounds
        }
        
        layerView.addSubview(label)
        label.autoPinEdgesToSuperviewMargins()
        
        layerView.isUserInteractionEnabled = true
        layerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(firstConversationCueWasTapped(gestureRecognizer:))))
        self.firstConversationCueView = layerView
        self.firstConversationLabel = label
    }
    
    @objc func firstConversationCueWasTapped(gestureRecognizer:UITapGestureRecognizer) {
        //    OWSLogInfo(@"");
        self.updateViewState()
    }
    
    func suggestedAccountsForFirstContact() -> [SignalAccount] {
        var accounts:[SignalAccount] = []
        let localNumber = TSAccountManager.localNumber()
        if ( localNumber == nil ) {
            //            OWSFailDebug(@"localNumber was unexepectedly nil");
            return []
        }
        
        for account:SignalAccount in self.contactsManager.signalAccounts {
            if ( localNumber != account.recipientId ) {
                continue
            }
            if ( accounts.count >= 3 ) {
                break
            }
            
            accounts.append(account)
        }
        
        return accounts
        //    return [accounts copy];
    }
    
    func updateFirstConversationLabel() {
        
        let signalAccounts:[SignalAccount] = self.suggestedAccountsForFirstContact()
        var formatString:String = ""
        var contactNames:[String] = []
        
        if ( signalAccounts.count >= 3 ) {
            contactNames.append(self.contactsManager.displayName(for: signalAccounts[0]))
            contactNames.append(self.contactsManager.displayName(for: signalAccounts[1]))
            contactNames.append(self.contactsManager.displayName(for: signalAccounts[2]))
            
            formatString = NSLocalizedString("HOME_VIEW_FIRST_CONVERSATION_OFFER_3_CONTACTS_FORMAT", comment: "Format string for a label offering to start a new conversation with your contacts, if you have at least 3 Signal contacts.  Embeds {{The names of 3 of your Signal contacts}}.")
        } else if ( signalAccounts.count == 2 ) {
            contactNames.append(self.contactsManager.displayName(for: signalAccounts[0]))
            contactNames.append(self.contactsManager.displayName(for: signalAccounts[1]))
            
            formatString = NSLocalizedString("HOME_VIEW_FIRST_CONVERSATION_OFFER_2_CONTACTS_FORMAT", comment: "Format string for a label offering to start a new conversation with your contacts, if you have at least 2 Signal contacts.  Embeds {{The names of 2 of your Signal contacts}}.")
        } else if ( signalAccounts.count == 1 ) {
            contactNames.append(self.contactsManager.displayName(for: signalAccounts[0]))
            
            formatString = NSLocalizedString("HOME_VIEW_FIRST_CONVERSATION_OFFER_1_CONTACTS_FORMAT", comment: "Format string for a label offering to start a new conversation with your contacts, if you have at least 1 Signal contacts.  Embeds {{The names of 1 of your Signal contacts}}.")
        }
        
        let embedToken = "%@"
        let formatSplits = [formatString .components(separatedBy: embedToken)]
        // We need to use a complicated format string that possibly embeds multiple contact names.
        // Translator error could easily lead to an invalid format string.
        // We need to verify that it was translated properly.
        var isValidFormatString:Bool = contactNames.count > 0 && formatSplits.count == contactNames.count + 1
        for contactName:String in contactNames {
            if ( contactName.contains(embedToken) ) {
                isValidFormatString = false
            }
        }
        
        var attributedString:NSMutableAttributedString?
        if ( isValidFormatString ) {
            attributedString = NSMutableAttributedString(string: formatString)
            while contactNames.count > 0 {
                let contactName:String! = contactNames.first
                contactNames.remove(at: 0)
                
                let range:NSRange = (attributedString?.mutableString.range(of: embedToken))!
                if ( range.location == NSNotFound ) {
                    // Error
                    attributedString = nil
                    break
                }
                
                let formattedName:NSAttributedString = NSAttributedString.init(string: contactName
                    , attributes: [:])
                attributedString?.replaceCharacters(in: range, with: formattedName)
            }
        }
        
        if ( attributedString == nil ) {
            // The default case handles the no-contacts scenario and all error cases.
            let defaultText:String = NSLocalizedString("HOME_VIEW_FIRST_CONVERSATION_OFFER_NO_CONTACTS"
                , comment: "A label offering to start a new conversation with your contacts, if you have no Signal contacts.")
            attributedString = NSMutableAttributedString.init(string: defaultText)
        }
        
        self.firstConversationLabel.attributedText = attributedString?.copy() as? NSAttributedString
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
        
        self.hasVisibleReminders = !self.missingContactsPermissionView.isHidden || !self.deregisteredView.isHidden || !self.outageView.isHidden
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
        
        self.editingDatabaseConnection = OWSPrimaryStorage.shared().newDatabaseConnection()
        
        // Create the database connection.
        self.databaseConnection = self.uiDatabaseConnection()
        
        self.updateMappings()
        self.updateViewState()
        self.updateReminderViews()
        self.observeNotifications()
        
        // because this uses the table data source, `tableViewSetup` must happen
        // after mappings have been set up in `showInboxGrouping`
        self.tableViewSetUp()
        
//        switch self.callsViewMode {
//        case .callsViewMode_all:
//            // TODO: Should our app name be translated?  Probably not.
//            selfTitle = "All calls   Missed Calls"
//            break
//        case .callsViewMode_missed:
//            selfTitle = "All calls   Missed Calls"
//            break
//        }
        
        // prefers large titles? not in Archive mode
        if #available(iOS 11.0, *) {
            if ( callsViewMode == .callsViewMode_missed ) {
                navigationController?.navigationBar.prefersLargeTitles = false
                navigationItem.largeTitleDisplayMode = .never
            } else {
                navigationController?.navigationBar.prefersLargeTitles = true
                navigationItem.largeTitleDisplayMode = .always
            }
        }
        
        self.applyDefaultBackButton()
        
        if self.traitCollection.responds(to: #selector(getter: self.traitCollection.forceTouchCapability)) &&
            self.traitCollection.forceTouchCapability == UIForceTouchCapability.available {
            self.registerForPreviewing(with: self, sourceView: self.tableView)
        }
        
        // Search
        //        self.searchBar = UISearchBar()
        //        searchBar.placeholder = NSLocalizedString("HOME_VIEW_CONVERSATION_SEARCHBAR_PLACEHOLDER", comment: "Placeholder text for search bar which filters conversations.")
        ////        searchBar.delegate = self
        //        searchBar.sizeToFit()
        //
        ////        OWSAssertDebug(self.tableView.tableHeaderView == nil)
        //        self.tableView.tableHeaderView = self.searchBar
        //        // Hide search bar by default.  User can pull down to search.
        //        let searchBarHeight = self.searchBar.frame.height
        //        self.tableView.contentOffset = CGPoint(x: 0, y: searchBarHeight)
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .done
        searchController.searchBar.placeholder = "Your Library"
        searchController.searchBar.searchBarStyle = .minimal
        
        self.searchBar = searchController.searchBar
        self.searchBar.delegate = self
        
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = searchController
            self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
            searchController.searchBar.backgroundColor = Theme.backgroundColor
        } else {
            // Fallback on earlier versions
            self.tableView.tableHeaderView = self.searchBar
        }
        
        self.searchResultsController = ConversationSearchViewController()
        searchResultsController.delegate = self
        self.addChildViewController(searchResultsController)
        self.view.addSubview(searchResultsController.view)
        searchResultsController.view.autoPinEdge(toSuperviewEdge: .bottom)
        searchResultsController.view!.autoPinLeadingToSuperviewMargin()
        searchResultsController.view!.autoPinTrailingToSuperviewMargin()
        if #available(iOS 11.0, *) {
            searchResultsController.view.autoPinTopToSuperviewMargin()
        } else {
            // VINCI need to check (inset 40)
            searchResultsController.view.autoPin(toTopLayoutGuideOf: self, withInset: 40)
        }
        searchResultsController.view.isHidden = true
        
        searchShadowView = UIView()
        searchShadowView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        // VINCI edit panel
        editModePanel = VinciTabEditPanel()
        editModePanel.backgroundColor = Theme.navbarBackgroundColor
        editModePanel.alpha = 0.0
        editModePanel.isUserInteractionEnabled = false
        view.addSubview(editModePanel)
        //        editModePanel.frame = navigationController?.tabBarController?.tabBar.frame ?? CGRect.zero
        editModePanel.frame = tabBarController?.tabBar.frame ?? CGRect.zero
        
        self.updateReminderViews()
        self.updateBarButtonItems()
        
        self.applyTheme()
    }
    
    func applyDefaultBackButton() {
        // We don't show any text for the back button, so there's no need to localize it. But because we left align the
        // conversation title view, we add a little tappable padding after the back button, by having a title of spaces.
        // Admittedly this is kind of a hack and not super fine grained, but it's simple and results in the interactive pop
        // gesture animating our title view nicely vs. creating our own back button bar item with custom padding, which does
        // not properly animate with the "swipe to go back" or "swipe left for info" gestures.
        let paddingLength = 3
        let paddingString = "".padding(toLength: paddingLength, withPad: " ", startingAt: 0)
        self.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: paddingString, style: .plain, target: nil, action: nil)
    }
    
    func applyArchiveBackButton() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: NSLocalizedString("BACK_BUTTON", comment: "button text for back button"), style: .plain, target: nil, action: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
        if #available(iOS 11.0, *) {
            self.navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            // Fallback on earlier versions
        }
        
        self.displayAnyUnseenUpgradeExperience()
        self.applyDefaultBackButton()
        
        if ( self.hasThemeChanged ) {
            self.tableView.reloadData()
            self.hasThemeChanged = false
        }
        
        self.requestReviewIfAppropriate()
        self.searchResultsController.viewDidAppear(animated)
        
        navigationItem.title = selfTitle
    }
    
    func updateBarButtonItems() {
        
        // Settings button.
        var settingsButton:UIBarButtonItem?
        
        // VINCI settings button with icon
        let image = UIImage(named: "vinciSettingsIcon")
        settingsButton = UIBarButtonItem.init(image: image, style: .plain, target: self, action: #selector(settingsButtonPressed))
        settingsButton?.tintColor = UIColor.vinciBrandBlue
        
        //        let systemVersionGreaterThan11:Bool = ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 11, minorVersion: 0, patchVersion: 0))
        //
        //        if ( systemVersionGreaterThan11 ) {
        //            let kAvatarSize = 28
        //            let localProfileAvatarImage:UIImage? = OWSProfileManager.shared().localProfileAvatarImage()
        //            var avatarImage = localProfileAvatarImage
        //            if ( avatarImage == nil) {
        //                let avatarBuilder = OWSContactAvatarBuilder.init(forLocalUserWithDiameter: UInt(kAvatarSize))
        //                avatarImage = avatarBuilder.buildDefaultImage()
        //            }
        //
        //            let avatarButton = AvatarImageButton.init(type: .custom)
        //            avatarButton.addTarget(self, action: #selector(settingsButtonPressed), for: .touchUpInside)
        //            avatarButton.setImage(avatarImage, for: .normal)
        //            avatarButton.autoSetDimensions(to: CGSize(width: kAvatarSize, height: kAvatarSize))
        //
        //            settingsButton = UIBarButtonItem.init(customView: avatarButton)
        //        } else {
        //            // iOS 9 and 10 have a bug around layout of custom views in UIBarButtonItem,
        //            // so we just use a simple icon.
        //            let image = UIImage(named: "button_settings_white")
        //            settingsButton = UIBarButtonItem.init(image: image, style: .plain, target: self, action: #selector(settingsButtonPressed))
        //        }
        
        settingsButton?.accessibilityLabel = CommonStrings.openSettingsButton
        self.navigationItem.leftBarButtonItem = settingsButton
        //        SET_SUBVIEW_ACCESSIBILITY_IDENTIFIER(self, settingsButton);
        
        var rightBarButtons:[UIBarButtonItem] = []
        
        if trashButton == nil {
            trashButton = UIBarButtonItem.init(barButtonSystemItem: .trash, target: self, action: #selector(trashButtonPressed))
        }
        
        let newChatButton = UIBarButtonItem.init(barButtonSystemItem: .compose, target: self, action: #selector(showNewConversationView))
        
        trashButton.tintColor = UIColor.vinciBrandBlue
        newChatButton.tintColor = UIColor.vinciBrandBlue
        
        rightBarButtons.append(newChatButton)
        rightBarButtons.append(trashButton)
        
        //        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .compose, target: self, action: #selector(showNewConversationView))
        self.navigationItem.rightBarButtonItems = rightBarButtons
    }
    
    @objc func allCallsTitleTapped() {
        //        self.titleLabel?.textColor = Theme.primaryColor
        //        self.secTitleLabel?.textColor = UIColor.lightGray
        
//        if self.callsViewMode == .callsViewMode_missed {
//
//            self.navigationController?.popViewController(animated: false)
//        } else {
//            self.callsViewMode = .callsViewMode_all
//            self.updateMappings()
//        }
        
        callsViewMode = .callsViewMode_all
    }
    
    @objc func missedCallsTitleTapped() {
        //        self.titleLabel?.textColor = UIColor.lightGray
        //        self.secTitleLabel?.textColor = Theme.primaryColor
        
//        self.callsViewMode = .callsViewMode_missed
//        self.updateMappings()
        
        // Push a separate instance of this view using "archive" mode.
//        let callsView:VinciCallsViewController = VinciCallsViewController.init()
//        callsView.callsViewMode = .callsViewMode_missed
        
        callsViewMode = .callsViewMode_missed
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
            navigationController?.navigationBar.prefersLargeTitles = false
        } else {
            // Fallback on earlier versions
        }
        
//        self.navigationController?.pushViewController(callsView, animated: false)
    }
    
    @objc func settingsButtonPressed() {
        let navigationController:OWSNavigationController = AppSettingsViewController.inModalNavigationController()
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func trashButtonPressed() {
        self.chatsEditModeOn = !self.chatsEditModeOn
        self.tableView.allowsMultipleSelection = self.chatsEditModeOn
        tableView.reloadData()
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
            self.editModePanel.alpha = self.chatsEditModeOn ? 1.0 : 0.0
            //            self.navigationController?.tabBarController?.tabBar.alpha = !self.chatsEditModeOn ? 1.0 : 0.0
            self.tabBarController?.tabBar.alpha = !self.chatsEditModeOn ? 1.0 : 0.0
        }) { (finished) in
            self.editModePanel.isUserInteractionEnabled = self.chatsEditModeOn
            //            self.navigationController?.tabBarController?.tabBar.isUserInteractionEnabled = !self.chatsEditModeOn
            self.tabBarController?.tabBar.isUserInteractionEnabled = !self.chatsEditModeOn
            return
        }
    }
    
    @objc func showNewConversationView() {
        //        OWSAssertIsOnMainThread();
        //        OWSLogInfo(@"");
        
        let viewController:VinciNewChatViewController = VinciNewChatViewController()
        //        let viewController = UIViewController()
        //        viewController.view.backgroundColor = Theme.backgroundColor
        //        viewController.title = "New message"
        
        //        if #available(iOS 11.0, *) {
        //            viewController.navigationController?.navigationBar.prefersLargeTitles = false
        //            viewController.navigationItem.largeTitleDisplayMode = .never
        //        } else {
        //            // Fallback on earlier versions
        //        }
        
        self.contactsManager.requestSystemContactsOnce { (error:Error?) in
            if (( error ) != nil) {
                OWSLogger.error( String(format: "Error when requesting contacts: %@", error! as CVarArg) )
            }
            
            // Even if there is an error fetching contacts we proceed to the next screen.
            // As the compose view will present the proper thing depending on contact access.
            //
            // We just want to make sure contact access is *complete* before showing the compose
            // screen to avoid flicker.
            //            let modal:OWSNavigationController = OWSNavigationController.init(rootViewController: viewController)
            //            self.navigationController?.present(modal, animated: true, completion: nil)
            self.navigationController?.pushViewController(viewController, animated: true)
            if self.navigationController?.presentedViewController != nil {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        var hasAnyMessages:Bool = false
        self.uiDatabaseConnection().read { (transaction) in
            hasAnyMessages = self.hasAnyMessages(withTransaction: transaction)
        }
        
        if ( hasAnyMessages ) {
            self.contactsManager.requestSystemContactsOnce { (error) in
                DispatchQueue.main.async {
                    self.updateReminderViews()
                }
            }
        }
        
        let isShowingSearchResults:Bool = !self.searchResultsController.view.isHidden
        if ( isShowingSearchResults ) {
            // OWSAssertDebug(self.searchBar.text.ows_stripped.length > 0);
            self.scrollSearchBarToTopAnimated(animated: false)
        } else if ( self.lastThread != nil ) {
            // OWSAssertDebug(self.searchBar.text.ows_stripped.length == 0);
            
            // When returning to home view, try to ensure that the "last" thread is still
            // visible.  The threads often change ordering while in conversation view due
            // to incoming & outgoing messages.
            var indexPathOfLastThread:IndexPath?
            self.uiDatabaseConnection().read { (transaction) in
                let extTransaction:YapDatabaseViewTransaction = transaction.extension(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewTransaction
                indexPathOfLastThread = extTransaction.indexPath(forKey: self.lastThread!.uniqueId!,
                                                                 inCollection: TSThread.collection(),
                                                                 with: self.threadMappings)
            }
            
            if ( indexPathOfLastThread != nil ) {
                self.tableView.scrollToRow(at: indexPathOfLastThread!, at: .none, animated: false)
            }
            
            self.updateViewState()
            self.applyDefaultBackButton()
            
            self.searchResultsController.viewWillAppear(animated)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.searchResultsController.viewWillDisappear(animated)
    }
    
    // I'm not sure I need this now
    //    - (void)setIsViewVisible:(BOOL)isViewVisible
    //{
    //    _isViewVisible = isViewVisible;
    //
    //    [self updateShouldObserveDBModifications];
    //    }
    
    func updateShouldObserveDBModifications() {
        let isAppForegroundAndActive:Bool = CurrentAppContext().isAppForegroundAndActive()
        self.shouldObserveDBModifications = self.isViewVisible && isAppForegroundAndActive
    }
    
    func setShouldObserveDBModifications(shouldObserveDBModifications: Bool) {
        if ( self.shouldObserveDBModifications == shouldObserveDBModifications ) {
            return
        }
        
        self.shouldObserveDBModifications = shouldObserveDBModifications
        
        if ( self.shouldObserveDBModifications ) {
            self.resetMappings()
        }
    }
    
    func reloadTableViewData() {
        // PERF: come up with a more nuanced cache clearing scheme
        self.threadViewModelCache.removeAllObjects()
        self.tableView.reloadData()
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
        // If we're entering "active" mode (e.g. view is visible and app is in foreground),
        // reset all state updated by yapDatabaseModified:.
        if ( self.threadMappings != nil ) {
            // Before we begin observing database modifications, make sure
            // our mapping and table state is up-to-date.
            //
            // We need to `beginLongLivedReadTransaction` before we update our
            // mapping in order to jump to the most recent commit.
            self.uiDatabaseConnection().beginLongLivedReadTransaction()
            self.uiDatabaseConnection().read { (transaction) in
                self.threadMappings.update(with: transaction)
            }
            
            self.reloadTableViewData()
            
            self.updateViewState()
            
            // If the user hasn't already granted contact access
            // we don't want to request until they receive a message.
            var hasAnyMessages:Bool = false
            self.uiDatabaseConnection().read { (transaction) in
                hasAnyMessages = self.hasAnyMessages(withTransaction: transaction)
            }
            if ( hasAnyMessages ) {
                self.contactsManager.requestSystemContactsOnce()
            }
        }
    }
    
    @objc func applicationWillEnterForeground(notification: NSNotification) {
        self.updateViewState()
    }
    
    func hasAnyMessages(withTransaction transaction:YapDatabaseReadTransaction) -> Bool {
        return TSThread.numberOfKeysInCollection(with: transaction) > 0
    }
    
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        self.updateShouldObserveDBModifications()
        
        // It's possible a thread was created while we where in the background. But since we don't honor contact
        // requests unless the app is in the foregrond, we must check again here upon becoming active.
        var hasAnyMessages:Bool = false
        self.uiDatabaseConnection().read { (transaction) in
            hasAnyMessages = self.hasAnyMessages(withTransaction: transaction)
        }
        
        if ( hasAnyMessages ) {
            self.contactsManager.requestSystemContactsOnce { (error) in
                DispatchQueue.main.async {
                    self.updateReminderViews()
                }
            }
        }
    }
    
    @objc func applicationWillResignActive(notification: NSNotification) {
        self.updateShouldObserveDBModifications()
    }
    
    // MARK - startup
    func unseenUpgradeExperiences() -> [ExperienceUpgrade] {
        //        OWSAssertIsOnMainThread();
        
        var unseenUpgrades:[ExperienceUpgrade] = []
        self.uiDatabaseConnection().read { (transaction) in
            unseenUpgrades = ExperienceUpgradeFinder.shared.allUnseen(transaction: transaction)
        }
        
        return unseenUpgrades
    }
    
    func displayAnyUnseenUpgradeExperience() {
        //        OWSAssertIsOnMainThread();
        
        let unseenUpgrades = self.unseenUpgradeExperiences()
        
        if ( unseenUpgrades.count > 0 ) {
            let experienceUpgradeViewController:ExperienceUpgradesPageViewController =
                ExperienceUpgradesPageViewController.init(experienceUpgrades: unseenUpgrades)
            self.present(experienceUpgradeViewController, animated: true, completion: nil)
        } else {
            OWSAlerts.showIOSUpgradeNagIfNecessary()
        }
    }
    
    func tableViewSetUp() {
        self.tableView.tableFooterView = UIView.init(frame: CGRect.zero)
    }
}

// MARK: Table View Data Source
extension VinciCallsViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let result = Int(self.threadMappings.numberOfSections())
        return result
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let aSection:CallsViewConrollerSection = CallsViewConrollerSection(rawValue: section)!
        switch aSection {
        case CallsViewConrollerSection.CallsViewControllerSectionReminders:
            return self.hasVisibleReminders ? 1 : 0
        case CallsViewConrollerSection.CallsViewControllerSectionConversations:
            let result:Int = Int(self.threadMappings.numberOfItems(inSection: UInt(section)))
            trashButton?.isEnabled = result == 0 ? false : true
            if #available(iOS 11.0, *) {
//                self.navigationItem.searchController = result == 0 ? nil : self.searchController
            } else {
                // Fallback on earlier versions
                self.tableView.tableHeaderView = result == 0 ? nil : self.searchBar
            }
            return result
        }
        
        // OWSFailDebug(@"failure: unexpected section: %lu", (unsigned long)section);
    }
    
    func threadViewModelForIndexPath(indexPath: IndexPath) -> ThreadViewModel {
        // VINCI edited
        let threadRecord:TSThread! = self.threadForIndexPath(indexPath: indexPath)
        //        OWSAssertDebug(threadRecord);
        
        let cachedThreadViewModel:ThreadViewModel? = self.threadViewModelCache.object(forKey: threadRecord.uniqueId! as NSString)
        
        if ( cachedThreadViewModel != nil ) {
            return cachedThreadViewModel!
        }
        
        var newThreadViewModel:ThreadViewModel?
        self.databaseConnection.read { (transaction) in
            newThreadViewModel = ThreadViewModel.init(thread: threadRecord, transaction: transaction)
        }
        self.threadViewModelCache.setObject(newThreadViewModel!, forKey: threadRecord.uniqueId! as NSString)
        
        return newThreadViewModel!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section:CallsViewConrollerSection = CallsViewConrollerSection(rawValue: indexPath.section)!
        switch section {
        case .CallsViewControllerSectionReminders:
            //        OWSAssert(self.reminderStackView);
            
            return self.reminderViewCell
        case .CallsViewControllerSectionConversations:
            return self.tableView(tableView, cellForConversationAtIndexPath: indexPath)
        }
        
        //        OWSFailDebug(@"failure: unexpected section: %lu", (unsigned long)section)
    }
    
    func tableView(_ tableView: UITableView, cellForConversationAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell:VinciChatViewCell = self.tableView.dequeueReusableCell(withIdentifier: VinciChatViewCell.cellReuseIdentifier()) as! VinciChatViewCell
        
        // VINCI edit mode on?
        if cell.isCheckable != self.chatsEditModeOn {
            cell.isCheckable = self.chatsEditModeOn
        }
        cell.checker.setState(checked: false, animated: false)
        //        OWSAssertDebug(cell);
        
        let thread:ThreadViewModel = self.threadViewModelForIndexPath(indexPath: indexPath)
        
        let isBlocked:Bool = self.blocklistCache.isBlocked(thread: thread.threadRecord)
        cell.configure(withThread: thread, isBlocked: isBlocked)
        
        // TODO: is it accessible via Appium.
        //        let cellName:NSString = NSString.init(format: "conversation-%@", NSUUID.UUID().uuidString)
        //        cell.accessibilityIdentifier = ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, cellName);
        
        return cell
    }
    
    func threadForIndexPath(indexPath: IndexPath) -> TSThread? {
        var thread:TSThread?
        self.uiDatabaseConnection().read { (transaction) in
            let extTransaction:YapDatabaseViewTransaction = transaction.extension(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewTransaction
            thread = extTransaction.object(at: indexPath, with: self.threadMappings) as? TSThread
        }
        
        if ( !(thread?.isKind(of: TSThread.self))! ) {
            // OWSLogError(@"Invalid object in thread view: %@", [thread class]);
            OWSStorage.incrementVersion(ofDatabaseExtension: TSThreadDatabaseViewExtensionName)
        }
        
        return thread
    }
    
    //    - (void)pullToRefreshPerformed:(UIRefreshControl *)refreshControl
    //{
    //    OWSAssertIsOnMainThread();
    //    OWSLogInfo(@"beggining refreshing.");
    //    [[AppEnvironment.shared.messageFetcherJob run].ensure(^{
    //        OWSLogInfo(@"ending refreshing.");
    //        [refreshControl endRefreshing];
    //        }) retainUntilComplete];
    //}
    //
}

// MARK: Table View Delegate
extension VinciCallsViewController : UITableViewDelegate {
    // MARK: Edit Actions
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        return
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let section:CallsViewConrollerSection = VinciCallsViewController.CallsViewConrollerSection(rawValue: indexPath.section)!
        switch section {
        case .CallsViewControllerSectionReminders:
            return UISwipeActionsConfiguration(actions: [])
        case .CallsViewControllerSectionConversations:
            
            let thread:ThreadViewModel = self.threadViewModelForIndexPath(indexPath: indexPath)
            
            let readAction = UIContextualAction(style: .destructive, title: "") { (action, view, (Bool) -> Void) in
                self.editingDatabaseConnection.readWrite { (transaction) in
                    if ( thread.hasUnreadMessages ) {
                        thread.threadRecord.markAllAsRead(with: transaction)
                    } else {
                        return
                    }
                }
            }
            
            if ( thread.hasUnreadMessages ) {
                readAction.image = UIImage(named: "editReadIcon")
            } else {
                readAction.image = UIImage(named: "editUnreadIcon")
            }
            
            readAction.backgroundColor = UIColor(rgbHex: 0x167EFB)
            
            let pinAction = UIContextualAction(style: .normal, title: "") { (action, view, (Bool) -> Void) in
                self.editingDatabaseConnection.readWrite { (transaction) in
                    if ( thread.threadRecord.isPinned ) {
                        thread.threadRecord.unpinThread(with: transaction)
                    } else {
                        thread.threadRecord.pinThread(with: transaction)
                    }
                }
            }
            
            if ( thread.threadRecord.isPinned ) {
                pinAction.image = UIImage(named: "editUnpinIcon")
            } else {
                pinAction.image = UIImage(named: "editPinIcon")
            }
            
            pinAction.backgroundColor = UIColor(rgbHex: 0x53D769)
            
            // The first action will be auto-performed for "very long swipes".
            return UISwipeActionsConfiguration(actions: [readAction, pinAction])
        }
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let section:CallsViewConrollerSection = VinciCallsViewController.CallsViewConrollerSection(rawValue: indexPath.section)!
        switch section {
        case .CallsViewControllerSectionReminders:
            return UISwipeActionsConfiguration(actions: [])
        case .CallsViewControllerSectionConversations:
            
            let thread:ThreadViewModel = self.threadViewModelForIndexPath(indexPath: indexPath)
            
            let muteAction = UIContextualAction(style: .normal, title: "") { (action, view, (Bool) -> Void) in
                //                [self.editingDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                //                    [self.thread updateWithMutedUntilDate:value transaction:transaction];
                //                    }];
                
                return
            }
            
            if ( thread.isMuted ) {
                muteAction.image = UIImage(named: "editUnmuteIcon")
            } else {
                muteAction.image = UIImage(named: "editMuteIcon")
            }
            
            muteAction.backgroundColor = UIColor(rgbHex: 0xFD9426)
            
            let deleteAction = UIContextualAction(style: .destructive, title: "") { (action, view, (Bool) -> Void) in
                self.tableViewCellTappedDelete(indexPath)
            }
            deleteAction.image = UIImage(named: "editTrashIcon")
            deleteAction.backgroundColor = UIColor(rgbHex: 0xFC3D39)
            
            // The first action will be auto-performed for "very long swipes".
            return UISwipeActionsConfiguration(actions: [deleteAction, muteAction])
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section:CallsViewConrollerSection = VinciCallsViewController.CallsViewConrollerSection(rawValue: indexPath.section)!
        switch section {
        case .CallsViewControllerSectionReminders:
            return false
        case .CallsViewControllerSectionConversations:
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        OWSLogInfo(@"%ld %ld", (long)indexPath.row, (long)indexPath.section);
        
        self.searchBar.resignFirstResponder()
        let section:CallsViewConrollerSection = VinciCallsViewController.CallsViewConrollerSection(rawValue: indexPath.section)!
        switch section {
        case .CallsViewControllerSectionReminders:
            break
        case .CallsViewControllerSectionConversations:
            if self.chatsEditModeOn {
                let cell = tableView.cellForRow(at: indexPath) as! VinciChatViewCell
                let thread:ThreadViewModel = self.threadViewModelForIndexPath(indexPath: indexPath)
                
                if cell.checker.isChecked {
                    // it will be unchecked below, so remove thread from selected
                    if let index = selectedThreads.firstIndex(of: thread.threadRecord) {
                        selectedThreads.remove(at: index)
                    }
                } else {
                    selectedThreads.append(thread.threadRecord)
                }
                
                cell.checker.setState(checked: !cell.checker.isChecked, animated: true)
                
            } else {
                let thread:TSThread? = self.threadForIndexPath(indexPath: indexPath)
                self.presentChat(thread: thread, action: .none, animated: true)
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            break
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        //        OWSLogInfo(@"%ld %ld", (long)indexPath.row, (long)indexPath.section);
        
        self.searchBar.resignFirstResponder()
        let section:CallsViewConrollerSection = VinciCallsViewController.CallsViewConrollerSection(rawValue: indexPath.section)!
        switch section {
        case .CallsViewControllerSectionReminders:
            break
        case .CallsViewControllerSectionConversations:
            if self.chatsEditModeOn {
                let cell = tableView.cellForRow(at: indexPath) as! VinciChatViewCell
                cell.checker.setState(checked: !cell.checker.isChecked, animated: true)
            }
            break
        }
    }
}

// MARK: UISearchBarDelegate
extension VinciCallsViewController : UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        
        searchShadowView.isHidden = true
        view.addSubview(searchShadowView)
        
        searchShadowViewConstraints.append( searchShadowView.autoPinEdge(toSuperviewEdge: .bottom) )
        searchShadowViewConstraints.append( searchShadowView.autoPinLeadingToSuperviewMargin() )
        searchShadowViewConstraints.append( searchShadowView.autoPinTrailingToSuperviewMargin())
        
        if #available(iOS 11.0, *) {
            searchShadowViewConstraints.append( searchShadowView.autoPin(toTopLayoutGuideOf: self, withInset: 0) )
        } else {
            // VINCI need to check (inset 40)
            searchShadowViewConstraints.append( searchShadowView.autoPin(toTopLayoutGuideOf: self, withInset: 40) )
        }
        
        searchShadowView.isHidden = false
        return searchBar == self.searchBar
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchShadowView.isHidden = true
        
        NSLayoutConstraint.deactivate(searchShadowViewConstraints)
        searchShadowViewConstraints.removeAll()
        
        searchShadowView.removeFromSuperview()
        
        return searchBar == self.searchBar
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.scrollSearchBarToTopAnimated(animated: false)
        
        self.updateSearchResultsVisibility()
        
        self.ensureSearchBarCancelButton()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.updateSearchResultsVisibility()
        
        self.ensureSearchBarCancelButton()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.updateSearchResultsVisibility()
        
        self.ensureSearchBarCancelButton()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.updateSearchResultsVisibility()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.text = nil;
        
        self.searchBar.resignFirstResponder()
        //        OWSAssertDebug(!self.searchBar.isFirstResponder);
        
        self.updateSearchResultsVisibility()
        
        self.ensureSearchBarCancelButton()
    }
    
    func ensureSearchBarCancelButton() {
        self.searchBar.showsCancelButton = ( self.searchBar.isFirstResponder || self.searchBar.text!.count > 0 )
    }
    
    func updateSearchResultsVisibility() {
        //  OWSAssertIsOnMainThread();
        
        let searchTextString:NSString = self.searchBar!.text! as NSString
        let searchText:String = searchTextString.ows_stripped()
        
        self.searchResultsController.searchText = searchText
        let isSearching = searchText.count > 0
        self.searchResultsController.view.isHidden = !isSearching
        
        if ( isSearching ) {
            self.scrollSearchBarToTopAnimated(animated: false)
            self.tableView.isScrollEnabled = false
        } else {
            self.tableView.isScrollEnabled = true
        }
    }
    
    func scrollSearchBarToTopAnimated(animated:Bool) {
        let topInset = self.topLayoutGuide.length
        self.tableView.setContentOffset(CGPoint.init(x: 0, y: -topInset), animated: animated)
    }
}

// MARK:  UIScrollViewDelegate
extension VinciCallsViewController : UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
        //        OWSAssertDebug(!self.searchBar.isFirstResponder);
    }
}

// MARK: ConversationSearchViewDelegate
extension VinciCallsViewController : ConversationSearchViewDelegate {
    func conversationSearchViewWillBeginDragging() {
        self.searchBar.resignFirstResponder()
        //        OWSAssertDebug(!self.searchBar.isFirstResponder);
    }
}

// MARK: HomeFeedTableViewCellDelegate
extension VinciCallsViewController {
    func tableViewCellTappedDelete(indexPath:IndexPath) {
        if ( indexPath.section != CallsViewConrollerSection.CallsViewControllerSectionConversations.rawValue ) {
            //            OWSFailDebug(@"failure: unexpected section: %lu", (unsigned long)indexPath.section);
            return
        }
        
        let thread:TSThread = self.threadForIndexPath(indexPath: indexPath)!
        
        let alert:UIAlertController = UIAlertController.init(title: NSLocalizedString("CONVERSATION_DELETE_CONFIRMATION_ALERT_TITLE"
            , comment: "Title for the 'conversation delete confirmation' alert.")
            , message: NSLocalizedString("CONVERSATION_DELETE_CONFIRMATION_ALERT_MESSAGE"
                , comment: "Message for the 'conversation delete confirmation' alert."), preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: NSLocalizedString("TXT_DELETE_TITLE", comment: "")
            , style: .destructive, handler: { (action) in
                self.deleteThread(thread: thread)
        }))
        alert.addAction(OWSAlerts.cancelAction)
        
        //        self.presentAlert(alert)
    }
    
    func deleteThread(thread:TSThread) {
        self.editingDatabaseConnection.readWrite { (transaction) in
            if ( thread.isKind(of: TSGroupThread.self) ) {
                let groupThread:TSGroupThread = thread as! TSGroupThread
                if ( groupThread.isLocalUserInGroup() ) {
                    groupThread.softDelete(with: transaction)
                    return
                }
            }
            
            thread.remove(with: transaction)
        }
        
        self.updateViewState()
    }
    
    @objc public func presentChat(thread:TSThread?, action:ConversationViewAction, animated isAnimated:Bool) {
        self.presentChat(thread: thread, action: action, focusMessageId: nil, animated: isAnimated)
    }
    
    @objc public func presentChat(thread:TSThread?, action:ConversationViewAction, focusMessageId:String?, animated isAnimated:Bool) {
        if ( thread == nil ) {
            //            OWSFailDebug(@"Thread unexpectedly nil");
            return
        }
        
        DispatchQueue.main.async {
            let conversationViewController:ConversationViewController = ConversationViewController()
            conversationViewController.configure(for: thread!, action: action, focusMessageId: focusMessageId)
            
            conversationViewController.title = thread?.name() ?? ""
            
            //            let conversationViewController = UIViewController()
            //            conversationViewController.title = "Chat #1"
            //            conversationViewController.view.backgroundColor = Theme.backgroundColor
            
            if #available(iOS 11.0, *) {
                conversationViewController.navigationController?.navigationBar.prefersLargeTitles = false
                conversationViewController.navigationItem.largeTitleDisplayMode = .never
            } else {
                // Fallback on earlier versions
            }
            
            self.lastThread = thread
            
            if ( self.callsViewMode == VinciCallsViewMode.callsViewMode_missed ) {
                self.navigationController?.pushViewController(conversationViewController, animated: isAnimated)
            } else {
                //                self.secTitleLabel?.alpha = 0.0
                //                self.smallTitle = nil
                //                self.largeTitle = nil
                
                //                self.navigationController?.setViewControllers([self, conversationViewController], animated: isAnimated)
                self.navigationController?.pushViewController(conversationViewController, animated: isAnimated)
                if self.navigationController?.presentedViewController != nil {
                    //                    self.navigationController?.dismiss(animated: true, completion: nil)
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

// MARK: Grouping
extension VinciCallsViewController {
    
    //- (YapDatabaseViewMappings *)threadMappings
    //{
    //    OWSAssertDebug(_threadMappings != nil);
    //    return _threadMappings;
    //    }
    
    func showInboxGrouping() {
        //        OWSAssertDebug(self.homeViewMode == HomeViewMode_Archive);
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func showArchivedConversations() {
        //        OWSAssertDebug(self.homeViewMode == HomeViewMode_Inbox);
        
        // When showing archived conversations, we want to use a conventional "back" button
        // to return to the "inbox" home view.
        self.applyArchiveBackButton()
        //        self.secTitleLabel?.alpha = 0.0
        
        // Push a separate instance of this view using "archive" mode.
        let chatsView:VinciCallsViewController = VinciCallsViewController.init()
        chatsView.callsViewMode = .callsViewMode_missed
        
        self.navigationController?.pushViewController(chatsView, animated: true)
    }
    
    func currentGrouping() -> String {
        switch self.callsViewMode {
        case .callsViewMode_all:
            return TSAllCallsGroup
        case .callsViewMode_missed:
            return TSMissedCallsGroup
        }
    }
    
    func updateMappings() {
        //        OWSAssertIsOnMainThread();
        
        self.threadMappings = YapDatabaseViewMappings.init(groups: [kReminderViewPseudoGroup, self.currentGrouping()], view: TSThreadDatabaseViewExtensionName)
        
        self.threadMappings.setIsReversed(true, forGroup: self.currentGrouping())
        
        self.resetMappings()
        
        self.reloadTableViewData()
        self.updateViewState()
        self.updateReminderViews()
    }
}

// MARK: Database delegates
extension VinciCallsViewController {
    @objc func yapDatabaseModifiedExternally(notification:NSNotification) {
        //    OWSAssertIsOnMainThread();
        //    OWSLogVerbose(@"");
        
        if ( self.shouldObserveDBModifications ) {
            // External database modifications can't be converted into incremental updates,
            // so rebuild everything.  This is expensive and usually isn't necessary, but
            // there's no alternative.
            
            // We don't need to do this if we're not observing db modifications since we'll
            // do it when we resume.
            self.resetMappings()
        }
    }
    
    @objc func yapDatabaseModified(notification:NSNotification) {
        //        OWSAssertIsOnMainThread();
        
        if ( !self.shouldObserveDBModifications ) {
            return
        }
        
        let notifications = self.databaseConnection.beginLongLivedReadTransaction()
        let extDBConnection:YapDatabaseViewConnection = self.databaseConnection.extension(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewConnection
        let hasChangesForGroup:Bool = extDBConnection.hasChanges(forGroup: self.currentGrouping(), in: notifications)
        if ( !hasChangesForGroup ) {
            self.databaseConnection.read { (transaction) in
                self.threadMappings.update(with: transaction)
            }
            self.updateViewState()
            
            return
        }
        
        // If the user hasn't already granted contact access
        // we don't want to request until they receive a message.
        var hasAnyMessages:Bool = false
        self.databaseConnection.read { (transaction) in
            hasAnyMessages = self.hasAnyMessages(withTransaction: transaction)
        }
        
        if ( hasAnyMessages ) {
            self.contactsManager.requestSystemContactsOnce()
        }
        
        var sectionChanges:NSArray = []
        var rowChanges:NSArray = []
        
        extDBConnection.getSectionChanges(&sectionChanges, rowChanges: &rowChanges,
                                          for: notifications, with: self.threadMappings)
        
        // We want this regardless of if we're currently viewing the archive.
        // So we run it before the early return
        self.updateViewState()
        
        if ( sectionChanges.count == 0 && rowChanges.count == 0 ) {
            return
        }
        
        self.tableView.beginUpdates()
        
        let typedSecChanges:[YapDatabaseViewSectionChange] = sectionChanges as! [YapDatabaseViewSectionChange]
        for sectionChange:YapDatabaseViewSectionChange in typedSecChanges {
            
            switch sectionChange.type {
            case .delete:
                self.tableView.deleteSections(IndexSet(integer: IndexSet.Element(sectionChange.index)),
                                              with: .automatic)
            case .insert:
                self.tableView.insertSections(IndexSet(integer: IndexSet.Element(sectionChange.index)),
                                              with: .automatic)
                break
            case .update:
                break
            case .move:
                break
            @unknown default:
                break
            }
        }
        
        let typedRowChanges:[YapDatabaseViewRowChange] = rowChanges as! [YapDatabaseViewRowChange]
        for rowChange:YapDatabaseViewRowChange in typedRowChanges {
            let key:NSString = rowChange.collectionKey.key as NSString
            //            OWSAssertDebug(key);
            self.threadViewModelCache.removeObject(forKey: key)
            
            switch rowChange.type {
            case .delete:
                self.tableView.deleteRows(at: [rowChange.indexPath!], with: .automatic)
                break
            case .insert:
                self.tableView.insertRows(at: [rowChange.indexPath!], with: .automatic)
                break
            case .move:
                self.tableView.deleteRows(at: [rowChange.indexPath!], with: .automatic)
                self.tableView.insertRows(at: [rowChange.newIndexPath!], with: .automatic)
                break
            case .update:
                self.tableView.reloadRows(at: [rowChange.indexPath!], with: .automatic)
                break
            @unknown default:
                break
            }
        }
        
        self.tableView.endUpdates()
    }
    
    func numberOfThreadsInGroup(group:String) -> Int {
        // We need to consult the db view, not the mapping since the mapping only knows about
        // the current group.
        var result:Int = 0
        self.databaseConnection.read { (transaction) in
            let viewTransaction:YapDatabaseViewTransaction = transaction.extension(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewTransaction
            result = Int(viewTransaction.numberOfItems(inGroup: group))
        }
        
        return result
    }
    
    func numberOfInboxThreads() -> Int {
        return self.numberOfThreadsInGroup(group: currentGrouping())
    }
    
    func updateViewState() {
        if ( self.shouldShowFirstConversationCue() ) {
            self.tableView.isHidden = true
            self.emptyInboxView.isHidden = false
            self.firstConversationCueView.isHidden = false
            self.updateFirstConversationLabel()
        } else {
            self.tableView.isHidden = false
            self.emptyInboxView.isHidden = true
            self.firstConversationCueView.isHidden = true
        }
    }
    
    func shouldShowFirstConversationCue() -> Bool {
        return false
        //        return self.callsViewMode == .ChatsViewMode_Inbox && self.numberOfInboxThreads() == 0
        //            && self.numberOfArchivedThreads() == 0 && !AppPreferences.hasDimissedFirstConversationCue
        //            && !SSKPreferences.hasSavedThread
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
extension VinciCallsViewController: BlockListCacheDelegate {
    func blockListCacheDidUpdate(_ blocklistCache:BlockListCache) {
        //        OWSLogVerbose(@"");
        self.reloadTableViewData()
    }
}

extension VinciCallsViewController : UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext:UIViewControllerPreviewing, viewControllerForLocation location:CGPoint) -> UIViewController? {
        let indexPath = self.tableView.indexPathForRow(at: location)
        
        if ( indexPath == nil ) {
            return nil
        }
        
        if ( indexPath?.section != CallsViewConrollerSection.CallsViewControllerSectionConversations.rawValue ) {
            return nil
        }
        
        previewingContext.sourceRect = self.tableView.rectForRow(at: indexPath!)
        
        let vc = ConversationViewController()
        let thread = self.threadForIndexPath(indexPath: indexPath!)
        self.lastThread = thread
        vc.configure(for: thread!, action: .none, focusMessageId: nil)
        vc.peekSetup()
        
        return vc
    }
    
    func previewingContext(_ previewingContext:UIViewControllerPreviewing, commit viewControllerToCommit:UIViewController) {
        let vc:ConversationViewController = viewControllerToCommit as! ConversationViewController
        vc.popped()
        
        self.navigationController?.pushViewController(vc, animated: false)
    }
}

extension VinciCallsViewController : VinciTabEditPanelDelegate {
    
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
