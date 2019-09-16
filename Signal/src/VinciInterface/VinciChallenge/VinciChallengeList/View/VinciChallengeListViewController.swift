//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit
import Foundation

let kCompactCellHeight: CGFloat = 36.0
let kCollectionCellOffset: CGFloat = 4.0
let kRowHeightExtendedCell: CGFloat = kCellMargin + kCompactCellHeight + kCollectionCellMargin + kCellCollectionViewHeight + kCollectionCellMargin

class VinciChallengeListViewController: VinciViewController, VinciChallengeListViewProtocol {
    var presenter: VinciChallengeListPresenterProtocol? = VinciChallengeListPresenter()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    
    private var elementSize: CGSize {
        get {
            return CGSize(width: self.collectionView.bounds.height * 2.0, height: self.collectionView.bounds.height)
        }
    }
    
    func setupTableView() {
        self.tableView.register(VinciChallengeExtendedCell.self, forCellReuseIdentifier: kVinciChallengeExtendedCellReuseIdentifier)
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func setupCollectionView() {
        self.collectionView.register(VinciChallengeCollectionSmallCell.self, forCellWithReuseIdentifier: kVinciChallengeCollectionCellReuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    func updateChallengeList() {
        self.tableView.reloadData()
    }
}


// MARK: Lifecycle
extension VinciChallengeListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        self.setupCollectionView()
        self.presenter?.startFetchingChallenges(limit: 20, offset: 0, signalID: "\(TSAccountManager.sharedInstance().getOrGenerateRegistrationId())")
        
        print("PHONE NUMBER: \(TSAccountManager.sharedInstance().localNumber() ?? "")")
        print("REGISTRATION ID: \(TSAccountManager.sharedInstance().getOrGenerateRegistrationId())")
    }
}


extension VinciChallengeListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kRowHeightExtendedCell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return kRowHeightExtendedCell
    }
}


extension VinciChallengeListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.presenter?.challengeCount() ?? 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let challenge = self.presenter?.challenge(at: indexPath) {
            let cell: VinciChallengeExtendedCell = self.tableView.dequeueReusableCell(withIdentifier: kVinciChallengeExtendedCellReuseIdentifier) as! VinciChallengeExtendedCell
            cell.setup(with: challenge)
            return cell
        }
        return UITableViewCell()
    }
}


extension VinciChallengeListViewController: UICollectionViewDelegate {
    
}


extension VinciChallengeListViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: kVinciChallengeCollectionCellReuseIdentifier, for: indexPath)
        return cell
    }
}


extension VinciChallengeListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.elementSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return kCollectionCellOffset
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let elementWidth: CGFloat = self.elementSize.width
        let ofs: CGFloat = kCollectionCellOffset
        let elementIndex: Int = Int(scrollView.contentOffset.x / (elementWidth + ofs))
        let elementPos: CGFloat = (scrollView.contentOffset.x / (elementWidth + ofs)) - CGFloat(elementIndex)
        let moreThenHalf: Bool = elementPos >= 0.5
        
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            let start: CGPoint = self.collectionView.contentOffset
            let end: CGPoint = CGPoint(x: CGFloat(moreThenHalf ? elementIndex + 1 : elementIndex) * (elementWidth + ofs), y: start.y)
            self.collectionView.contentOffset = end
//            self.collectionView.reloadItems(at: [IndexPath(row: elementIndex, section: 0)])
            self.collectionView.layoutIfNeeded()
        }, completion: nil)
    }
}
