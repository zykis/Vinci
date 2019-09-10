//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

class VinciInfoCallViewController: UIViewController {
    
    let navigationBar = VinciTopMenuController(title: "Info")
    var navigationBarTopConstraint: NSLayoutConstraint!
    let tableView = UITableView(frame: CGRect.zero, style: .plain)
    
    var headerViewMaxHeight: CGFloat = 128.0
    let headerViewMinHeight: CGFloat = 42.0
    
    var call: TSCall?
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    init(call: TSCall) {
        super.init(nibName: nil, bundle: nil)
        self.call = call
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Theme.backgroundColor

        // Do any additional setup after loading the view.
        view.addSubview(navigationBar.view)
        navigationBarTopConstraint = navigationBar.pinToTop()
        headerViewMaxHeight = navigationBar.maxBarHeight
        navigationBar.searchBarMode = .hidden
        
        if let topTitleView = navigationBar.topTitleView as? VinciTopMenuRowViewController {
            topTitleView.leftBarItems.append(UIBarButtonItem(title: "< Back", style: .plain, target: self, action: #selector(dismissViewController)))
            topTitleView.rightBarItems.append(UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(dismissViewController)))
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        view.addSubview(tableView)
        
        tableView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
        tableView.autoPinEdge(.top, to: .bottom, of: navigationBar.view)
        
//        searchResultsController.delegate = self
    }
    
    @objc func dismissViewController() {
        navigationController?.popViewController(animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension VinciInfoCallViewController : UITableViewDelegate {
    
}

extension VinciInfoCallViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if call == nil {
            return 0
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowIndex = indexPath.row
        
        switch rowIndex {
        case 0:
            
            let cell = VinciContactViewCell(style: .default, reuseIdentifier: "contactCell")
            OWSTableItem.configureCell(cell)
            
            cell.configure(thread: call!.thread)
            cell.selectionStyle = .none
            cell.hideChecker(animated: false)
            
            return cell
            
        default:
            return UITableViewCell()
        }
    }
}

//extension VinciInfoCallViewController : UISearchBarDelegate {
//
//    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
//        navigationBar.searchBar.searchBar.setShowsCancelButton(false, animated: false)
//
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
//
//        let tableView = self.searchResultsController.tableView
//        tableView.delegate = hideSearchBarWhenScrolling ? self : nil
//        tableView.setContentOffset(CGPoint(x: 0.0, y: 0.0), animated: false)
//
//        let navBarLargeTitleHeight = navigationBar.largeTitleView.frame.height
//        navigationBarTopConstraint.constant = -navigationBar.topTitleView.view.frame.height - navBarLargeTitleHeight
//        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseInOut, animations: {
//            self.navigationBar.topTitleView.view.alpha = 0.0
//            self.navigationBar.largeTitleView.alpha = 0.0
//            self.tableView.alpha = 0.0
//            self.view.layoutIfNeeded()
//        }) { (finished) in
//            self.navigationBar.searchBar.searchBarIsReady()
//        }
//
//        return searchBar == self.searchBar
//    }
//
//    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
//        return searchBar == self.searchBar
//    }
//
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        self.searchResultsController.searchText = searchText
//    }
//
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.text?.removeAll()
//        searchBar.resignFirstResponder()
//
//        self.searchResultsController.searchText = ""
//        //        searchResultsController.updateSearchResults(searchText: "")
//
//        navigationBarTopConstraint.constant = 0.0
//        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseInOut, animations: {
//            self.navigationBar.topTitleView.view.alpha = 1.0
//            self.navigationBar.largeTitleView.alpha = 1.0
//            self.tableView.alpha = 1.0
//            self.view.layoutIfNeeded()
//        }) { (finished) in
//            if let searchResultsView = self.searchResultsController.view {
//                searchResultsView.removeFromSuperview()
//            }
//        }
//    }
//}

//// MARK: ConversationSearchViewDelegate
//extension VinciInfoCallViewController : VinciSearchResultsViewDelegate {
//    func conversationSearchViewWillBeginDragging() {
//        //        searchBar.resignFirstResponder()
//        // OWSAssertDebug(!self.searchBar.isFirstResponder);
//    }
//    
//    func didSelect(rowWith vinciAccount: SignalAccount) {
//    }
//}
