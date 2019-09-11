//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

class VinciChallengeListViewController: VinciViewController, VinciChallengeListViewProtocol {
    var presenter: VinciChallengeListPresenterProtocol? = VinciChallengeListPresenter()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    func setupTableView() {
//        self.tableView.register(UINib(nibName: VinciChallengeCompactCellNibName, bundle: nil),
//                                forCellReuseIdentifier: VinciChallengeCompactCellReuseIdentifier)
        self.tableView.register(VinciChallengeCompactCell.self, forCellReuseIdentifier: VinciChallengeCompactCellReuseIdentifier)
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
            let cell: VinciChallengeCompactCell = self.tableView.dequeueReusableCell(withIdentifier: VinciChallengeCompactCellReuseIdentifier) as! VinciChallengeCompactCell
            cell.setup(with: challenge)
            return cell
        }
        return UITableViewCell()
    }
}


extension VinciChallengeListViewController: UICollectionViewDelegate {
    
}


extension VinciChallengeListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}
