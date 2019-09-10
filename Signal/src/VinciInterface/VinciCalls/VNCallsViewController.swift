//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc class VNCallsViewController: VinciViewController {
    
    let navigationBar = VinciTopMenuController(title: "")
    var navigationBarTopConstraint: NSLayoutConstraint!
    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    
    var hideSearchBarWhenScrolling = true
    
    var headerViewMaxHeight: CGFloat = 128.0
    let headerViewMinHeight: CGFloat = 42.0
    
    var editButton: UIButton?
    
    @objc enum VNCallsViewMode:Int {
        case allCalls
        case missedCalls
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
    let kEmptyCallsViewPseudoGroup:String = "kEmptyCallsViewPseudoGroup"
    
    @objc enum VinciCallsSection:Int {
        case sectionReminders = 0
        case sectionEmptyCalls = 1
        case sectionCalls = 2
    }
    
    var firstConversationCueView:UIView!
    var firstConversationLabel:UILabel!
    
    var editingDatabaseConnection:YapDatabaseConnection!
    var databaseConnection:YapDatabaseConnection!
    var callMappings:YapDatabaseViewMappings!
    var filteredCalls = [TSCall]()
    
    var callsViewMode:VNCallsViewMode = .allCalls
    @objc var previewingContext:Any?
    var callViewModelCache:NSCache<NSString,CallViewModel> = NSCache()
    var shouldObserveDBModifications:Bool = true
    
    var selfTitle = ""
    
    // MARK: Search
    var searchBar:UISearchBar!
    
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
    var archiveReminderView:UIView!
    var missingContactsPermissionView:UIView!
    
    var lastCall:TSCall?
    
    var hasArchivedThreadsRow:Bool = false
    var hasVisibleReminders:Bool = false
    var hasThemeChanged:Bool = false
    
    // VINCI extension
    var callsEditModeOn:Bool = false
    var selectedThreads:[TSThread] = []
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.callsViewMode = .allCalls
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
        self.callViewModelCache = NSCache()
        
        // Ensure ExperienceUpgradeFinder has been initialized.
        //#pragma GCC diagnostic push
        //#pragma GCC diagnostic ignored "-Wunused-result"
        let _ = ExperienceUpgradeFinder.shared
        //#pragma GCC diagnostic pop
    }
    
    func observeNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(signalAccountsDidChange(notification:)),
                                               name: .OWSContactsManagerSignalAccountsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)),
                                               name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)),
                                               name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)),
                                               name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
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
        SignalApp.shared().vinciCallsViewController = self
        
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
        
        archiveReminderView = ReminderView.explanation(text: NSLocalizedString("INBOX_VIEW_ARCHIVE_MODE_REMINDER", comment: "Label reminding the user that they are in archive mode."))
        reminderStackView.addArrangedSubview(archiveReminderView)
        //        archiveReminderView.accessibilityIdentifier = String(format: "%@.%@", self, "archiveReminderView")
        
        missingContactsPermissionView = ReminderView.nag(text: NSLocalizedString("INBOX_VIEW_MISSING_CONTACTS_PERMISSION", comment: "Multi-line label explaining how to show names instead of phone numbers in your inbox"), tapAction: ({
            UIApplication.shared.openSystemSettings()
        }))
        reminderStackView.addArrangedSubview(missingContactsPermissionView)
        //        missingContactsPermissionView.accessibilityIdentifier = String(format: "%@.%@", self, "missingContactsPermissionView")
        
        createFirstConversationCueView()
        view.addSubview(firstConversationCueView)
        firstConversationCueView.autoPin(toTopLayoutGuideOf: self, withInset: 0)
        // This inset bakes in assumptions about UINavigationBar layout, but I'm not sure
        // there's a better way to do it, since it isn't safe to use iOS auto layout with
        // UINavigationBar contents.
        firstConversationCueView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 6.0)
        firstConversationCueView.autoPinEdge(toSuperviewEdge: .leading, withInset: 10, relation: .greaterThanOrEqual)
        firstConversationCueView.autoPinEdge(toSuperviewMargin: .bottom, relation: .greaterThanOrEqual)
    }
    
    func createEmptyInboxView() -> UIView {
        return UIView()
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
        layerView.layoutMargins = UIEdgeInsets.init(top: 11 + kTailHeight, left: 16, bottom: 11, right: 16)
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
        //        AppPreferences.hasDimissedFirstConversationCue = true
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
        
        //        let archiveReminderIsHidden = self.callsViewMode != VNCallsViewMode.archivedChats
        let missingContactsPermissionIsHidden = !self.contactsManager.isSystemContactsDenied
        let deregisteredIsHidden = !TSAccountManager.sharedInstance().isDeregistered()
        let outageIsHidden = !OutageDetection.shared.hasOutage
        
        // change archive reminder hidden to true value
        //        self.archiveReminderView.isHidden = archiveReminderIsHidden
        self.archiveReminderView.isHidden = true
        // App is killed and restarted when the user changes their contact permissions, so need need to "observe" anything
        // to re-render this.
        self.missingContactsPermissionView.isHidden = missingContactsPermissionIsHidden
        self.deregisteredView.isHidden = deregisteredIsHidden
        self.outageView.isHidden = outageIsHidden
        
        self.hasVisibleReminders = !self.archiveReminderView.isHidden || !self.missingContactsPermissionView.isHidden || !self.deregisteredView.isHidden || !self.outageView.isHidden
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
        
        //        UIFont.familyNames.forEach({ familyName in
        //            let fontNames = UIFont.fontNames(forFamilyName: familyName)
        //            print(familyName, fontNames)
        //        })
        
//        guard  let statusBar = (UIApplication.shared.value(forKey: "statusBarWindow") as AnyObject).value(forKey: "statusBar") as? UIView else {
//            return
//        }
//        statusBar.backgroundColor = Theme.backgroundColor
        
        navigationBar.titleType = .callsTitle
        
        view.addSubview(navigationBar.view)
        navigationBarTopConstraint = navigationBar.pinToTop()
        
        headerViewMaxHeight = navigationBar.maxBarHeight
        
        if let topTitleView = navigationBar.topTitleView as? VinciCallsTitleViewController {
            topTitleView.leftBarItems.append(UIBarButtonItem(title: "Edit", style: .plain, target: self, action:#selector(editButtonPressed)))
            topTitleView.rightBarItems.append(UIBarButtonItem(image: UIImage(named: "newCallIcon"), style: .plain, target: self, action: #selector(showNewCallView)))
            
            if let editButtonItem = topTitleView.leftBarItemStack.arrangedSubviews[0] as? UIButton {
                editButton = editButtonItem
                editButton?.isEnabled = false
            }
            
            topTitleView.callsTitleDelegate = self
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.separatorColor = Theme.cellSeparatorColor
        tableView.register(VinciEmptyChatsViewCell.self, forCellReuseIdentifier: VinciEmptyChatsViewCell.reuseIdentifier)
        tableView.register(VinciCallViewCell.self, forCellReuseIdentifier: VinciCallViewCell.cellReuseIdentifier())
        self.view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: navigationBar.view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        // VINCI CHATS
        editingDatabaseConnection = OWSPrimaryStorage.shared().newDatabaseConnection()
        
        // Create the database connection.
        databaseConnection = uiDatabaseConnection()
        
        updateMappings()
        updateViewState()
        updateReminderViews()
        observeNotifications()
        
        // because this uses the table data source, `tableViewSetup` must happen
        // after mappings have been set up in `showInboxGrouping`
        tableViewSetUp()
        
        if traitCollection.responds(to: #selector(getter: traitCollection.forceTouchCapability)) &&
            traitCollection.forceTouchCapability == UIForceTouchCapability.available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
        
        navigationBar.searchBar.searchDelegate = self
        navigationBar.searchBar.searchBar.placeholder = "Search for messages or users"
        searchBar = navigationBar.searchBar.searchBar
        
        if numberOfAllCalls() == 0 {
            navigationBar.searchBarMode = .hidden
        }
        
        updateReminderViews()
        updateBarButtonItems()
        applyTheme()
    }
    
    @objc func dismissViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.tabBarController?.tabBar.isHidden = false
        hideSearchBarWhenScrolling = true
        
        if ( hasThemeChanged ) {
            tableView.reloadData()
            hasThemeChanged = false
        }
        
        requestReviewIfAppropriate()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    func updateBarButtonItems() {
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateMappings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @objc func settingsButtonPressed() {
        let navigationController:OWSNavigationController = AppSettingsViewController.inModalNavigationController()
        present(navigationController, animated: true, completion: nil)
    }
    
    @objc func showNewCallView() {
        AssertIsOnMainThread()
        //        OWSLogInfo(@"");
        
        let viewController:VNNewCallViewController = VNNewCallViewController()
        viewController.view.backgroundColor = Theme.backgroundColor
        
        contactsManager.requestSystemContactsOnce { (error:Error?) in
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
        callViewModelCache.removeAllObjects()
        tableView.reloadData()
    }
    
    // MARK: Database
    func uiDatabaseConnection() -> YapDatabaseConnection {
        if ( databaseConnection == nil ) {
            databaseConnection = OWSPrimaryStorage.shared().newDatabaseConnection()
            // default is 250
            databaseConnection.objectCacheLimit = 500
            databaseConnection.beginLongLivedReadTransaction()
        }
        
        return databaseConnection
    }
    
    func resetMappings() {
        // If we're entering "active" mode (e.g. view is visible and app is in foreground),
        // reset all state updated by yapDatabaseModified:.
        if ( callMappings != nil ) {
            // Before we begin observing database modifications, make sure
            // our mapping and table state is up-to-date.
            //
            // We need to `beginLongLivedReadTransaction` before we update our
            // mapping in order to jump to the most recent commit.
            uiDatabaseConnection().beginLongLivedReadTransaction()
            uiDatabaseConnection().read { (transaction) in
                self.callMappings.update(with: transaction)
                
                //                for group in self.callMappings.allGroups {
                //                    let section = self.callMappings.section(forGroup: group)
                //                    let itemsCount = self.callMappings.numberOfItems(inGroup: group)
                //                    for row in 0..<itemsCount {
                //                        let indexPath = IndexPath(row: Int(row), section: Int(section))
                //
                //                        let extTransaction:YapDatabaseViewTransaction = transaction.extension(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewTransaction
                //                        if let thread = extTransaction.object(at: indexPath, with: self.callMappings) as? TSThread {
                //                            if thread.isGroupThread() {
                //                                self.groupThreads.append(thread)
                //                            } else {
                //                                self.contactThreads.append(thread)
                //                            }
                //                        }
                //                    }
                //                }
            }
            
            filteredCalls = []
            if navigationBar.isSearching {
                uiDatabaseConnection().read { (transaction) in
                    let extTransaction:YapDatabaseViewTransaction = transaction.extension(TSCallMessageDatabaseViewExtensionName) as! YapDatabaseViewTransaction
                    
                    let section = VinciCallsSection.sectionCalls.rawValue
                    let itemsCount = self.callMappings.numberOfItems(inSection: UInt(section))
                    for row in 0...itemsCount {
                        let indexPath = IndexPath(row: Int(row), section: Int(section))
                        if let call = extTransaction.object(at: indexPath, with: self.callMappings) as? TSCall {
                            let name = self.contactsManager.attributedContactOrProfileName(forPhoneIdentifier: call.thread.contactIdentifier() ?? ""
                                , primaryFont: VinciStrings.regularFont, secondaryFont: VinciStrings.regularFont)
                            let number = call.thread.recipientIdentifiers[0]
                            
//                            print("call to \(name.string) \(number)")
                            if let searchText = self.navigationBar.searchBar.searchBar.text {
                                if number.containsIgnoringCase(searchText) || name.string.containsIgnoringCase(searchText) {
                                    self.filteredCalls.append(call)
                                }
                            }
                        }
                    }
                }
            }
            
            reloadTableViewData()
            
            updateViewState()
            
            // If the user hasn't already granted contact access
            // we don't want to request until they receive a message.
            var hasAnyMessages:Bool = false
            uiDatabaseConnection().read { (transaction) in
                hasAnyMessages = self.hasAnyMessages(withTransaction: transaction)
            }
            if ( hasAnyMessages ) {
                contactsManager.requestSystemContactsOnce()
            }
        }
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
        var hasAnyMessages:Bool = false
        uiDatabaseConnection().read { (transaction) in
            hasAnyMessages = self.hasAnyMessages(withTransaction: transaction)
        }
        
        if ( hasAnyMessages ) {
            contactsManager.requestSystemContactsOnce { (error) in
                DispatchQueue.main.async {
                    self.updateReminderViews()
                }
            }
        }
    }
    
    @objc func applicationWillResignActive(notification: NSNotification) {
        updateShouldObserveDBModifications()
    }
    
    // MARK - startup
    func unseenUpgradeExperiences() -> [ExperienceUpgrade] {
        //        OWSAssertIsOnMainThread();
        
        var unseenUpgrades:[ExperienceUpgrade] = []
        uiDatabaseConnection().read { (transaction) in
            unseenUpgrades = ExperienceUpgradeFinder.shared.allUnseen(transaction: transaction)
        }
        
        return unseenUpgrades
    }
    
    func displayAnyUnseenUpgradeExperience() {
        //        OWSAssertIsOnMainThread();
        
        let unseenUpgrades = unseenUpgradeExperiences()
        
        if ( unseenUpgrades.count > 0 ) {
            let experienceUpgradeViewController:ExperienceUpgradesPageViewController =
                ExperienceUpgradesPageViewController.init(experienceUpgrades: unseenUpgrades)
            present(experienceUpgradeViewController, animated: true, completion: nil)
        } else {
            OWSAlerts.showIOSUpgradeNagIfNecessary()
        }
    }
    
    func tableViewSetUp() {
        tableView.tableFooterView = UIView.init(frame: CGRect.zero)
    }
    
    func updateSearchBarVisibility() {
        if numberOfCurrentCalls() == 0 {
            navigationBar.searchBarMode = .hidden
        } else {
            navigationBar.searchBarMode = .opened
        }
    }
    
    @objc func editButtonPressed() {
        
        // if no chats in current view - don't enter edit mode
        if !callsEditModeOn && numberOfCurrentCalls() == 0 {
            return
        }
        
        callsEditModeOn = !self.callsEditModeOn
        tableView.allowsMultipleSelection = callsEditModeOn
        tableView.reloadData()
        
        let editButtonTitle = callsEditModeOn ? "Done" : "Edit"
        editButton?.setTitle(editButtonTitle, for: .normal)
    }
    
    func newCall(recipientId: String) {
        let thread = TSContactThread.getOrCreateThread(contactId: recipientId)
        newCall(thread: thread)
    }
    
    func newCall(thread: TSThread) {
        if let contactIdentifier = thread.contactIdentifier() {
            let outboundCallInitiator = AppEnvironment.shared.outboundCallInitiator
            outboundCallInitiator.initiateCall(recipientId: contactIdentifier, isVideo: false)
        }
    }
}

extension VNCallsViewController : VinciCallsTitleViewControllerDelegate {
    
    func allCallsTitleDidPressed() {
        navigationBar.setLargeTitle(collapsed: false)
        callsViewMode = .allCalls
        updateMappings()
    }
    
    func missedCallsTitleDidPressed() {
        navigationBar.setLargeTitle(collapsed: true)
        callsViewMode = .missedCalls
        updateMappings()
    }
}

extension VNCallsViewController : UITableViewDelegate {
    
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
    
    // MARK: Edit Actions
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        return
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return UISwipeActionsConfiguration(actions: [])
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let section:VinciCallsSection = VNCallsViewController.VinciCallsSection(rawValue: indexPath.section)!
        switch section {
        case .sectionReminders:
            return UISwipeActionsConfiguration(actions: [])
        case .sectionEmptyCalls:
            return UISwipeActionsConfiguration(actions: [])
        case .sectionCalls:
            
            let deleteAction = UIContextualAction(style: .destructive, title: "") { (action, view, (Bool) -> Void) in
                self.tableViewCellTappedDelete(indexPath)
            }
            deleteAction.image = UIImage(named: "editTrashIcon")
            deleteAction.backgroundColor = UIColor(rgbHex: 0xFC3D39)
            
            // The first action will be auto-performed for "very long swipes".
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let section:VinciCallsSection = VNCallsViewController.VinciCallsSection(rawValue: indexPath.section)!
        switch section {
        case .sectionReminders:
            return false
        case .sectionEmptyCalls:
            return false
        case .sectionCalls:
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        OWSLogInfo(@"%ld %ld", (long)indexPath.row, (long)indexPath.section);
        
        self.searchBar.resignFirstResponder()
        let section:VinciCallsSection = VNCallsViewController.VinciCallsSection(rawValue: indexPath.section)!
        switch section {
        case .sectionReminders:
            break
        case .sectionEmptyCalls:
            break
        case .sectionCalls:
            if self.callsEditModeOn {
                //                let cell = tableView.cellForRow(at: indexPath) as! VinciChatViewCell
                //                let thread:ThreadViewModel = threadViewModelForIndexPath(indexPath: indexPath)
                //
                //                if cell.checker.isChecked {
                //                    // it will be unchecked below, so remove thread from selected
                //                    if let index = selectedThreads.firstIndex(of: thread.threadRecord) {
                //                        selectedThreads.remove(at: index)
                //                    }
                //                } else {
                //                    selectedThreads.append(thread.threadRecord)
                //                }
                //
                //                cell.checker.setState(checked: !cell.checker.isChecked, animated: true)
                
                let call:TSCall = callMessageForIndexPath(indexPath: indexPath)!
                
                let actionSheetController = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
                actionSheetController.addAction(UIAlertAction(title: "Delete chat", style: .destructive, handler: { (action) in
//                    self.deleteCall(thread: thread)
                }))
                actionSheetController.addAction(OWSAlerts.cancelAction)
                
                self.present(actionSheetController, animated: true, completion: nil)
                
            } else {
                if let call = self.callMessageForIndexPath(indexPath: indexPath) {
//                    presentCallInfo(call: call)
                    newCall(thread: call.thread)
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
            break
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        //        OWSLogInfo(@"%ld %ld", (long)indexPath.row, (long)indexPath.section);
        
//        if navigationBar.isSearching {
//            searchResultsController.tableView(tableView, didDeselectRowAt: indexPath)
//            return
//        }
        
        self.searchBar.resignFirstResponder()
        let section:VinciCallsSection = VNCallsViewController.VinciCallsSection(rawValue: indexPath.section)!
        switch section {
        case .sectionReminders:
            break
        case .sectionEmptyCalls:
            break
        case .sectionCalls:
            if callsEditModeOn {
                let cell = tableView.cellForRow(at: indexPath) as! VinciChatViewCell
                cell.checker.setState(checked: !cell.checker.isChecked, animated: true)
            }
            break
        }
    }
}

extension VNCallsViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let result = Int(callMappings.numberOfSections())
        return result
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let aSection:VinciCallsSection = VinciCallsSection(rawValue: section)!
        switch aSection {
        case VinciCallsSection.sectionReminders:
            return hasVisibleReminders ? 1 : 0
        case .sectionEmptyCalls:
            var callCount = 0
            if callsViewMode == .allCalls {
                callCount = numberOfAllCalls()
            } else {
                callCount = numberOfMissedCalls()
            }
            
            return ( callCount == 0 && !hasVisibleReminders ) ? 1 : 0
        case VinciCallsSection.sectionCalls:
            
            var result:Int = 0
            if navigationBar.isSearching {
                result = filteredCalls.count
            } else {
                result = Int(callMappings.numberOfItems(inSection: UInt(section)))
            }
            
            editButton?.isEnabled = result == 0 ? false : true
            return result
        }
        
        // OWSFailDebug(@"failure: unexpected section: %lu", (unsigned long)section);
    }
    
    func callViewModelForIndexPath(indexPath: IndexPath) -> CallViewModel {
        // VINCI edited
        let callRecord:TSCall! = callMessageForIndexPath(indexPath: indexPath)
        //        OWSAssertDebug(threadRecord);
        
        let cachedCallViewModel:CallViewModel? = callViewModelCache.object(forKey: callRecord.uniqueId! as NSString)
        
        if ( cachedCallViewModel != nil ) {
            return cachedCallViewModel!
        }
        
        var newCallViewModel:CallViewModel?
        databaseConnection.read { (transaction) in
            newCallViewModel = CallViewModel.init(call: callRecord, transaction: transaction)
        }
        callViewModelCache.setObject(newCallViewModel!, forKey: callRecord.uniqueId! as NSString)
        
        return newCallViewModel!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section:VinciCallsSection = VinciCallsSection(rawValue: indexPath.section)!
        switch section {
        case .sectionReminders:
            //        OWSAssert(self.reminderStackView);
            return self.reminderViewCell
        case .sectionEmptyCalls:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: VinciEmptyChatsViewCell.reuseIdentifier) as? VinciEmptyChatsViewCell else {
                owsFailDebug("cell was unexpectedly nil")
                return UITableViewCell()
            }
            
            OWSTableItem.configureCell(cell)
            cell.configure(size: tableView.frame.size)
            cell.selectionStyle = .none
            return cell
        case .sectionCalls:
            return self.tableView(tableView, cellForCallAtIndexPath: indexPath)
        }
        
        //        OWSFailDebug(@"failure: unexpected section: %lu", (unsigned long)section)
    }
    
    func tableView(_ tableView: UITableView, cellForCallAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell:VinciCallViewCell = tableView.dequeueReusableCell(withIdentifier: VinciCallViewCell.cellReuseIdentifier()) as! VinciCallViewCell
        
        // VINCI edit mode on?
        if cell.isCheckable != callsEditModeOn {
            cell.isCheckable = callsEditModeOn
        }
        
        cell.delChecker.setState(checked: true, animated: false)
        //        OWSAssertDebug(cell);
        
        let call:CallViewModel = callViewModelForIndexPath(indexPath: indexPath)
        
//        let isBlocked:Bool = blocklistCache.isBlocked(thread: call.callRecord)
        
        OWSTableItem.configureCell(cell)
        cell.configure(withCall: call, isBlocked: false)
        
        // TODO: is it accessible via Appium.
        //        let cellName:NSString = NSString.init(format: "conversation-%@", NSUUID.UUID().uuidString)
        //        cell.accessibilityIdentifier = ACCESSIBILITY_IDENTIFIER_WITH_NAME(self, cellName);
        
        return cell
    }
    
    func callMessageForIndexPath(indexPath: IndexPath) -> TSCall? {
        
        if navigationBar.isSearching {
            return filteredCalls[indexPath.row]
        } else {
            var call:TSCall?
            uiDatabaseConnection().read { (transaction) in
                let extTransaction:YapDatabaseViewTransaction = transaction.extension(TSCallMessageDatabaseViewExtensionName) as! YapDatabaseViewTransaction
                call = extTransaction.object(at: indexPath, with: self.callMappings) as? TSCall
            }
            
            if ( !(call?.isKind(of: TSCall.self))! ) {
                // OWSLogError(@"Invalid object in thread view: %@", [thread class]);
                OWSStorage.incrementVersion(ofDatabaseExtension: TSCallMessageDatabaseViewExtensionName)
            }
            
            return call
        }
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

extension VNCallsViewController : UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        
        navigationBar.searchBar.searchBar.setShowsCancelButton(false, animated: false)
        
//        if let searchResultsView = searchResultsController.view {
//            searchResultsView.translatesAutoresizingMaskIntoConstraints = false
//            view.insertSubview(searchResultsView, belowSubview: tableView)
//
//            searchResultsView.topAnchor.constraint(equalTo: navigationBar.view.bottomAnchor).isActive = true
//            searchResultsView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//            searchResultsView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//            searchResultsView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
//
//            view.layoutIfNeeded()
//        }
        
//        let tableView = searchResultsController.tableView
//        tableView.delegate = hideSearchBarWhenScrolling ? self : nil
//        tableView.setContentOffset(CGPoint(x: 0.0, y: 0.0), animated: false)
        
        let navBarLargeTitleHeight = navigationBar.largeTitleView.frame.height
        navigationBarTopConstraint.constant = -navigationBar.topTitleView.view.frame.height - navBarLargeTitleHeight
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseInOut, animations: {
            self.navigationBar.topTitleView.view.alpha = 0.0
            self.navigationBar.largeTitleView.alpha = 0.0
//            self.tableView.alpha = 0.0f
            self.view.layoutIfNeeded()
        }) { (finished) in
            self.navigationBar.searchBar.searchBarIsReady()
        }
        
        return searchBar == self.searchBar
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        updateMappings()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text?.removeAll()
        searchBar.resignFirstResponder()
        
        updateMappings()
        
        navigationBarTopConstraint.constant = 0.0
        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseInOut, animations: {
            self.navigationBar.topTitleView.view.alpha = 1.0
            self.navigationBar.largeTitleView.alpha = 1.0
            self.tableView.alpha = 1.0
            self.view.layoutIfNeeded()
        }) { (finished) in
        }
    }
    
    func updateSearchResultsVisibility() {
        return
    }
    
    //    func scrollSearchBarToTopAnimated(animated:Bool) {
    //        let topInset = topLayoutGuide.length
    //        tableView.setContentOffset(CGPoint.init(x: 0, y: -topInset), animated: animated)
    //    }
}

// MARK: ConversationSearchViewDelegate
extension VNCallsViewController : VinciSearchResultsViewDelegate {
    func conversationSearchViewWillBeginDragging() {
        //        searchBar.resignFirstResponder()
        // OWSAssertDebug(!self.searchBar.isFirstResponder);
    }
    
    func didSelect(rowWith vinciAccount: SignalAccount) {
        return
    }
}

// MARK: HomeFeedTableViewCellDelegate
extension VNCallsViewController {
    
    func tableViewCellTappedDelete(indexPath:IndexPath) {
        if ( indexPath.section != VinciCallsSection.sectionCalls.rawValue ) {
            //            OWSFailDebug(@"failure: unexpected section: %lu", (unsigned long)indexPath.section);
            return
        }
        
        let call:TSCall = callMessageForIndexPath(indexPath: indexPath)!
        deleteCall(call: call)
//        let actionSheetController = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
//        actionSheetController.addAction(UIAlertAction(title: "Delete call", style: .destructive, handler: { (action) in
//            self.deleteCall(call: call)
//        }))
//        actionSheetController.addAction(OWSAlerts.cancelAction)
//
//        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    @objc public func deleteCall(call:TSCall) {
        editingDatabaseConnection.readWrite { (transaction) in
            call.remove(with: transaction)
        }
        
        updateViewState()
    }
    
    @objc public func presentCallInfo(call: TSCall) {
        let viewController = VinciInfoCallViewController(call: call)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
//    @objc public func presentCall(thread:TSThread?, action:ConversationViewAction, animated isAnimated:Bool) {
//        presentChat(thread: thread, action: action, focusMessageId: nil, animated: isAnimated)
//    }
//
//    @objc public func presentCall(thread:TSThread?, action:ConversationViewAction, focusMessageId:String?, animated isAnimated:Bool) {
//        if ( thread == nil ) {
//            // OWSFailDebug(@"Thread unexpectedly nil");
//            return
//        }
//
//        DispatchQueue.main.async {
//            let conversationViewController:ConversationViewController = ConversationViewController()
//            conversationViewController.configure(for: thread!, action: action, focusMessageId: focusMessageId)
//
//            conversationViewController.title = thread?.name() ?? ""
//
//            self.lastThread = thread
//
////            if ( self.callsViewMode == .archivedChats ) {
////
////                self.navigationController?.pushViewController(conversationViewController, animated: isAnimated)
////            } else {
////                //                self.navigationController?.setViewControllers([self, conversationViewController], animated: isAnimated)
////                self.navigationController?.pushViewController(conversationViewController, animated: isAnimated)
////                if self.navigationController?.presentedViewController != nil {
////                    //                    self.navigationController?.dismiss(animated: true, completion: nil)
////                    self.navigationController?.popViewController(animated: true)
////                }
////            }
//        }
//    }
}

// MARK: Grouping
extension VNCallsViewController {
    
    func showInboxGrouping() {
        //        OWSAssertDebug(self.homeViewMode == HomeViewMode_Archive);
        navigationController?.popToRootViewController(animated: true)
    }
    
    func currentGrouping() -> String {
        switch self.callsViewMode {
        case .allCalls:
            return TSAllCallsGroup
        case .missedCalls:
            return TSMissedCallsGroup
        }
    }
    
    func updateMappings() {
        //        OWSAssertIsOnMainThread();
            
        callMappings = YapDatabaseViewMappings.init(groups: [kReminderViewPseudoGroup, kEmptyCallsViewPseudoGroup, currentGrouping()], view: TSCallMessageDatabaseViewExtensionName)

        callMappings.setIsReversed(true, forGroup: currentGrouping())
        
        resetMappings()
        
        reloadTableViewData()
        updateViewState()
        updateSearchBarVisibility()
        updateReminderViews()
    }
}

// MARK: Database delegates
extension VNCallsViewController {
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
        
        if ( !shouldObserveDBModifications ) {
            return
        }
        
        let notifications = databaseConnection.beginLongLivedReadTransaction()
        let extDBConnection:YapDatabaseViewConnection = databaseConnection.extension(TSCallMessageDatabaseViewExtensionName) as! YapDatabaseViewConnection
        let hasChangesForGroup:Bool = extDBConnection.hasChanges(forGroup: currentGrouping(), in: notifications)
        if ( !hasChangesForGroup ) {
            databaseConnection.read { (transaction) in
                self.callMappings.update(with: transaction)
            }
            updateViewState()
            
            return
        }
        
        // If the user hasn't already granted contact access
        // we don't want to request until they receive a message.
        var hasAnyMessages:Bool = false
        databaseConnection.read { (transaction) in
            hasAnyMessages = self.hasAnyMessages(withTransaction: transaction)
        }
        
        if ( hasAnyMessages ) {
            contactsManager.requestSystemContactsOnce()
        }
        
        var sectionChanges:NSArray = []
        var rowChanges:NSArray = []
        
        extDBConnection.getSectionChanges(&sectionChanges, rowChanges: &rowChanges,
                                          for: notifications, with: callMappings)
        
        // We want this regardless of if we're currently viewing the archive.
        // So we run it before the early return
        updateViewState()
        
        if ( sectionChanges.count == 0 && rowChanges.count == 0 ) {
            return
        }
        
        self.tableView.beginUpdates()
        
        let typedSecChanges:[YapDatabaseViewSectionChange] = sectionChanges as! [YapDatabaseViewSectionChange]
        for sectionChange:YapDatabaseViewSectionChange in typedSecChanges {
            
            switch sectionChange.type {
            case .delete:
                tableView.deleteSections(IndexSet(integer: IndexSet.Element(sectionChange.index)),
                                         with: .automatic)
            case .insert:
                tableView.insertSections(IndexSet(integer: IndexSet.Element(sectionChange.index)),
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
            self.callViewModelCache.removeObject(forKey: key)
            
            switch rowChange.type {
            case .delete:
                let inboxThreadsCount = numberOfAllCalls()
                
                if inboxThreadsCount == 0 {
                    tableView.insertRows(at: [IndexPath(row: 0, section: VinciCallsSection.sectionEmptyCalls.rawValue)], with: .automatic)
                }
                
                print("original: \(rowChange.originalIndex) \(rowChange.originalSection)")
                print("final: \(rowChange.finalIndex) \(rowChange.finalSection)")
                
                let indexPath = IndexPath(row: Int(rowChange.originalIndex), section: Int(rowChange.originalSection))
                tableView.deleteRows(at: [indexPath], with: .automatic)
                break
            case .insert:
                let inboxThreadsCount = numberOfAllCalls()
                
                if inboxThreadsCount == 1 {
                    tableView.deleteRows(at: [IndexPath(row: 0, section: VinciCallsSection.sectionEmptyCalls.rawValue)], with: .automatic)
                }
                
                let indexPath = IndexPath(row: Int(rowChange.finalIndex), section: Int(rowChange.finalSection))
                tableView.insertRows(at: [indexPath], with: .automatic)
                break
            case .move:
                tableView.deleteRows(at: [rowChange.indexPath!], with: .automatic)
                tableView.insertRows(at: [rowChange.newIndexPath!], with: .automatic)
                break
            case .update:
                let indexPath = IndexPath(row: Int(rowChange.finalIndex), section: Int(rowChange.finalSection))
                tableView.reloadRows(at: [rowChange.indexPath ?? indexPath], with: .automatic)
                break
            @unknown default:
                break
            }
        }
        
        tableView.endUpdates()
        tableView.reloadData()
        
        updateSearchBarVisibility()
    }
    
    func numberOfCallsInGroup(group:String) -> Int {
        // We need to consult the db view, not the mapping since the mapping only knows about
        // the current group.
        var result:Int = 0
        databaseConnection.read { (transaction) in
            let viewTransaction:YapDatabaseViewTransaction = transaction.extension(TSCallMessageDatabaseViewExtensionName) as! YapDatabaseViewTransaction
            result = Int(viewTransaction.numberOfItems(inGroup: group))
        }
        
        return result
    }
    
    func numberOfCurrentCalls() -> Int {
        return numberOfCallsInGroup(group: currentGrouping())
    }
    
    func numberOfAllCalls() -> Int {
        return numberOfCallsInGroup(group: TSAllCallsGroup) + numberOfCallsInGroup(group: TSMissedCallsGroup)
    }
    
    func numberOfMissedCalls() -> Int {
        return self.numberOfCallsInGroup(group: TSMissedCallsGroup)
    }
    
    func updateViewState() {
        if ( shouldShowFirstConversationCue() ) {
            firstConversationCueView.isHidden = false
            updateFirstConversationLabel()
        } else {
            firstConversationCueView.isHidden = true
        }
    }
    
    func shouldShowFirstConversationCue() -> Bool {
        //        return callsViewMode == .chats && numberOfAllInboxThreads() == 0
        //            && self.numberOfArchivedThreads() == 0 && !AppPreferences.hasDimissedFirstConversationCue
        //            && !SSKPreferences.hasSavedThread
        
        return callsViewMode == .allCalls && numberOfAllCalls() == 0 && false
    }
    
    // We want to delay asking for a review until an opportune time.
    // If the user has *just* launched Signal they intend to do something, we don't want to interrupt them.
    // If the user hasn't sent a message, we don't want to ask them for a review yet.
    func requestReviewIfAppropriate() {
        if ( hasEverAppeared && Environment.shared.preferences.hasSentAMessage() ) {
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
extension VNCallsViewController: BlockListCacheDelegate {
    func blockListCacheDidUpdate(_ blocklistCache:BlockListCache) {
        //        OWSLogVerbose(@"");
        reloadTableViewData()
    }
}

extension VNCallsViewController : UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext:UIViewControllerPreviewing, viewControllerForLocation location:CGPoint) -> UIViewController? {
        let indexPath = tableView.indexPathForRow(at: location)
        
        if ( indexPath == nil ) {
            return nil
        }
        
        if ( indexPath?.section != VinciCallsSection.sectionCalls.rawValue ) {
            return nil
        }
        
        previewingContext.sourceRect = tableView.rectForRow(at: indexPath!)
        
        if let call = callMessageForIndexPath(indexPath: indexPath!) {
            let vc = VinciInfoCallViewController(call: call)
            
            lastCall = call
            
//            vc.peekSetup()
            return vc
        }
        
        return UIViewController()
    }
    
    func previewingContext(_ previewingContext:UIViewControllerPreviewing, commit viewControllerToCommit:UIViewController) {
        let vc:VinciInfoCallViewController = viewControllerToCommit as! VinciInfoCallViewController
//        vc.popped()

        self.navigationController?.pushViewController(vc, animated: false)
    }
}
