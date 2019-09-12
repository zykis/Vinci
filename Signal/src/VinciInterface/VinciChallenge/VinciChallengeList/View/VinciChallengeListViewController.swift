//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit
import Foundation

let kCompactCellHeight: CGFloat = 36.0
let kRowHeightExtendedCell: CGFloat = kCellMargin + kCompactCellHeight + kCollectionCellMargin + kCellCollectionViewHeight + kCollectionCellMargin

class VinciChallengeListViewController: VinciViewController, VinciChallengeListViewProtocol {
    var presenter: VinciChallengeListPresenterProtocol? = VinciChallengeListPresenter()
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var collectionView: UICollectionView!
    
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
        self.presenter?.startFetchingChallenges()
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
        let height: CGFloat = self.collectionView.bounds.height
        let width: CGFloat = height * 2.0
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4.0
    }
}
