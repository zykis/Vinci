//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

class VinciGroupInviteMembersViewCell: UITableViewCell {
    
    static let reuseIdentifier = "VinciGroupInviteMembersViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textLabel?.font = VinciStrings.regularFont.withSize(13.0)
        textLabel?.textColor = UIColor.gray
        textLabel?.lineBreakMode = .byWordWrapping
        textLabel?.numberOfLines = 0
        
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    public func configure(vinciAccounts:[SignalAccount]) {
        if vinciAccounts.count == 0 {
            textLabel?.attributedText = nil
            textLabel?.text = "Whom would you like to message?"
        } else {
            let membersText = NSMutableAttributedString(string: "")
            for vinciAccount in vinciAccounts {
                let contactName = vinciAccount.contactFullName()
                let recipientId = vinciAccount.recipientId
                let nameString = NSAttributedString(string: "\(contactName ?? recipientId), ")
                membersText.append(nameString)
            }
            textLabel?.attributedText = membersText.attributedSubstring(from: NSRange(location: 0, length: membersText.length-2))
        }
    }
}


@objc class VinciGroupMembersViewController: VinciViewController {
    
    let navigationBar = VinciTopMenuController(title: "New Group")
    var navigationBarTopConstraint: NSLayoutConstraint!
    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    
    var searchResultsController: VinciContactsSearchResultsController!
    var hideSearchBarWhenScrolling = true
    
    var headerViewMaxHeight: CGFloat = 128.0
    let headerViewMinHeight: CGFloat = 42.0
    
    enum VinciContactsSection: Int {
        case sectionReminder = 0
        case sectionInviteFriends = 1
        case sectionVinciContactsTitle = 2
        case sectionVinciContacts = 3
        case sectionVinciUndefined = 4
        
        static let count: Int = {
            var max: Int = 0
            while let _ = VinciContactsSection(rawValue: max) { max += 1 }
            
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
    
    var searchBar: UISearchBar!
    
    // A list of possible phone numbers parsed from the search text as
    // E164 values.
    var searchPhoneNumbers = [String]()
    
    // data
    var vinciAccounts = [SignalAccount]()
    var collatedVinciAccounts = [[SignalAccount]]()
    var selectedVinciAccounts = [SignalAccount]()
    var sectionsMap = [VinciContactsSection:Int]()
    
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
    
    func commonInit() {
        contactsViewHelper = ContactsViewHelper(delegate: self)
        
        // Make sure we have requested contact access at this point if, e.g.
        // the user has no messages in their inbox and they choose to compose
        // a message.
        contactsViewHelper.contactsManager.requestSystemContactsOnce()
        collation = UILocalizedIndexedCollation.current()
        
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
    
    func defineSection(section: Int) -> VinciContactsSection {
        switch section {
        case VinciContactsSection.sectionReminder.rawValue:
            return VinciContactsSection.sectionReminder
        case VinciContactsSection.sectionInviteFriends.rawValue:
            return VinciContactsSection.sectionInviteFriends
        case VinciContactsSection.sectionVinciContactsTitle.rawValue:
            return VinciContactsSection.sectionVinciContactsTitle
        case VinciContactsSection.sectionVinciContacts.rawValue:
            return VinciContactsSection.sectionVinciContacts
        default:
            return VinciContactsSection.sectionVinciUndefined
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
            topTitleView.rightBarItems.append(UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(createGroupChatWithMembers)))
            
            if let nextButtonItem = topTitleView.rightBarItemStack.arrangedSubviews[0] as? UIButton {
                nextButton = nextButtonItem
                nextButton.isEnabled = false
            }
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
    
    func updateBarButtonItems() {
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
        let searchText = searchBar.text ?? ""
        vinciAccounts = contactsViewHelper.signalAccounts(matchingSearch: searchText)
        collatedVinciAccounts = collation.partitionObjects(array: vinciAccounts,
                                                           collationStringSelector: #selector(SignalAccount.stringForCollation)) as! [[SignalAccount]]
        
        sectionsMap.removeAll()
        sectionsMap[.sectionReminder] = hasVisibleReminders() ? 1 : 0
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
            sectionsMap[.sectionVinciContactsTitle] = vinciAccounts.count == 0 ? 0 : 1
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
    
    func updateGroupMembers() {
        inviteGroupMembersViewCell.configure(vinciAccounts: selectedVinciAccounts)
        nextButton?.isEnabled = selectedVinciAccounts.count > 0 ? true : false
    }
    
    @objc func createGroupChatWithMembers() {
        let groupInfoViewController = VinciGroupInfoViewController.init(groupMembers: selectedVinciAccounts)
        navigationController?.pushViewController(groupInfoViewController, animated: true)
    }
}

extension VinciGroupMembersViewController : UITableViewDelegate {
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

extension VinciGroupMembersViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sectionsCount:Int = VinciContactsSection.count - 1 // initial value = - contacts section
        sectionsCount += collatedVinciAccounts.count
        
        return sectionsCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch defineSection(section: section) {
        case .sectionReminder:
            return sectionsMap[.sectionReminder] ?? 0
        case .sectionInviteFriends:
            return sectionsMap[.sectionInviteFriends] ?? 0
        case .sectionVinciContactsTitle:
            return sectionsMap[.sectionVinciContactsTitle] ?? 0
        default:
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VinciContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            let minGlobalVinciAccountsSection = maxContactsSection
            let maxGlobalVinciAccountsSection = minGlobalVinciAccountsSection
            
            if section > minContactsSection && section < maxContactsSection {
                // ok, define true section of contacts
                let contactSection = section - minContactsSection
                let collatedSection = collatedVinciAccounts[contactSection]
                let numberOfAccounts = collatedSection.count
                return numberOfAccounts
            } else if section > minGlobalVinciAccountsSection && section < maxGlobalVinciAccountsSection {
                
            }
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch defineSection(section: indexPath.section) {
        case .sectionReminder:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "reminderCell")
            cell.backgroundColor = UIColor.red
            return cell
        case .sectionInviteFriends:
            inviteGroupMembersViewCell.configure(vinciAccounts: selectedVinciAccounts)
            return inviteGroupMembersViewCell
        case .sectionVinciContactsTitle:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "contactsTitleCell")
            
            let titleLabel = InsetLabel()
            titleLabel.text = "Contacts"
            titleLabel.font = VinciStrings.sectionTitleFont
            titleLabel.textColor = Theme.primaryColor
            
            cell.contentView.addSubview(titleLabel)
            titleLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16.0)
            titleLabel.autoPinLeadingToSuperviewMargin()
            
            cell.selectionStyle = .none
            
            return cell
        default:
            let section = indexPath.section
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VinciContactsSection.sectionVinciContacts.rawValue
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
                    cell.selectionStyle = .none
                    
                    cell.checker.setState(checked: false, animated: false)
                    
                    return cell
                }
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch defineSection(section: indexPath.section) {
        case .sectionReminder:
            return UITableViewAutomaticDimension
        case .sectionInviteFriends:
            return UITableViewAutomaticDimension
        case .sectionVinciContactsTitle:
            return 80.0
        case .sectionVinciContacts:
            return UITableViewAutomaticDimension
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch defineSection(section: section) {
        case .sectionVinciContacts:
            let contactSection = section - VinciContactsSection.sectionVinciContacts.rawValue
            if modeWithCollation {
                let collatedSection = collatedVinciAccounts[contactSection]
                if collatedSection.count > 0 {
                    return collation.sectionTitles[contactSection]
                }
            }
        default:
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VinciContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            if section > minContactsSection && section < maxContactsSection {
                let contactSection = section - VinciContactsSection.sectionVinciContacts.rawValue
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
//        tableView.deselectRow(at: indexPath, animated: true)
        
        switch defineSection(section: indexPath.section) {
        case .sectionReminder:
            break
        case .sectionInviteFriends:
            break
        case .sectionVinciContactsTitle:
            break
        default:
            let section = indexPath.section
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VinciContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            if section > minContactsSection && section < maxContactsSection {
                // ok, define true section of contacts
                let contactSection = section - minContactsSection
                let newIndexPath = IndexPath(row: indexPath.row, section: contactSection)
                if let cell = tableView.cellForRow(at: indexPath) as? VinciContactViewCell {
                    let vinciAccount: SignalAccount!
                    
                    let collatedSection = collatedVinciAccounts[newIndexPath.section]
                    vinciAccount = collatedSection[newIndexPath.row]
                    
                    if !selectedVinciAccounts.contains(vinciAccount) {
                        selectedVinciAccounts.append(vinciAccount)
                        cell.checker.setState(checked: true, animated: true)
                    } else {
                        selectedVinciAccounts.remove(at: selectedVinciAccounts.index(of: vinciAccount) ?? 0)
                        cell.checker.setState(checked: false, animated: true)
                    }
                }
            }
            
            updateGroupMembers()
        }
    }
}

// MARK : SearchBar delegate

extension VinciGroupMembersViewController : UISearchBarDelegate {
    
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

extension VinciGroupMembersViewController : ContactsViewHelperDelegate {
    
    func contactsViewHelperDidUpdateContacts() {
        updateTableContent()
        showContactAppropriateViews()
    }
    
    func shouldHideLocalNumber() -> Bool {
        return false
    }
}

extension VinciGroupMembersViewController : CNContactViewControllerDelegate {
    // dismiss CNContactViewController when pressed Done or Cancel
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        self.dismiss(animated: true, completion: nil)
    }
}
