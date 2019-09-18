//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit
import Foundation

let kSectionMargin: CGFloat = 16.0
let kSearchBarHeight: CGFloat = 44.0
let kRowHeightCompactCell: CGFloat = 36.0 + kCellMargin * 2
let kCollectionCellOffset: CGFloat = 4.0
let kRowSpacing: CGFloat = 8.0
let kRowHeightExtendedCell: CGFloat = (kRowHeightCompactCell - kCellMargin) + kCollectionCellMargin + kCellCollectionViewHeight + kCollectionCellMargin

class VinciChallengeListViewController: VinciViewController, VinciChallengeListViewProtocol {
    var presenter: VinciChallengeListPresenterProtocol? = VinciChallengeListPresenter()
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var gamesLabel: UILabel!
    @IBOutlet var gamesTopConstraint: NSLayoutConstraint!
    @IBOutlet var gamesLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
        
    func setupTableView() {
        self.tableView.register(VinciChallengeExtendedCell.self, forCellReuseIdentifier: kVinciChallengeExtendedCellReuseIdentifier)
        self.tableView.register(VinciChallengeLargeCollectionCell.self, forCellReuseIdentifier: kVinciChallengeLargeCollectionCellReuseIdentifier)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
        
    func updateChallengeList() {
        self.tableView.reloadData()
    }
    
    func animateTitlePositionChange() {
        self.gamesTopConstraint.constant = self.navigationBar.bounds.height / 2.0 - self.gamesLabel.bounds.height / 2.0
        self.gamesLeadingConstraint.constant = self.view.bounds.width / 2.0 - self.gamesLabel.bounds.width / 2.0
        self.tableViewTopConstraint.constant = 8.0
        
        UIView.animate(withDuration: 0.3) {
            self.gamesLabel.transform = CGAffineTransform(scaleX: 0.65, y: 0.65)
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func pushToAccount() {
        let accountVC = VinciChallengeAccountRouter.createModule()
        self.navigationController?.pushViewController(accountVC, animated: true)
    }
}


// MARK: Lifecycle
extension VinciChallengeListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        self.presenter?.startFetchingChallenges(limit: 100, offset: 0, signalID: "\(TSAccountManager.sharedInstance().getOrGenerateRegistrationId())")
        
        print("PHONE NUMBER: \(TSAccountManager.sharedInstance().localNumber() ?? "")")
        print("REGISTRATION ID: \(TSAccountManager.sharedInstance().getOrGenerateRegistrationId())")
    }
}


extension VinciChallengeListViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        switch indexPath.section {
//        case 0:
//            return kSearchBarHeight
//        case 1:
//            return kLargeCollectionCellHeight
//        case 2:
//            return kRowHeightExtendedCell
//        default:
//            return 0.0
//        }
//    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > self.gamesLabel.bounds.height + kSearchBarHeight {
            self.animateTitlePositionChange()
        }
    }
}


extension VinciChallengeListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return self.presenter?.challengeCount() ?? 0
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let width: CGFloat = tableView.bounds.width
            let searchBar = UISearchBar(frame: CGRect(x: 0,
                                                      y: 0,
                                                      width: width,
                                                      height: kSearchBarHeight))
            searchBar.searchBarStyle = .minimal
            let cell = UITableViewCell()
            cell.contentView.addSubview(searchBar)
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: kVinciChallengeLargeCollectionCellReuseIdentifier)!
            return cell
        case 2:
            if let challenge = self.presenter?.challenge(at: indexPath) {
                let cell: VinciChallengeExtendedCell = self.tableView.dequeueReusableCell(withIdentifier: kVinciChallengeExtendedCellReuseIdentifier) as! VinciChallengeExtendedCell
                cell.setup(with: challenge)
                return cell
            }
            return UITableViewCell()
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return kSectionMargin
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}
