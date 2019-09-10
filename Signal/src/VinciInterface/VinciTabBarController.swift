//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc protocol VinciTabBarControllerDelegate {
    func askRootNavigationToPush(viewController: UIViewController, animated: Bool)
}

@objc class VinciTabBarController: UITabBarController, UITabBarControllerDelegate, VinciTabBarControllerDelegate {
    
    let activeTabMarker = UIView()
    var activeTabMarkerConstraints = [NSLayoutConstraint]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        activeTabMarker.backgroundColor = UIColor.vinciBrandBlue
//        activeTabMarker.translatesAutoresizingMaskIntoConstraints = false
//        activeTabMarker.heightAnchor.constraint(equalToConstant: 46).isActive = true
//        activeTabMarker.widthAnchor.constraint(equalToConstant: 46).isActive = true
//        activeTabMarker.layer.cornerRadius = 23
//        tabBar.addSubview(activeTabMarker)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    @objc func hideTitleLabels() {
        var tabButtons = [UIView]()
        for subview in self.tabBar.subviews {
            if subview.isKind(of: NSClassFromString("UITabBarButton")!) {
                tabButtons.append(subview)
            }
        }
        
        for index in 0..<tabButtons.count {
            let activeButton = tabButtons[index]
            // find label view
            for subview in activeButton.subviews {
                if subview.isKind(of: NSClassFromString("UITabBarButtonLabel")!) {
                    // that's it!
                    subview.isHidden = true
                }
            }
        }
    }
    
    func markActiveTabButton(index: Int) {
        print("\(index) tab selected")
        
        let editedIndex = index
        
        var tabButtons = [UIView]()
        for subview in self.tabBar.subviews {
            if subview.isKind(of: NSClassFromString("UITabBarButton")!) {
                tabButtons.append(subview)
            }
        }
        
        if editedIndex < tabButtons.count {
            let activeButton = tabButtons[editedIndex]
            // find image view
            for subview in activeButton.subviews {
                if subview.isKind(of: NSClassFromString("UITabBarSwappableImageView")!) {
                    // that's it!
                    
                    NSLayoutConstraint.deactivate(activeTabMarkerConstraints)
                    activeTabMarker.removeConstraints(activeTabMarkerConstraints)
                    activeTabMarkerConstraints.removeAll()
                    
                    activeTabMarkerConstraints.append(activeTabMarker.centerXAnchor.constraint(equalTo: subview.centerXAnchor))
                    activeTabMarkerConstraints.append(activeTabMarker.centerYAnchor.constraint(equalTo: subview.centerYAnchor))
                    
                    for constraint in activeTabMarkerConstraints {
                        constraint.isActive = true
                    }
                }
            }
        }
    }
    
    // Override selectedIndex for Programmatic changes
    override var selectedIndex: Int {
        willSet {
            hideTitleLabels()
        }
        didSet {
//            markActiveTabButton(index: selectedIndex)
        }
    }
    
    // Override selectedViewController for User initiated changes
    override var selectedViewController: UIViewController? {
        willSet {
            hideTitleLabels()
        }
        didSet {
//            markActiveTabButton(index: selectedIndex)
        }
    }
    
    func askRootNavigationToPush(viewController: UIViewController, animated: Bool) {
        navigationController?.pushViewController(viewController, animated: animated)
    }
}
