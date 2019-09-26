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

protocol VinciChallengeMediaTappedProtocol {
    func mediaTapped(media: Media, mediaFrame: CGRect, cell: VinciChallengeExtendedCell, image: UIImage?)
}

class VinciChallengeListViewController: VinciViewController, VinciChallengeListViewProtocol {
    var presenter: VinciChallengeListPresenterProtocol? = VinciChallengeListPresenter()
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var gamesLabel: UILabel!
    @IBOutlet var gamesTopConstraint: NSLayoutConstraint!
    @IBOutlet var gamesLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
    var selectedImageFrame: CGRect = .null
    var selectedImage: UIImage?
        
    func setupTableView() {
        self.tableView.register(VinciChallengeExtendedCell.self, forCellReuseIdentifier: kVinciChallengeExtendedCellReuseIdentifier)
        self.tableView.register(VinciChallengeLargeCollectionCell.self, forCellReuseIdentifier: kVinciChallengeLargeCollectionCellReuseIdentifier)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
        
    func updateChallengeList() {
        self.tableView.reloadData()
    }
    
    func updateTopChallengeList() {
        self.tableView.reloadSections(IndexSet(integer: 1), with: .none)
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
    
    @IBAction func presentSettings() {
        let navigationController:OWSNavigationController = AppSettingsViewController.inModalNavigationController()
        present(navigationController, animated: true, completion: nil)
    }
}


// MARK: Lifecycle
extension VinciChallengeListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        self.presenter?.startFetchingChallenges()
        self.presenter?.startFetchingTopChallenges()
        
        print("PHONE NUMBER: \(TSAccountManager.sharedInstance().localNumber() ?? "")")
        print("REGISTRATION ID: \(TSAccountManager.sharedInstance().getOrGenerateRegistrationId())")
    }
}


extension VinciChallengeListViewController: UITableViewDelegate {
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
            return 0
        case 1:
            return 1
        case 2:
            guard let count = self.presenter?.challengeCount(), count > 0
                else { return 3 }
            return count
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
            let cell = tableView.dequeueReusableCell(withIdentifier: kVinciChallengeLargeCollectionCellReuseIdentifier)! as! VinciChallengeLargeCollectionCell
            cell.setup(topChallenges: (self.presenter?.getTopChallenges())!)
            return cell
        case 2:
            let cell: VinciChallengeExtendedCell = self.tableView.dequeueReusableCell(withIdentifier: kVinciChallengeExtendedCellReuseIdentifier) as! VinciChallengeExtendedCell
            // FIXME: cell.prepareForReuse not getting called
            cell.cleanUp()
            // FIXME: cell не должен предполагать родителя определённого класса
            cell.viewContoller = self
            cell.delegate = self
            if let challenge = self.presenter?.challenge(at: indexPath) {
                cell.setup(with: challenge)
            }
            return cell
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


extension VinciChallengeListViewController: VinciChallengeMediaTappedProtocol {
    func mediaTapped(media: Media, mediaFrame: CGRect, cell: VinciChallengeExtendedCell, image: UIImage?) {
        let relatedToTable = cell.contentView.convert(mediaFrame, to: self.tableView)
        self.selectedImageFrame = self.tableView.convert(relatedToTable, to: self.tableView.superview)
        self.selectedImage = image
        
        let destVC: VinciChallengeWatchMediaViewController = VinciChallengeWatchMediaRouter.createModule()
        destVC.presenter!.mediaID = media.id
        self.navigationController?.delegate = self
        self.navigationController?.pushViewController(destVC, animated: true)
    }
}


extension VinciChallengeListViewController: VinciChallengeMoveToChallengeProtocol {
    func moveToChallenge(challengeID: String) {
        let destVC = VinciChallengeGameRouter.createModule()
        self.navigationController?.pushViewController(destVC, animated: true)
    }
}


extension VinciChallengeListViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationControllerOperation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if toVC is VinciChallengeWatchMediaViewController {
            let expandAnimator = ExpandAnimator()
            expandAnimator.originFrame = self.selectedImageFrame
            expandAnimator.originImage = self.selectedImage
            return expandAnimator
        }
        return nil
    }
}
