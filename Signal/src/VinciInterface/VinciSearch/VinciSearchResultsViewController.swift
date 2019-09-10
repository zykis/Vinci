//
//  Copyright (c) 2019 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc
protocol VinciSearchResultsViewDelegate: class {
    func conversationSearchViewWillBeginDragging()
    func didSelect(rowWith vinciAccount: SignalAccount)
}

@objc
class VinciSearchResultsViewController: UITableViewController, BlockListCacheDelegate {
    
    @objc
    public weak var delegate: VinciSearchResultsViewDelegate?
    
    @objc
    public var searchText = "" {
        didSet {
            AssertIsOnMainThread()
            
            // Use a slight delay to debounce updates.
            refreshSearchResults()
        }
    }
    
    var searchResultSet: HomeScreenSearchResultSet = HomeScreenSearchResultSet.empty {
        didSet {
            AssertIsOnMainThread()
            updateSeparators()
        }
    }
    
    var uiDatabaseConnection: YapDatabaseConnection {
        return OWSPrimaryStorage.shared().uiDatabaseConnection
    }
    
    var searcher: FullTextSearcher {
        return FullTextSearcher.shared
    }
    
    private var contactsManager: OWSContactsManager {
        return Environment.shared.contactsManager
    }
    
    enum SearchSection: Int {
        case noResults
        case conversations
        case contacts
        case messages
    }
    
    private var hasThemeChanged = false
    
    var blockListCache: BlockListCache!
    
    // MARK: View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        blockListCache = BlockListCache()
        blockListCache.startObservingAndSyncState(delegate: self)
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        tableView.separatorColor = Theme.cellSeparatorColor
        
        tableView.register(VinciEmptySearchResultCell.self, forCellReuseIdentifier: VinciEmptySearchResultCell.reuseIdentifier)
        tableView.register(HomeViewCell.self, forCellReuseIdentifier: HomeViewCell.cellReuseIdentifier())
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
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let searchSection = SearchSection(rawValue: indexPath.section) else {
            owsFailDebug("unknown section selected.")
            return
        }
        
        switch searchSection {
        case .noResults:
            owsFailDebug("shouldn't be able to tap 'no results' section")
        case .conversations:
            let sectionResults = searchResultSet.conversations
            guard let searchResult = sectionResults[safe: indexPath.row] else {
                owsFailDebug("unknown row selected.")
                return
            }
            
            let thread = searchResult.thread
            SignalApp.shared().presentConversation(for: thread.threadRecord, action: .compose, animated: true)
            
        case .contacts:
            let sectionResults = searchResultSet.contacts
            guard let searchResult = sectionResults[safe: indexPath.row] else {
                owsFailDebug("unknown row selected.")
                return
            }
            
            SignalApp.shared().presentConversation(forRecipientId: searchResult.recipientId, action: .compose, animated: true)
            
        case .messages:
            let sectionResults = searchResultSet.messages
            guard let searchResult = sectionResults[safe: indexPath.row] else {
                owsFailDebug("unknown row selected.")
                return
            }
            
            let thread = searchResult.thread
            SignalApp.shared().presentConversation(for: thread.threadRecord,
                                                   action: .none,
                                                   focusMessageId: searchResult.messageId,
                                                   animated: true)
        }
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let searchSection = SearchSection(rawValue: section) else {
            owsFailDebug("unknown section: \(section)")
            return 0
        }
        
        switch searchSection {
        case .noResults:
            return searchResultSet.isEmpty ? 1 : 0
        case .conversations:
            return searchResultSet.conversations.count
        case .contacts:
            return searchResultSet.contacts.count
        case .messages:
            return searchResultSet.messages.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
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
            
            let searchText = self.searchResultSet.searchText
            cell.configure(searchText: searchText, size: tableView.frame.size)
            cell.selectionStyle = .none
            return cell
        case .conversations:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeViewCell.cellReuseIdentifier()) as? HomeViewCell else {
                owsFailDebug("cell was unexpectedly nil")
                return UITableViewCell()
            }
            
            guard let searchResult = self.searchResultSet.conversations[safe: indexPath.row] else {
                owsFailDebug("searchResult was unexpectedly nil")
                return UITableViewCell()
            }
            cell.configure(withThread: searchResult.thread, isBlocked: isBlocked(thread: searchResult.thread))
            return cell
        case .contacts:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier()) as? ContactTableViewCell else {
                owsFailDebug("cell was unexpectedly nil")
                return UITableViewCell()
            }
            
            guard let searchResult = self.searchResultSet.contacts[safe: indexPath.row] else {
                owsFailDebug("searchResult was unexpectedly nil")
                return UITableViewCell()
            }
            cell.configure(withRecipientId: searchResult.signalAccount.recipientId)
            return cell
        case .messages:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HomeViewCell.cellReuseIdentifier()) as? HomeViewCell else {
                owsFailDebug("cell was unexpectedly nil")
                return UITableViewCell()
            }
            
            guard let searchResult = self.searchResultSet.messages[safe: indexPath.row] else {
                owsFailDebug("searchResult was unexpectedly nil")
                return UITableViewCell()
            }
            
            var overrideSnippet = NSAttributedString()
            var overrideDate: Date?
            if searchResult.messageId != nil {
                if let messageDate = searchResult.messageDate {
                    overrideDate = messageDate
                } else {
                    owsFailDebug("message search result is missing message timestamp")
                }
                
                // Note that we only use the snippet for message results,
                // not conversation results.  HomeViewCell will generate
                // a snippet for conversations that reflects the latest
                // contents.
                if let messageSnippet = searchResult.snippet {
                    overrideSnippet = NSAttributedString(string: messageSnippet,
                                                         attributes: [
                                                            NSAttributedString.Key.foregroundColor: Theme.secondaryColor
                        ])
                } else {
                    owsFailDebug("message search result is missing message snippet")
                }
            }
            
            cell.configure(withThread: searchResult.thread,
                           isBlocked: isBlocked(thread: searchResult.thread),
                           overrideSnippet: overrideSnippet,
                           overrideDate: overrideDate)
            
            return cell
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard nil != self.tableView(tableView, titleForHeaderInSection: section) else {
            return 0
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = self.tableView(tableView, titleForHeaderInSection: section) else {
            return nil
        }
        
        let label = UILabel()
        label.textColor = Theme.secondaryColor
        label.text = title
        label.font = UIFont.ows_dynamicTypeBody.ows_mediumWeight()
        label.tag = section
        
        let hMargin: CGFloat = 15
        let vMargin: CGFloat = 4
        let wrapper = UIView()
        wrapper.backgroundColor = Theme.offBackgroundColor
        wrapper.addSubview(label)
        label.autoPinWidthToSuperview(withMargin: hMargin)
        label.autoPinHeightToSuperview(withMargin: vMargin)
        
        return wrapper
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let searchSection = SearchSection(rawValue: section) else {
            owsFailDebug("unknown section: \(section)")
            return nil
        }
        
        switch searchSection {
        case .noResults:
            return nil
        case .conversations:
            if searchResultSet.conversations.count > 0 {
                return NSLocalizedString("SEARCH_SECTION_CONVERSATIONS", comment: "section header for search results that match existing conversations (either group or contact conversations)")
            } else {
                return nil
            }
        case .contacts:
            if searchResultSet.contacts.count > 0 {
                return NSLocalizedString("SEARCH_SECTION_CONTACTS", comment: "section header for search results that match a contact who doesn't have an existing conversation")
            } else {
                return nil
            }
        case .messages:
            if searchResultSet.messages.count > 0 {
                return NSLocalizedString("SEARCH_SECTION_MESSAGES", comment: "section header for search results that match a message in a conversation")
            } else {
                return nil
            }
        }
    }
    
    // MARK: BlockListCacheDelegate
    
    func blockListCacheDidUpdate(_ blocklistCache: BlockListCache) {
        refreshSearchResults()
    }
    
    // MARK: Update Search Results
    
    var refreshTimer: Timer?
    
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
            self.searchResultSet = HomeScreenSearchResultSet.empty
            self.tableView.reloadData()
            return
        }
        
        var searchResults: HomeScreenSearchResultSet?
        self.uiDatabaseConnection.asyncRead({[weak self] transaction in
            guard let strongSelf = self else { return }
            searchResults = strongSelf.searcher.searchForHomeScreen(searchText: searchText, transaction: transaction, contactsManager: strongSelf.contactsManager)
            },
                                            completionBlock: { [weak self] in
                                                AssertIsOnMainThread()
                                                guard let strongSelf = self else { return }
                                                
                                                guard let results = searchResults else {
                                                    owsFailDebug("searchResults was unexpectedly nil")
                                                    return
                                                }
                                                
                                                strongSelf.searchResultSet = results
                                                strongSelf.tableView.reloadData()
        })
    }
    
    // MARK: - UIScrollViewDelegate
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.conversationSearchViewWillBeginDragging()
    }
    
    // MARK: -
    
    private func isBlocked(thread: ThreadViewModel) -> Bool {
        return self.blockListCache.isBlocked(thread: thread.threadRecord)
    }
}

class VinciEmptySearchResultCell: UITableViewCell {
    static let reuseIdentifier = "VinciEmptySearchResultCell"
    
    let emptyView: VinciEmptySearchView
    let isSearching: Bool = false
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.emptyView = VinciEmptySearchView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(emptyView)
        
        emptyView.autoPinEdge(toSuperviewEdge: .top, withInset: 0.0, relation: .greaterThanOrEqual)
        emptyView.autoPinEdge(toSuperviewEdge: .leading, withInset: 0.0, relation: .greaterThanOrEqual)
        emptyView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0.0, relation: .greaterThanOrEqual)
        emptyView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 0.0, relation: .greaterThanOrEqual)
        
        emptyView.autoVCenterInSuperview()
        emptyView.autoHCenterInSuperview()
        
        emptyView.setContentHuggingHigh()
        emptyView.setCompressionResistanceHigh()
    }
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    public func configure(searchText: String, size: CGSize) {
        emptyView.autoSetDimensions(to: size)
        emptyView.isSearching = !searchText.isEmpty
    }
}
