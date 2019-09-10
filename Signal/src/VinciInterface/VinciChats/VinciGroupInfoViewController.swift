import UIKit
import Contacts
import ContactsUI

class VinciGroupTopRowViewCell: UITableViewCell {

    static let reuseIdentifier = "VinciGroupTopRowViewCell"
    var avatarImageView: AvatarImageView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }

    public func configure() {
    }
}

@objc class VinciGroupInfoViewController: VinciViewController {
    
    let navigationBar = VinciTopMenuController(title: "New Group")
    var navigationBarTopConstraint: NSLayoutConstraint!
    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    
    var searchResultsController: VinciContactsSearchResultsController!
    var hideSearchBarWhenScrolling = true
    
    var headerViewMaxHeight: CGFloat = 128.0
    let headerViewMinHeight: CGFloat = 42.0
    
    var messageSender: MessageSender!
    var avatarViewHelper: AvatarViewHelper!
    var avatarView = AvatarImageView()
    var groupAvatar: UIImage! {
        didSet {
            updateAvatarView()
        }
    }
    
    enum VNGroupInfoSections: Int {
        case sectionReminder = 0
        case sectionTitleRow = 1
        case sectionNotifications = 2
        case sectionSharedMedia = 3
        case sectionGroupMembersTitle = 4
        case sectionAddGroupMembers = 5
        case sectionGroupMembers = 6
        case sectionVinciUndefined = 7
        
        static let count: Int = {
            var max: Int = 0
            while let _ = VNGroupInfoSections(rawValue: max) { max += 1 }
            
            return max-1 // why minus 1? i don't need Undefined section, but i need it to complete switch-cases
        }()
    }
    
    var nonVinciContactsView: UIView!
    
    var collation: UILocalizedIndexedCollation!
    var modeWithCollation = true {
        didSet {
            updateTableContent()
        }
    }
    
    var inviteGroupMembersViewCell: VinciGroupInviteMembersViewCell!
    var nextButton: UIButton!
    
    let kGroupIdLength:__int32_t = 16
    var groupId: Data!
    
    var groupTitleTextView: UITextField!
    
    var searchBar: UISearchBar!
    
    // A list of possible phone numbers parsed from the search text as
    // E164 values.
    var searchPhoneNumbers = [String]()
    
    // data
    var vinciAccounts = [SignalAccount]()
    var sectionsMap = [VNGroupInfoSections:Int]()
    
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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.commonInit()
    }
    
    init(groupMembers:[SignalAccount]) {
        super.init(nibName: nil, bundle: nil)
        vinciAccounts = groupMembers
        
        commonInit()
    }
    
    func commonInit() {
        
        groupId = Randomness.generateRandomBytes(kGroupIdLength)
        contactsViewHelper = ContactsViewHelper(delegate: self)
        
        messageSender = SSKEnvironment.shared.messageSender
        
        // Make sure we have requested contact access at this point if, e.g.
        // the user has no messages in their inbox and they choose to compose
        // a message.
        contactsViewHelper.contactsManager.requestSystemContactsOnce()
        collation = UILocalizedIndexedCollation.current()
        
        avatarViewHelper = AvatarViewHelper()
        avatarViewHelper.delegate = self
        
        //        searchController = UISearchController(searchResultsController: nil)
        //        searchController.dimsBackgroundDuringPresentation = false
        //        searchBar = searchController.searchBar
        //        let searchBackground = UIImage(color: UIColor.magenta)
        //        searchBar.setBackgroundImage(searchBackground, for: .any, barMetrics: .default)
        
        // Ensure ExperienceUpgradeFinder has been initialized.
        //#pragma GCC diagnostic push
        //#pragma GCC diagnostic ignored "-Wunused-result"
        let _ = ExperienceUpgradeFinder.shared
        //#pragma GCC diagnostic pop
    }
    
    func defineSection(section: Int) -> VNGroupInfoSections {
        switch section {
        case VNGroupInfoSections.sectionReminder.rawValue:
            return VNGroupInfoSections.sectionReminder
        case VNGroupInfoSections.sectionTitleRow.rawValue:
            return VNGroupInfoSections.sectionTitleRow
        case VNGroupInfoSections.sectionNotifications.rawValue:
            return VNGroupInfoSections.sectionNotifications
        case VNGroupInfoSections.sectionSharedMedia.rawValue:
            return VNGroupInfoSections.sectionSharedMedia
        case VNGroupInfoSections.sectionGroupMembersTitle.rawValue:
            return VNGroupInfoSections.sectionGroupMembersTitle
        case VNGroupInfoSections.sectionAddGroupMembers.rawValue:
            return VNGroupInfoSections.sectionAddGroupMembers
        case VNGroupInfoSections.sectionGroupMembers.rawValue:
            return VNGroupInfoSections.sectionGroupMembers
        default:
            return VNGroupInfoSections.sectionVinciUndefined
        }
    }
    
    func hasVisibleReminders() -> Bool {
        return false
    }
    
    func observeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange(notification:)),
                                               name: .ThemeDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications
    
    @objc func themeDidChange(notification: NSNotification) {
        //        OWSAssertIsOnMainThread();
        
        self.applyTheme()
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
        
        inviteGroupMembersViewCell = VinciGroupInviteMembersViewCell()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(navigationBar.view)
        navigationBarTopConstraint = navigationBar.pinToTop()
        
        navigationBar.searchBar.searchDelegate = self
        searchBar = navigationBar.searchBar.searchBar
        headerViewMaxHeight = navigationBar.maxBarHeight
        
        navigationBar.searchBarMode = .hidden
        searchBar.placeholder = "Search for contacts or usernames"
        
        if let topTitleView = navigationBar.topTitleView as? VinciTopMenuRowViewController {
            topTitleView.leftBarItems.append(UIBarButtonItem(title: "< Back", style: .plain, target: self, action: #selector(dismissViewController)))
            topTitleView.rightBarItems.append(UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(createGroup)))
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.register(VinciContactViewCell.self, forCellReuseIdentifier: "VinciContactViewCell")
        view.addSubview(tableView)
        
        tableView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0), excludingEdge: .top)
        tableView.autoPinEdge(.top, to: .bottom, of: navigationBar.view)
        
        updateTableContent()
        self.updateBarButtonItems()
        self.applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    @objc func dismissViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func createGroup() {
        
//        OWSAssertIsOnMainThread();
        let model = makeGroup()
        var thread: TSGroupThread!
        
        OWSPrimaryStorage.dbReadWriteConnection().readWrite { (transaction) in
            thread = TSGroupThread.getOrCreateThread(with: model, transaction: transaction)
        }
        
//        OWSAssertDebug(thread);
        
        OWSProfileManager.shared().addThread(toProfileWhitelist: thread)
        
//        ModalActivityIndicatorViewController.present(fromViewController: self, canCancel: false) { (modalActivityIndicator) in
            let message = TSOutgoingMessage.init(outgoingMessageWithTimestamp: NSDate.ows_millisecondTimeStamp(),
                                                 in: thread,
                                                 messageBody: nil,
                                                 attachmentIds: [],
                                                 expiresInSeconds: 0,
                                                 expireStartedAt: 0,
                                                 isVoiceMessage: false,
                                                 groupMetaMessage: TSGroupMetaMessage.new,
                                                 quotedMessage: nil,
                                                 contactShare: nil)
            
            message.update(withCustomMessage: NSLocalizedString("GROUP_CREATED", comment: ""))
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                if model.groupImage != nil {
                    let data = UIImagePNGRepresentation(model.groupImage!)
                    let dataSource = DataSourceValue.dataSource(with: data!, fileExtension: "png")
                    // CLEANUP DURABLE - Replace with a durable operation e.g. `GroupCreateJob`, which creates
                    // an error in the thread if group creation fails
                    
                    self.messageSender.sendTemporaryAttachment(dataSource!, contentType: OWSMimeTypeImagePng, in: message, success: {
                        DispatchQueue.main.async {
                            SignalApp.shared().presentConversation(for: thread, action: .compose, animated: true)
                        }
                    }, failure: { (error) in
                        // Add an error message to the new group indicating
                        // that group creation didn't succeed.
                        let errorMessage = TSErrorMessage.init(timestamp: NSDate.ows_millisecondTimeStamp(), in: thread, failedMessageType: .groupCreationFailed)
                        errorMessage.save()
                        
                        DispatchQueue.main.async {
                            SignalApp.shared().presentConversation(for: thread, action: .compose, animated: true)
                        }
                    })
                } else {
                    self.messageSender.send(message, success: {
                        DispatchQueue.main.async {
                            SignalApp.shared().presentConversation(for: thread, action: .compose, animated: true)
                        }
                    }, failure: { (error) in
                        // Add an error message to the new group indicating
                        // that group creation didn't succeed.
                        let errorMessage = TSErrorMessage.init(timestamp: NSDate.ows_millisecondTimeStamp(), in: thread, failedMessageType: .groupCreationFailed)
                        errorMessage.save()
                        
                        DispatchQueue.main.async {
                            SignalApp.shared().presentConversation(for: thread, action: .compose, animated: true)
                        }
                    })
                }
            }
//        }
    }
    
    func makeGroup() -> TSGroupModel {
        let groupName = groupTitleTextView.text != nil && !groupTitleTextView.text!.isEmpty ? groupTitleTextView.text : "group #"
        
        var memberRecipientIds = [String]()
        for member in vinciAccounts {
            memberRecipientIds.append(member.recipientId)
        }
        
        // don't forget to add local contact to group
        if let localNumber = TSAccountManager.localNumber() {
            memberRecipientIds.append(localNumber)
        }
        
        return TSGroupModel.init(title: groupName, memberIds: memberRecipientIds, image: nil, groupId: groupId)
    }
    
    // MARK - Group Avatar
    @objc func showChangeAvatarUI() {
        avatarViewHelper.showChangeAvatarUI()
    }
    
    func updateAvatarView() {
        var groupAvatar = self.groupAvatar
        if groupAvatar == nil {
            let conversationColorName = TSGroupThread.defaultConversationColorName(forGroupId: groupId)
            groupAvatar = OWSGroupAvatarBuilder.defaultAvatar(forGroupId: groupId, conversationColorName: conversationColorName.rawValue, diameter: kLargeAvatarSize)
        }
        
        avatarView.image = groupAvatar
    }
    
    func updateBarButtonItems() {
        
        // Settings button.
        var settingsButton:UIBarButtonItem!
        
        // VINCI settings button with icon
        let image = UIImage(named: "vinciSettingsIcon")
        settingsButton = UIBarButtonItem.init(image: image, style: .plain, target: self, action: #selector(settingsButtonPressed))
        settingsButton.tintColor = UIColor.vinciBrandBlue
        settingsButton.accessibilityLabel = CommonStrings.openSettingsButton
        //        self.navigationItem.leftBarButtonItem = settingsButton
        //        SET_SUBVIEW_ACCESSIBILITY_IDENTIFIER(self, settingsButton);
        
        var rightBarButtons:[UIBarButtonItem] = []
        let addContactButton = UIBarButtonItem.init(title: "Next", style: .plain, target: self, action: #selector(newContactButtonPressed))
        rightBarButtons.append(addContactButton)
        //        rightBarButtons.append(UIBarButtonItem.init(barButtonSystemItem: .trash, target: self, action: #selector(trashButtonPressed)))
        
        //        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .compose, target: self, action: #selector(showNewConversationView))
        self.navigationItem.rightBarButtonItems = rightBarButtons
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showContactAppropriateViews()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func updateTableContent() {
        
        // vinci update
//        let searchText = searchBar.text ?? ""
//        vinciAccounts = contactsViewHelper.signalAccounts(matchingSearch: searchText)
//        collatedVinciAccounts = collation.partitionObjects(array: vinciAccounts,
//                                                           collationStringSelector: #selector(SignalAccount.stringForCollation)) as! [[SignalAccount]]
        
        sectionsMap.removeAll()
        sectionsMap[.sectionReminder] = hasVisibleReminders() ? 1 : 0
        sectionsMap[.sectionTitleRow] = 1
        sectionsMap[.sectionNotifications] = 0
        sectionsMap[.sectionSharedMedia] = 0
        sectionsMap[.sectionGroupMembersTitle] = 1
        sectionsMap[.sectionAddGroupMembers] = 0
        sectionsMap[.sectionGroupMembers] = vinciAccounts.count
        
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
        tableView.reloadData()
    }
    
    @objc func settingsButtonPressed() {
        let navigationController:OWSNavigationController = AppSettingsViewController.inModalNavigationController()
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func newContactButtonPressed() {
        let groupCompletionViewController = VinciGroupInfoViewController()
        //        let navigationController = OWSNavigationController(rootViewController: groupCompletionViewController)
        //        self.present(navigationController, animated: true, completion: nil)
        navigationController?.pushViewController(groupCompletionViewController, animated: true)
    }
    
    @objc func avatarTouched(sender: UIGestureRecognizer) {
        if sender.state == .recognized {
            showChangeAvatarUI()
        }
    }
}

extension VinciGroupInfoViewController : UITableViewDelegate {
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

extension VinciGroupInfoViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let sectionsCount:Int = VNGroupInfoSections.count
        return sectionsCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch defineSection(section: section) {
        case .sectionReminder:
            return sectionsMap[.sectionReminder] ?? 0
        case .sectionTitleRow:
            return sectionsMap[.sectionTitleRow] ?? 0
        case .sectionNotifications:
            return sectionsMap[.sectionNotifications] ?? 0
        case .sectionSharedMedia:
            return sectionsMap[.sectionSharedMedia] ?? 0
        case .sectionGroupMembersTitle:
            return sectionsMap[.sectionGroupMembersTitle] ?? 0
        case .sectionAddGroupMembers:
            return sectionsMap[.sectionAddGroupMembers] ?? 0
        case .sectionGroupMembers:
            return sectionsMap[.sectionGroupMembers] ?? 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch defineSection(section: indexPath.section) {
        case .sectionReminder:
            break
        case .sectionTitleRow:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "contactsTitleCell")
            if groupTitleTextView == nil {
                groupTitleTextView = UITextField(frame: CGRect.zero)
            }
            
            if groupTitleTextView.superview != nil {
                groupTitleTextView.removeFromSuperview()
            }
            
            if avatarView.superview != nil {
                avatarView.removeFromSuperview()
                avatarView.gestureRecognizers?.removeAll()
            }
            
            cell.contentView.addSubview(avatarView)
            
            avatarView.autoVCenterInSuperview()
            avatarView.autoPinLeading(toEdgeOf: cell.contentView, offset: 15.0)
            avatarView.autoSetDimensions(to: CGSize(width: CGFloat(kLargeAvatarSize), height: CGFloat(kLargeAvatarSize)))
            updateAvatarView()
            
            avatarView.isUserInteractionEnabled = true
            avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTouched(sender:))))
            
            groupTitleTextView.placeholder = "Group Name"
            groupTitleTextView.font = VinciStrings.regularFont.withSize(17.0)
            groupTitleTextView.textColor = Theme.primaryColor
            
            cell.contentView.addSubview(groupTitleTextView)
            groupTitleTextView.autoVCenterInSuperview()
            groupTitleTextView.autoPinLeading(toTrailingEdgeOf: avatarView, offset: 15.0)
            groupTitleTextView.autoPinTrailing(toEdgeOf: cell.contentView)
            
            cell.selectionStyle = .none
            
            return cell
        case .sectionNotifications:
            break
        case .sectionSharedMedia:
            break
        case .sectionGroupMembersTitle:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "contactsTitleCell")
            
            let titleLabel = InsetLabel()
            titleLabel.text = "Group members"
            titleLabel.font = VinciStrings.sectionTitleFont
            titleLabel.textColor = Theme.primaryColor
            
            cell.contentView.addSubview(titleLabel)
            titleLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16.0)
            titleLabel.autoPinLeadingToSuperviewMargin()
            
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0.0, left: tableView.frame.width, bottom: 0.0, right: 0.0)
            
            return cell
        case .sectionAddGroupMembers:
            break
        case .sectionGroupMembers:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "VinciContactViewCell", for: indexPath) as? VinciContactViewCell {
                let vinciAccount = vinciAccounts[indexPath.row]
                
                cell.configure(recipientId: vinciAccount.recipientId)
                cell.selectionStyle = .none
                
                cell.hideChecker(animated: false)
                
                return cell
            }
        default:
            break
        }
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "defaultCell")
        
        cell.selectionStyle = .none
        cell.separatorInset = UIEdgeInsets(top: 0.0, left: tableView.frame.width, bottom: 0.0, right: 0.0)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch defineSection(section: indexPath.section) {
        case .sectionTitleRow:
            return 80.0
        case .sectionGroupMembersTitle:
            return 64.0
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch defineSection(section: section) {
        case .sectionReminder:
            return nil
        case .sectionTitleRow:
            return nil
        case .sectionNotifications:
            return nil
        case .sectionSharedMedia:
            return nil
        case .sectionGroupMembersTitle:
            return nil
        case .sectionAddGroupMembers:
            return nil
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK : SearchBar delegate

extension VinciGroupInfoViewController : UISearchBarDelegate {
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTextDidChange()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchTextDidChange()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchTextDidChange()
    }
    
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        searchTextDidChange()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        searchTextDidChange()
    }
    
    func searchTextDidChange() {
        updateSearchPhoneNumbers()
        updateTableContent()
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

extension VinciGroupInfoViewController : ContactsViewHelperDelegate {
    
    func contactsViewHelperDidUpdateContacts() {
        updateTableContent()
        showContactAppropriateViews()
    }
    
    func shouldHideLocalNumber() -> Bool {
        return false
    }
}

extension VinciGroupInfoViewController : CNContactViewControllerDelegate {
    // dismiss CNContactViewController when pressed Done or Cancel
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK - AvatarViewHelperDelegate
extension VinciGroupInfoViewController : AvatarViewHelperDelegate {
    
    func avatarActionSheetTitle() -> String {
        return NSLocalizedString("NEW_GROUP_ADD_PHOTO_ACTION", comment: "Action Sheet title prompting the user for a group avatar")
    }
    
    func avatarDidChange(_ image: UIImage) {
        AssertIsOnMainThread()
        groupAvatar = image
    }
    
    func fromViewController() -> UIViewController {
        return self
    }
    
    func hasClearAvatarAction() -> Bool {
        return false
    }
}
