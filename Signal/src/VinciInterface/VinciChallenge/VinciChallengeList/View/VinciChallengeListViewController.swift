//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit
import Foundation

let kCompactCellHeight: CGFloat = 36.0
let kRowHeightExtendedCell: CGFloat = kCompactCellHeight + kCellMargin + kCellCollectionViewHeight + kCellMargin * 2

class VinciChallengeListViewController: VinciViewController, VinciChallengeListViewProtocol {
    var presenter: VinciChallengeListPresenterProtocol? = VinciChallengeListPresenter()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    func setupTableView() {
        self.tableView.register(VinciChallengeExtendedCell.self, forCellReuseIdentifier: VinciChallengeExtendedCellReuseIdentifier)
        self.tableView.delegate = self
        self.tableView.dataSource = self
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
            let cell: VinciChallengeExtendedCell = self.tableView.dequeueReusableCell(withIdentifier: VinciChallengeExtendedCellReuseIdentifier) as! VinciChallengeExtendedCell
            cell.setup(with: challenge)
            return cell
        }
        return UITableViewCell()
    }
}
