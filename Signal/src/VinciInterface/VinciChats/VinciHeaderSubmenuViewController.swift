//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc class VinciHeaderSubmenuViewController: UIView {
    
    @objc public var submenuBar:VinciConversationHeaderSubmenu!
    
    var submenuBarHeight:CGFloat = 0
    let bottomSubmenuLine:UIView = UIView()
    
    @objc var delegate:VinciConversationHeaderSubmenuDelegate?
    
    @objc public var isShown = false
    @objc public var settingsTableView:UITableView? {
        didSet {
            self.settingsTableView?.frame = CGRect.init(x: 16, y: self.submenuBarHeight*2, width: self.frame.width - 16*2, height: self.frame.height - 8*2 - self.submenuBarHeight - 64)
            if ( self.settingsTableView != nil ) {
                self.addSubview(self.settingsTableView!)
                self.settingsTableView?.isHidden = true
            }
        }
    }
    
    var contentView:UIView? = UIView()
    
    var thread:TSThread?
    var dbConnection:YapDatabaseConnection?
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    @objc init(submenuHeight:CGFloat) {
        super.init(frame: CGRect.zero)
        self.submenuBarHeight = submenuHeight
        commonInit()
    }
    
    func commonInit() {
        submenuBar = VinciConversationHeaderSubmenu()
        submenuBar.delegate = self
        
        bottomSubmenuLine.backgroundColor = Theme.cellSeparatorColor
        submenuBar.addSubview(bottomSubmenuLine)
        
        self.addSubview(self.submenuBar)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        //        tabBar = UITabBar(frame: CGRect.init(x: 0, y: 0, width: rect.width, height: self.submenuBarHeight))
        //        tabBar.delegate = self
        //        tabBar.barTintColor = Theme.backgroundColor
        //        tabBar.tintColor = Theme.primaryColor
        
        //        let searchItem = UITabBarItem(title: "Search", image: UIImage(named: "searchbar_search"), tag: 0)
        //        let muteItem = UITabBarItem(title: "Mute", image: UIImage(named: "table_ic_mute_thread"), tag: 1)
        //        let walletItem = UITabBarItem(title: "Wallets", image: UIImage(named: "tabWallets"), tag: 2)
        //        let infoItem = UITabBarItem(title: "Info", image: UIImage(named: "ic_info"), tag: 3)
        
        //        let barItems:[UITabBarItem] = [searchItem, muteItem, walletItem, infoItem]
        //        tabBar.setItems(barItems, animated: false)
        //        self.addSubview(tabBar)
        
        submenuBar.frame = CGRect.init(x: 0, y: self.submenuBarHeight - 64, width: rect.width, height: 64)
        bottomSubmenuLine.frame = CGRect.init(x: 0, y: 63, width: rect.width, height: 1)
        
        // Do any additional setup after loading the view.
        self.submenuBar.alpha = 1.0
//        self.addSubview(contentView!)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if ( !self.isShown ) {
            return false
        }
        
        return true
    }
    
    @objc public func show() {
        
        UIView.transition(with: self, duration: 0.1, options: .curveEaseIn, animations: {
            self.submenuBar.frame = self.submenuBar.frame.offsetBy(dx: 0, dy: 64)
            //            self.contentView!.frame = self.contentView!.frame.offsetBy(dx: 0, dy: -self.height() + self.submenuBarHeight*2)
            self.layer.backgroundColor = Theme.backgroundColor.withAlphaComponent(0.45).cgColor
            self.submenuBar.alpha = 1.0
            self.contentView?.alpha = 1.0
        }) { (result) in
            if ( result ) {
                self.isShown = true
            }
        }
    }
    
    @objc public func hide() {
        self.menuButtonDidPressed(action: .noAction)
        
        UIView.transition(with: self, duration: 0.1, options: .curveEaseIn, animations: {
            self.submenuBar.frame = self.submenuBar.frame.offsetBy(dx: 0, dy: -64)
            //            self.contentView!.frame = self.contentView!.frame.offsetBy(dx: 0, dy: self.height() - self.submenuBarHeight*2)
            self.layer.backgroundColor = UIColor.clear.cgColor
            self.submenuBar.alpha = 0.0
            self.contentView?.alpha = 0.0
        }) { (result) in
            if ( result ) {
                self.isShown = false
            }
        }
    }
    
    @objc public func changeContentView() {
        if self.contentView == nil {
            // show contentView
        } else {
            // change contentView
        }
    }
    
    @objc func configure(thread:TSThread, connection:YapDatabaseConnection) {
        self.thread = thread
        self.dbConnection = connection
        
        if ( self.thread?.isGroupThread() ?? false ) {
            self.submenuBar.disableButton(action: .callAction)
        }
    }
}

extension VinciHeaderSubmenuViewController : VinciConversationHeaderSubmenuDelegate {
    func menuButtonDidPressed(action: VinciConversationHeaderSubmenuActions) {
        
        var darkTo:CGFloat = 0.0
        var menuPressed:VinciConversationHeaderSubmenuActions = .noAction
        
        switch action {
        case .searchAction:
//            self.submenuBar.setOnlyButtonActive(action: .noAction)
            menuPressed = .searchAction
//            darkTo = 0.45
            break
        case .muteAction:
//            self.submenuBar.setOnlyButtonActive(action: .muteAction)
            menuPressed = .muteAction
//            darkTo = 0.95
            break
        case .callAction:
//            self.submenuBar.setOnlyButtonActive(action: .callAction)
            menuPressed = .callAction
//            darkTo = 0.95
            break
        case .infoAction:
//            self.submenuBar.setOnlyButtonActive(action: .noAction)
            menuPressed = .infoAction
//            darkTo = 0.45
            break
        default:
//            self.submenuBar.setOnlyButtonActive(action: .noAction)
            menuPressed = .noAction
//            darkTo = 0.45
            break
        }
        
        UIView.transition(with: self, duration: 0.1, options: .curveEaseIn, animations: {
            self.layer.backgroundColor = Theme.backgroundColor.withAlphaComponent(darkTo).cgColor
        }) { (result) in
            self.delegate?.menuButtonDidPressed(action: menuPressed)
        }
    }
}
