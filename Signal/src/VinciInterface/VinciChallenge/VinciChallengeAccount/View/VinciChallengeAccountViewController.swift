//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit


class VinciChallengeAccountViewController: VinciViewController, VinciChallengeAccountViewProtocol {
    var presenter: VinciChallengeAccountPresenterProtocol?
    
    @IBOutlet var avatar: UIImageView!
    @IBOutlet var navigationBar: UINavigationBar!
    
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
