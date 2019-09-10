//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

@objc class VinciInviteFriendsViewController: VinciViewController {
    
    // MARK: Title Views
    let navigationBar = VinciTopMenuController(title: "")
    var navigationBarTopConstraint: NSLayoutConstraint!
    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    
    var searchResultsController: VinciContactsSearchResultsController!
    var hideSearchBarWhenScrolling = true
    
    var headerViewMaxHeight: CGFloat = 128.0
    let headerViewMinHeight: CGFloat = 42.0
    
    //
    
    var contactViewHelper: ContactsViewHelper!
    
    enum VinciContactsSection: Int {
        case sectionReminder = 0
        case sectionShareVinci = 1
        case sectionVinciContacts = 2
        case sectionGlobalVinciAccounts = 3
        case sectionVinciUndefined = 4
        
        static let count: Int = {
            var max: Int = 0
            while let _ = VinciContactsSection(rawValue: max) { max += 1 }
            return max-1 // why minus 1? i don't need Undefined section, but i need it to complete switch-cases
        }()
    }
    
    var nonVinciContactsView: UIView!
    
    var editModePanel: VinciInviteTabPanel!
    var editModePanelHeightConstraint: NSLayoutConstraint!
    var tabFrame: CGRect? {
        didSet {
            editModePanelHeightConstraint?.constant = self.tabFrame?.height ?? 0.0
        }
    }
    
    var collation: UILocalizedIndexedCollation!
    var modeWithCollation = true {
        didSet {
            updateTableContent()
        }
    }
    
    var searchBar: UISearchBar!
    var searchController: UISearchController!
    var isSearching = false
    
    // A list of possible phone numbers parsed from the search text as
    // E164 values.
    var searchPhoneNumbers = [String]()
    
    // data
    var vinciAccounts = [Contact]()
    var collatedVinciAccounts = [[Contact]]()
    var globalVinciAccounts = [Contact]()
    var sectionsMap = [VinciContactsSection:Int]()
    var selectedAccounts = [Contact]()
    
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
        
        self.title = "Invite Friends"
        contactsViewHelper = ContactsViewHelper(delegate: self)
        
        // Make sure we have requested contact access at this point if, e.g.
        // the user has no messages in their inbox and they choose to compose
        // a message.
        contactsViewHelper.contactsManager.requestSystemContactsOnce()
        
        collation = UILocalizedIndexedCollation.current()
        
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchBar = searchController.searchBar
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
        case VinciContactsSection.sectionShareVinci.rawValue:
            return VinciContactsSection.sectionShareVinci
        case VinciContactsSection.sectionVinciContacts.rawValue:
            return VinciContactsSection.sectionVinciContacts
        case VinciContactsSection.sectionGlobalVinciAccounts.rawValue:
            return VinciContactsSection.sectionGlobalVinciAccounts
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.titleType = .noTitle
        
        view.addSubview(navigationBar.view)
        navigationBarTopConstraint = navigationBar.pinToTop()
        
        headerViewMaxHeight = navigationBar.maxBarHeight
        
        if let topTitleView = navigationBar.topTitleView as? VinciTopMenuRowViewController {
            topTitleView.leftBarItems.append(UIBarButtonItem(title: "< Back", style: .plain, target: self, action: #selector(dismissViewController)))
            topTitleView.rightBarItems.append(UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(newContactButtonPressed)))
            
            topTitleView.titleViewLabel?.text = "Invite Friends"
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.register(VinciContactViewCell.self, forCellReuseIdentifier: "VinciContactViewCell")
        tableView.allowsMultipleSelection = true
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: navigationBar.view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        //        searchController = UISearchController(searchResultsController: nil)
        //        searchBar = searchController.searchBar
        
        searchBar.delegate = self
        searchBar.placeholder = "Search for contacts or usernames"
        
        // no large title here!
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
            navigationItem.largeTitleDisplayMode = .never
            
            navigationItem.searchController = searchController
        }
        
        // VINCI edit panel
        editModePanel = VinciInviteTabPanel()
        editModePanel.backgroundColor = Theme.navbarBackgroundColor
        editModePanel.alpha = 1.0
        editModePanel.isUserInteractionEnabled = false
        editModePanel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editModePanel)
        
        if editModePanelHeightConstraint == nil {
            editModePanelHeightConstraint = editModePanel.heightAnchor.constraint(equalToConstant: tabFrame?.height ?? 0.0)
        } else {
            editModePanelHeightConstraint.constant = tabFrame?.height ?? 0.0
        }

        editModePanelHeightConstraint.isActive = true
        editModePanel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        editModePanel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        editModePanel.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        updateTableContent()
        self.updateBarButtonItems()
        self.applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationController?.tabBarController?.tabBar.isHidden = false
        
        if #available(iOS 11.0, *) {
            self.navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            // Fallback on earlier versions
        }
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
////        self.navigationItem.leftBarButtonItem = settingsButton
//        //        SET_SUBVIEW_ACCESSIBILITY_IDENTIFIER(self, settingsButton);
//
//        var rightBarButtons:[UIBarButtonItem] = []
//        let selectAllButton = UIBarButtonItem.init(title: "Select All", style: .plain, target: self, action: #selector(newContactButtonPressed))
//        rightBarButtons.append(selectAllButton)
//        //        rightBarButtons.append(UIBarButtonItem.init(barButtonSystemItem: .trash, target: self, action: #selector(trashButtonPressed)))
//
//        //        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .compose, target: self, action: #selector(showNewConversationView))
//        self.navigationItem.rightBarButtonItems = rightBarButtons
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
            navigationController?.navigationBar.prefersLargeTitles = true
            
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // Fallback on earlier versions
        }
        
        showContactAppropriateViews()
    }
    
    @objc func dismissViewController() {
        navigationController?.popViewController(animated: true)
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
        
        vinciAccounts.removeAll()
        let allContacts = contactsViewHelper.contactsManager.allContacts
        for contact in allContacts {
            if !contact.isSignalContact {
                vinciAccounts.append(contact)
            }
        }
        
        collatedVinciAccounts = collation.partitionObjects(array: vinciAccounts,
                                                           collationStringSelector: #selector(Contact.stringForCollation)) as! [[Contact]]
        
        sectionsMap.removeAll()
        sectionsMap[.sectionReminder] = hasVisibleReminders() ? 1 : 0
        sectionsMap[.sectionVinciContacts] = collatedVinciAccounts.count
        sectionsMap[.sectionGlobalVinciAccounts] = 0
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
            sectionsMap[.sectionShareVinci] = 1
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
        selectedAccounts.removeAll()
        selectedAccounts.append(contentsOf: vinciAccounts)
        
        tableView.reloadData()
    }
}

extension Contact {
    @objc func stringForCollation() -> String {
//        if let contactsManager = Environment.shared.contactsManager {
//            return contactsManager.comparableName(for: self)
//        }

//        return "#"
        
        return self.fullName
    }
}

extension VinciInviteFriendsViewController : UITableViewDelegate {
    
}

extension VinciInviteFriendsViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var sectionsCount:Int = VinciContactsSection.count - 2 // initial value = - contacts section
        
        if !isSearching {
            sectionsCount += collatedVinciAccounts.count + globalVinciAccounts.count
        } else {
            sectionsCount += 2 // only contacts section + global contacts section, without collation
        }
        
        return sectionsCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch defineSection(section: section) {
        case .sectionReminder:
            return sectionsMap[.sectionReminder] ?? 0
        case .sectionShareVinci:
            if !isSearching {
                return sectionsMap[.sectionShareVinci] ?? 0
            } else {
                return 0
            }
        case .sectionVinciContacts:
            // ok, define true section of contacts
            let contactSection = section - VinciContactsSection.sectionVinciContacts.rawValue
            if !isSearching {
                let collatedSection = collatedVinciAccounts[contactSection]
                let numberOfAccounts = collatedSection.count
                return numberOfAccounts
            } else {
                return vinciAccounts.count
            }
        case .sectionGlobalVinciAccounts:
            if !isSearching {
                return 0
            } else {
                let numberOfAccounts = sectionsMap[.sectionGlobalVinciAccounts] ?? 0
                return numberOfAccounts
            }
        default:
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VinciContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            let minGlobalVinciAccountsSection = maxContactsSection
            let maxGlobalVinciAccountsSection = ( sectionsMap[.sectionGlobalVinciAccounts] ?? 0 ) + minGlobalVinciAccountsSection
            
            if section > minContactsSection && section < maxContactsSection {
                // ok, define true section of contacts
                let contactSection = section - minContactsSection
                if !isSearching {
                    let collatedSection = collatedVinciAccounts[contactSection]
                    let numberOfAccounts = collatedSection.count
                    return numberOfAccounts
                } else {
                    return vinciAccounts.count
                }
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
        case .sectionShareVinci:
            let cell = UITableViewCell(style: .default, reuseIdentifier: "shareVinciCell")
            cell.textLabel?.text = "Share Vinci"
            cell.textLabel?.font = VinciStrings.regularFont.withSize(16.0)
            cell.textLabel?.textColor = UIColor.vinciBrandBlue
            cell.imageView?.contentMode = .center
            cell.imageView?.image = UIImage(named: "shareVinci")?.withAlignmentRectInsets(UIEdgeInsets(top: 0.0, left: 6.0, bottom: 0.0, right: 6.0))
            return cell
        case .sectionVinciContacts:
            let reuseIdentifier = "VinciContactViewCell"
            if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? VinciContactViewCell {
                let vinciAccount: Contact!
                if !isSearching {
                    // ok, define true section of contacts
                    let contactSection = indexPath.section - VinciContactsSection.sectionVinciContacts.rawValue
                    let collatedSection = collatedVinciAccounts[contactSection]
                    vinciAccount = collatedSection[indexPath.row]
                } else {
                    vinciAccount = vinciAccounts[indexPath.row]
                }
                
//                cell.configure(recipientId: vinciAccount.cnContactId)
                cell.configure(contact: vinciAccount)
//                cell.textLabel?.text = vinciAccount.fullName
                
                cell.setSelected(selectedAccounts.contains(vinciAccount), animated: true)
                cell.selectionStyle = .none
                
                return cell
            }
        default:
            let section = indexPath.section
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VinciContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            let minGlobalVinciAccountsSection = maxContactsSection
            let maxGlobalVinciAccountsSection = ( sectionsMap[.sectionGlobalVinciAccounts] ?? 0 ) + minGlobalVinciAccountsSection
            
            if section > minContactsSection && section < maxContactsSection {
                // ok, define true section of contacts
                let contactSection = section - minContactsSection
                let newIndexPath = IndexPath(row: indexPath.row, section: contactSection)
                let reuseIdentifier = "VinciContactViewCell"
                if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: newIndexPath) as? VinciContactViewCell {
                    
                    let vinciAccount: Contact!
                    if !isSearching {
                        let collatedSection = collatedVinciAccounts[newIndexPath.section]
                        vinciAccount = collatedSection[newIndexPath.row]
                    } else {
                        vinciAccount = vinciAccounts[newIndexPath.row]
                    }
                    
//                    cell.configure(recipientId: vinciAccount.cnContactId)
                    cell.configure(contact: vinciAccount)
//                    cell.textLabel?.text = vinciAccount.fullName
                    
                    cell.setSelected(selectedAccounts.contains(vinciAccount), animated: true)
                    cell.selectionStyle = .none
                    
                    return cell
                }
            } else if section > minGlobalVinciAccountsSection && section < maxGlobalVinciAccountsSection {
                if !isSearching {
                    return UITableViewCell()
                } else {
                    let cell = UITableViewCell(style: .default, reuseIdentifier: "globalVinciAccountCell")
                    cell.backgroundColor = UIColor.magenta
                    cell.textLabel?.text = "Global Contact"
                    
                    return cell
                }
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch defineSection(section: section) {
        case .sectionVinciContacts:
            let contactSection = section - VinciContactsSection.sectionVinciContacts.rawValue
            if !isSearching {
                if modeWithCollation {
                    let collatedSection = collatedVinciAccounts[contactSection]
                    if collatedSection.count > 0 {
                        return collation.sectionTitles[contactSection]
                    }
                }
            } else {
                return "Contacts"
            }
        case .sectionGlobalVinciAccounts:
            if !isSearching {
                return nil
            } else {
                return "Global Contacts"
            }
        default:
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VinciContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            let minGlobalVinciAccountsSection = maxContactsSection
            let maxGlobalVinciAccountsSection = ( sectionsMap[.sectionGlobalVinciAccounts] ?? 0 ) + minGlobalVinciAccountsSection
            
            if section > minContactsSection && section < maxContactsSection {
                let contactSection = section - VinciContactsSection.sectionVinciContacts.rawValue
                if !isSearching {
                    if modeWithCollation {
                        let collatedSection = collatedVinciAccounts[contactSection]
                        if collatedSection.count > 0 {
                            return collation.sectionTitles[contactSection]
                        }
                    }
                }
            } else if section > minGlobalVinciAccountsSection && section < maxGlobalVinciAccountsSection {
                if !isSearching {
                    return nil
                } else {
                    return "Global Contacts"
                }
            }
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch defineSection(section: indexPath.section) {
        case .sectionVinciContacts:
            if let cell = tableView.cellForRow(at: indexPath) as? VinciContactViewCell {
                let vinciAccount: Contact!
                if !isSearching {
                    // ok, define true section of contacts
                    let contactSection = indexPath.section - VinciContactsSection.sectionVinciContacts.rawValue
                    let collatedSection = collatedVinciAccounts[contactSection]
                    vinciAccount = collatedSection[indexPath.row]
                } else {
                    vinciAccount = vinciAccounts[indexPath.row]
                }
                
                if !selectedAccounts.contains(vinciAccount) {
                    selectedAccounts.append(vinciAccount)
                }
            }
            
            editModePanel.setCount(count: selectedAccounts.count)
            
            return
            
        default:
            let section = indexPath.section
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VinciContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            let minGlobalVinciAccountsSection = maxContactsSection
            let maxGlobalVinciAccountsSection = ( sectionsMap[.sectionGlobalVinciAccounts] ?? 0 ) + minGlobalVinciAccountsSection
            
            if section > minContactsSection && section < maxContactsSection {
                // ok, define true section of contacts
                let contactSection = section - minContactsSection
                let newIndexPath = IndexPath(row: indexPath.row, section: contactSection)
                if let cell = tableView.cellForRow(at: indexPath) as? VinciContactViewCell {
                    
                    let vinciAccount: Contact!
                    if !isSearching {
                        let collatedSection = collatedVinciAccounts[newIndexPath.section]
                        vinciAccount = collatedSection[newIndexPath.row]
                    } else {
                        vinciAccount = vinciAccounts[newIndexPath.row]
                    }
                    
                    if !selectedAccounts.contains(vinciAccount) {
                        selectedAccounts.append(vinciAccount)
                    }
                }
                
                editModePanel.setCount(count: selectedAccounts.count)
                
                return
                
            } else if section > minGlobalVinciAccountsSection && section < maxGlobalVinciAccountsSection {
                if !isSearching {
                    return
                } else {
                    return
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        switch defineSection(section: indexPath.section) {
        case .sectionVinciContacts:
            if let cell = tableView.cellForRow(at: indexPath) as? VinciContactViewCell {
                let vinciAccount: Contact!
                if !isSearching {
                    // ok, define true section of contacts
                    let contactSection = indexPath.section - VinciContactsSection.sectionVinciContacts.rawValue
                    let collatedSection = collatedVinciAccounts[contactSection]
                    vinciAccount = collatedSection[indexPath.row]
                } else {
                    vinciAccount = vinciAccounts[indexPath.row]
                }
                
                if selectedAccounts.contains(vinciAccount) {
                    selectedAccounts.remove(at: selectedAccounts.index(of: vinciAccount) ?? -1)
                }
            }
            
            editModePanel.setCount(count: selectedAccounts.count)
            return
            
        default:
            let section = indexPath.section
            // here is because of numbered sections ( Contacts for example )
            let minContactsSection = VinciContactsSection.sectionVinciContacts.rawValue
            let maxContactsSection = ( sectionsMap[.sectionVinciContacts] ?? 0 ) + minContactsSection
            
            let minGlobalVinciAccountsSection = maxContactsSection
            let maxGlobalVinciAccountsSection = ( sectionsMap[.sectionGlobalVinciAccounts] ?? 0 ) + minGlobalVinciAccountsSection
            
            if section > minContactsSection && section < maxContactsSection {
                // ok, define true section of contacts
                let contactSection = section - minContactsSection
                let newIndexPath = IndexPath(row: indexPath.row, section: contactSection)
                if let cell = tableView.cellForRow(at: indexPath) as? VinciContactViewCell {
                    
                    let vinciAccount: Contact!
                    if !isSearching {
                        let collatedSection = collatedVinciAccounts[newIndexPath.section]
                        vinciAccount = collatedSection[newIndexPath.row]
                    } else {
                        vinciAccount = vinciAccounts[newIndexPath.row]
                    }
                    
                    if selectedAccounts.contains(vinciAccount) {
                        selectedAccounts.remove(at: selectedAccounts.index(of: vinciAccount) ?? -1)
                    }
                }
                
                editModePanel.setCount(count: selectedAccounts.count)
                return
                
            } else if section > minGlobalVinciAccountsSection && section < maxGlobalVinciAccountsSection {
                if !isSearching {
                    return
                } else {
                    return
                }
            }
        }
    }
}

// MARK : SearchBar delegate

extension VinciInviteFriendsViewController : UISearchBarDelegate {
    
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

extension VinciInviteFriendsViewController : ContactsViewHelperDelegate {
    
    func contactsViewHelperDidUpdateContacts() {
        updateTableContent()
        showContactAppropriateViews()
    }
    
    func shouldHideLocalNumber() -> Bool {
        return false
    }
}

//public extension DispatchQueue {
//
//    private static var _onceTracker = [String]()
//
//    /**
//     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
//     only execute the code once even in the presence of multithreaded calls.
//
//     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
//     - parameter block: Block to execute once
//     */
//    class func once(token: String, block:()->Void) {
//        objc_sync_enter(self); defer { objc_sync_exit(self) }
//
//        if _onceTracker.contains(token) {
//            return
//        }
//
//        _onceTracker.append(token)
//        block()
//    }
//}

//extension UILocalizedIndexedCollation {
//    // func for partition array in sections
//    func partitionObjects(array:[AnyObject], collationStringSelector:Selector) -> [AnyObject] {
//        var unsortedSections = [[AnyObject]]()
//        // 1. Create a array to hold the data for each section
//        for _ in self.sectionTitles {
//            unsortedSections.append([]) //appending an empty array
//        }
//        // 2. put each objects into a section
//        for item in array {
//            let index:Int = self.section(for: item, collationStringSelector:collationStringSelector)
//            unsortedSections[index].append(item)
//        }
//        // 3. sort the array of each sections
//        var sections = [AnyObject]()
//        for index in 0 ..< unsortedSections.count {
//            sections.append(self.sortedArray(from: unsortedSections[index], collationStringSelector: collationStringSelector) as AnyObject)
//        }
//        return sections
//    }
//}

extension VinciInviteFriendsViewController : CNContactViewControllerDelegate {
    // dismiss CNContactViewController when pressed Done or Cancel
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        self.dismiss(animated: true, completion: nil)
    }
}
