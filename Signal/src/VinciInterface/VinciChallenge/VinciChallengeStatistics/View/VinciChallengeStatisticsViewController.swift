//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit


class VinciChallengeStatisticsViewController: VinciViewController {
    var presenter: VinciChallengeStatisticsPresenterProtocol?
    
    @IBOutlet weak var tableView: UITableView!
    
    func setupTableView() {
        tableView.register(VinciChallengeCompactCell.self, forCellReuseIdentifier: kVinciChallengeCompactCellReuseIdentifier)
        tableView.dataSource = self
    }
}


// MARK: Lifecycle
extension VinciChallengeStatisticsViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        ChallengeAPIManager.shared.fetchChallenges(participant: nil, finished: nil, owner: nil, limit: 100, offset: 0) { (challenges, error) in
            guard error == nil
                else { return }
            
            if let challenges = challenges {
                DispatchQueue.main.async {
                    self.presenter?.challenges = challenges
                    self.tableView.reloadData()
                }
            }
        }
    }
}


// MARK: User interaction
extension VinciChallengeStatisticsViewController {
    @IBAction func backButtonPressed() {
        navigationController?.popViewController(animated: true)
    }
}


extension VinciChallengeStatisticsViewController: VinciChallengeStatisticsViewProtocol {
    
}


extension VinciChallengeStatisticsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter?.challenges.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kVinciChallengeCompactCellReuseIdentifier) as! VinciChallengeCompactCell
        if presenter?.challenges.indices.contains(indexPath.row) ?? false {
            let ch = presenter!.challenges[indexPath.row]
            cell.setup(with: ch)
            return cell
        }
        return UITableViewCell()
    }
}
