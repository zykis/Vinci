//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit


class VinciChallengeAccountViewController: VinciViewController, VinciChallengeAccountViewProtocol {
    var presenter: VinciChallengeAccountPresenterProtocol?
    
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var navigationBar: UINavigationBar!
    
    @IBOutlet var winsLabel: UILabel!
    @IBOutlet var votesLabel: UILabel!
    @IBOutlet var incomeLabel: UILabel!
    
    @IBOutlet var tableView: UITableView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.barTintColor = .black
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        self.avatar.layer.cornerRadius = self.avatar.bounds.width / 2.0
    }
    
    @IBAction func pop() {
        self.navigationController?.popViewController(animated: true)
    }
}
