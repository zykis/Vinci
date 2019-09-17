//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit


class VinciChallengeAccountViewController: VinciViewController, VinciChallengeAccountViewProtocol {
    var presenter: VinciChallengeAccountPresenterProtocol?
    
    @IBOutlet var avatar: UIImageView!
    private var avatarMask: CAShapeLayer = CAShapeLayer()
    @IBOutlet var navigationBar: UINavigationBar!
    
    @IBOutlet var winsLabel: UILabel!
    @IBOutlet var votesLabel: UILabel!
    @IBOutlet var incomeLabel: UILabel!
    
    @IBOutlet var tableView: UITableView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.avatar.layer.mask = self.avatarMask
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
    
    @IBAction func pop() {
        self.navigationController?.popViewController(animated: true)
    }
}
