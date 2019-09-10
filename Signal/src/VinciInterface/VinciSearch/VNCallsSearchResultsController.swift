//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
class VNCallsSearchResultsController: UIViewController {
    
    @objc
    public weak var delegate: VinciSearchResultsViewDelegate?
    
    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    var refreshTimer: Timer?
    
    @objc
    public var searchText = "" {
        didSet {
            AssertIsOnMainThread()
            
            // Use a slight delay to debounce updates.
            refreshSearchResults()
        }
    }
    
    var searchResultSet = [SignalAccount]()
    var contactsViewHelper: ContactsViewHelper!
    
    enum SearchSection: Int {
        case noResults
        case contacts
    }
    
    private var hasThemeChanged = false
    
    var blockListCache: BlockListCache!
    
    // MARK: View Lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    func commonInit() {
        
        contactsViewHelper = ContactsViewHelper(delegate: self)
        
        // Make sure we have requested contact access at this point if, e.g.
        // the user has no messages in their inbox and they choose to compose
        // a message.
        contactsViewHelper.contactsManager.requestSystemContactsOnce()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        blockListCache = BlockListCache()
        blockListCache.startObservingAndSyncState(delegate: self)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        tableView.separatorColor = Theme.cellSeparatorColor
        
        tableView.register(VinciEmptySearchResultCell.self, forCellReuseIdentifier: VinciEmptySearchResultCell.reuseIdentifier)
        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: ContactTableViewCell.reuseIdentifier())
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(uiDatabaseModified),
                                               name: .OWSUIDatabaseConnectionDidUpdate,
                                               object: OWSPrimaryStorage.shared().dbNotificationObject)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(themeDidChange),
                                               name: NSNotification.Name.ThemeDidChange,
                                               object: nil)
        
        tableView.tableFooterView = UIView()
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
        
        applyTheme()
        updateSeparators()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard hasThemeChanged else {
            return
        }
        hasThemeChanged = false
        
        applyTheme()
        self.tableView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc internal func uiDatabaseModified(notification: NSNotification) {
        AssertIsOnMainThread()
        
        refreshSearchResults()
    }
    
    @objc internal func themeDidChange(notification: NSNotification) {
        AssertIsOnMainThread()
        
        applyTheme()
        self.tableView.reloadData()
        
        hasThemeChanged = true
    }
    
    private func applyTheme() {
        AssertIsOnMainThread()
        
        self.view.backgroundColor = Theme.backgroundColor
        self.tableView.backgroundColor = Theme.backgroundColor
    }
    
    private func updateSeparators() {
        AssertIsOnMainThread()
        
        self.tableView.separatorStyle = (searchResultSet.isEmpty
            ? UITableViewCell.SeparatorStyle.none
            : UITableViewCell.SeparatorStyle.singleLine)
    }
}

// MARK: UITableViewDelegate
extension VNCallsSearchResultsController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let searchSection = SearchSection(rawValue: indexPath.section) else {
            owsFailDebug("unknown section selected.")
            return
        }
        
        switch searchSection {
        case .noResults:
            owsFailDebug("shouldn't be able to tap 'no results' section")
        case .contacts:
            let sectionResults = searchResultSet
            guard let searchResult = sectionResults[safe: indexPath.row] else {
                owsFailDebug("unknown row selected.")
                return
            }
            
            delegate?.didSelect(rowWith: searchResult)
        }
    }
}

// MARK: UITableViewDataSource
extension VNCallsSearchResultsController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let searchSection = SearchSection(rawValue: section) else {
            owsFailDebug("unknown section: \(section)")
            return 0
        }
        
        switch searchSection {
        case .noResults:
            return searchResultSet.isEmpty ? 1 : 0
        case .contacts:
            return searchResultSet.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let searchSection = SearchSection(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch searchSection {
        case .noResults:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: VinciEmptySearchResultCell.reuseIdentifier) as? VinciEmptySearchResultCell else {
                owsFailDebug("cell was unexpectedly nil")
                return UITableViewCell()
            }
            
            guard indexPath.row == 0 else {
                owsFailDebug("searchResult was unexpected index")
                return UITableViewCell()
            }
            
            OWSTableItem.configureCell(cell)
            
            let searchText = self.searchText
            cell.configure(searchText: searchText, size: tableView.frame.size)
            cell.selectionStyle = .none
            return cell
        case .contacts:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier()) as? ContactTableViewCell else {
                owsFailDebug("cell was unexpectedly nil")
                return UITableViewCell()
            }
            
            guard let signalAccount = self.searchResultSet[safe: indexPath.row] else {
                owsFailDebug("searchResult was unexpectedly nil")
                return UITableViewCell()
            }
            cell.configure(withRecipientId: signalAccount.recipientId)
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard nil != self.tableView(tableView, titleForHeaderInSection: section) else {
            return 0
        }
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = self.tableView(tableView, titleForHeaderInSection: section) else {
            return nil
        }
        
        let label = UILabel()
        label.textColor = Theme.primaryColor
        label.text = title
        label.font = VinciStrings.sectionTitleFont
        label.tag = section
        
        let hMargin: CGFloat = 15
        let vMargin: CGFloat = 4
        let wrapper = UIView()
        wrapper.backgroundColor = Theme.backgroundColor
        wrapper.addSubview(label)
        label.autoPinWidthToSuperview(withMargin: hMargin)
        label.autoPinHeightToSuperview(withMargin: vMargin)
        
        return wrapper
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let searchSection = SearchSection(rawValue: section) else {
            owsFailDebug("unknown section: \(section)")
            return nil
        }
        
        switch searchSection {
        case .noResults:
            return nil
        case .contacts:
            if searchResultSet.count > 0 {
                return "Contacts"
            } else {
                return nil
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

// MARK: BlockListCacheDelegate
extension VNCallsSearchResultsController : BlockListCacheDelegate {
    
    func blockListCacheDidUpdate(_ blocklistCache: BlockListCache) {
        refreshSearchResults()
    }
    
    // MARK: Update Search Results
    
    private func refreshSearchResults() {
        AssertIsOnMainThread()
        
        guard !searchResultSet.isEmpty else {
            // To avoid incorrectly showing the "no results" state,
            // always search immediately if the current result set is empty.
            refreshTimer?.invalidate()
            refreshTimer = nil
            
            updateSearchResults(searchText: searchText)
            return
        }
        
        if refreshTimer != nil {
            // Don't start a new refresh timer if there's already one active.
            return
        }
        
        refreshTimer?.invalidate()
        refreshTimer = WeakTimer.scheduledTimer(timeInterval: 0.1, target: self, userInfo: nil, repeats: false) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.updateSearchResults(searchText: strongSelf.searchText)
            strongSelf.refreshTimer = nil
        }
    }
    
    private func updateSearchResults(searchText: String) {
        guard searchText.stripped.count > 0 else {
            self.searchResultSet = []
            self.tableView.reloadData()
            return
        }
        
        searchResultSet = contactsViewHelper.signalAccounts(matchingSearch: searchText)
        tableView.reloadData()
    }
}

// MARK: - UIScrollViewDelegate
extension VNCallsSearchResultsController : UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.conversationSearchViewWillBeginDragging()
    }
    
    // MARK: -
    
    private func isBlocked(thread: ThreadViewModel) -> Bool {
        return self.blockListCache.isBlocked(thread: thread.threadRecord)
    }
}

extension VNCallsSearchResultsController : ContactsViewHelperDelegate {
    
    func contactsViewHelperDidUpdateContacts() {
        updateSearchResults(searchText: self.searchText)
    }
    
    func shouldHideLocalNumber() -> Bool {
        return false
    }
}
