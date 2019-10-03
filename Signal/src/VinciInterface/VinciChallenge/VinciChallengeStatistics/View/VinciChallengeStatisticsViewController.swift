//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit


class VinciChallengeStatisticsViewController: VinciViewController {
    var presenter: VinciChallengeStatisticsPresenterProtocol?
    
    convenience init(tabIndex: Int = 0, nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.currentTabIndexInit = tabIndex
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private var currentTabIndexInit: Int = 0
    // FIXME: shouldnt be -1s
    private var previousTabIndex: Int = -1
    private var currentTabIndex: Int = -1 {
        didSet {
            if currentTabIndex == previousTabIndex {
                return
            }
            let previousButton = tabButton(by: previousTabIndex)
            let currentButton = tabButton(by: currentTabIndex)
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: {
                previousButton?.setTitleColor(.gray, for: .normal)
                currentButton?.setTitleColor(.black, for: .normal)
            }) { (_) in
                
                self.presenter?.challenges = []
                self.tableView.reloadData()
                
//                let finished: Bool? = self.currentTabIndex == 0 ? false : self.currentTabIndex == 1 ? true : nil
                let owner: Bool? = self.currentTabIndex == 2 ? true : nil
                let favourite: Bool = self.currentTabIndex == 1
                
                self.previousTabIndex = self.currentTabIndex
                ChallengeAPIManager.shared.fetchChallenges(participant: nil,
                                                           finished: nil,
                                                           owner: owner,
                                                           favourite: favourite,
                                                           limit: 100,
                                                           offset: 0) { (challenges, error) in
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
    }
    
    private func tabButton(by index: Int) -> UIButton? {
        switch index {
        case 0: return self.tab1Button
        case 1: return self.tab2Button
        case 2: return self.tab3Button
        default: return nil
        }
    }
    
    @IBAction func nowPlayingPressed() {
        self.currentTabIndex = 0
    }
    
    @IBAction func finishedPressed() {
        self.currentTabIndex = 1
    }
    
    @IBAction func authorPressed() {
        self.currentTabIndex = 2
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var winsLabel: UILabel!
    @IBOutlet weak var votesLabel: UILabel!
    @IBOutlet weak var incomeLabel: UILabel!
    @IBOutlet weak var tab1Button: UIButton!
    @IBOutlet weak var tab2Button: UIButton!
    @IBOutlet weak var tab3Button: UIButton!
    
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
        
        // FIXME: T_T
        self.currentTabIndex = currentTabIndexInit
        
        ChallengeAPIManager.shared.fetchStatistics { (statistic) in
            self.winsLabel.text = "\(statistic.wins)"
            self.votesLabel.text = "\(statistic.totalLikes)"
            self.incomeLabel.text = "$\(statistic.totalReward)"
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
