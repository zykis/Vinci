//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let kVinciChallengeAccountCellReuseIdentifier = "kVinciChallengeAccountCellRI"
let kVinciChallengeAccountCellXibName = "VinciChallengeAccountCell"

class VinciChallengeAccountViewController: VinciViewController, VinciChallengeAccountViewProtocol {
    var presenter: VinciChallengeAccountPresenterProtocol?
    
    private var avatarMask: CAShapeLayer = CAShapeLayer()
    
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var winsLabel: UILabel!
    @IBOutlet var votesLabel: UILabel!
    @IBOutlet var incomeLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var newGameButton: UIButton!
    
    @IBAction func newGamePressed() {
        let destVC = VinciChallengeGameRouter.createModule(gameState: .new)
        self.navigationController?.pushViewController(destVC, animated: true)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func pop() {
        self.navigationController?.popViewController(animated: true)
    }
     
    func setupTableView() {
        let nib = UINib(nibName: kVinciChallengeAccountCellXibName, bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: kVinciChallengeAccountCellReuseIdentifier)
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
}


// Lifecycle
extension VinciChallengeAccountViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        
        self.avatar.layer.mask = self.avatarMask
        
        ChallengeAPIManager.shared.fetchStatistics { (statistic) in
            self.winsLabel.text = "\(statistic.wins)"
            self.votesLabel.text = "\(statistic.totalLikes)"
            self.incomeLabel.text = "$\(statistic.totalReward)"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.barTintColor = .black
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let af = self.avatar.frame
        self.avatarMask.bounds = CGRect(x: 0,
                                        y: 0,
                                        width: af.height,
                                        height: af.height)
        self.avatarMask.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        self.avatarMask.position = CGPoint(x: af.origin.x,
                                           y: af.origin.y + af.size.height)
        self.avatarMask.path = UIBezierPath(roundedRect: self.avatarMask.bounds, cornerRadius: af.size.height / 2.0).cgPath
        var t: CATransform3D = CATransform3DIdentity
        t = CATransform3DMakeTranslation(af.size.width * 0.15, 0, 0)
        t.m11 = 1.2
        t.m22 = 1.2
        self.avatarMask.transform = t
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.newGameButton.layer.cornerRadius = newGameButton.bounds.height / 2.0
    }
}


extension VinciChallengeAccountViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destVC = VinciChallengeStatisticsRouter.createModule(tabIndex: indexPath.row)
        navigationController?.pushViewController(destVC, animated: true)
    }
}


extension VinciChallengeAccountViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: VinciChallengeAccountCell = self.tableView.dequeueReusableCell(withIdentifier: kVinciChallengeAccountCellReuseIdentifier) as! VinciChallengeAccountCell
        switch indexPath.row {
//        case 0:
//            cell.setup(iconName: "icon_gamerules", title: "Game Rules")
        case 0:
            cell.setup(iconName: "icon_star", title: "Now Trending")
        case 1:
            cell.setup(iconName: "icon_interests", title: "My Interests")
        case 2:
            cell.setup(iconName: "icon_gamerules", title: "Author")
        default:
            cell.setup(iconName: "", title: "")
        }
        return cell
    }
}
