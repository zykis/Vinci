//
//  VinciCallsTitleViewController.swift
//  VinciNavigationBar
//
//  Created by Илья on 16/08/2019.
//  Copyright © 2019 Vinci Technologies. All rights reserved.
//

import UIKit

@objc protocol VinciCallsTitleViewControllerDelegate {
    func allCallsTitleDidPressed()
    func missedCallsTitleDidPressed()
}

@objc class VinciCallsTitleViewController: UIViewController {
    
    var leftBarItem: UIBarButtonItem?
    @objc var leftBarItems = [UIBarButtonItem]() {
        didSet {
            updateBarButtons()
        }
    }
    
    var leftBarItemStack: UIStackView!
    
    var rightBarItem: UIBarButtonItem?
    @objc var rightBarItems = [UIBarButtonItem]() {
        didSet {
            updateBarButtons()
        }
    }
    var rightBarItemStack: UIStackView!
    
    var allCallsTitleLabel: UILabel!
    var missedCallsTitleLabel: UILabel!
    
    @objc var callsTitleDelegate: VinciCallsTitleViewControllerDelegate!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        allCallsTitleLabel = UILabel()
        allCallsTitleLabel?.text = "All Calls"
        allCallsTitleLabel?.textColor = Theme.navbarTitleColor
        allCallsTitleLabel?.font = VinciStrings.navigationTitleFont
        allCallsTitleLabel?.sizeToFit()
        
        allCallsTitleLabel?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(allCallsTitleLabel!)
        allCallsTitleLabel?.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 64.0).isActive = true
        allCallsTitleLabel?.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        missedCallsTitleLabel = UILabel()
        missedCallsTitleLabel?.text = "Missed Calls"
        missedCallsTitleLabel?.textColor = UIColor.init(rgbHex: 0xDADADA)
        missedCallsTitleLabel?.font = VinciStrings.navigationTitleFont
        missedCallsTitleLabel?.sizeToFit()
        
        missedCallsTitleLabel?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(missedCallsTitleLabel!)
        missedCallsTitleLabel?.leftAnchor.constraint(equalTo: allCallsTitleLabel.rightAnchor, constant: 42.0).isActive = true
        missedCallsTitleLabel?.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        allCallsTitleLabel.isUserInteractionEnabled = true
        allCallsTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(allCallsTitleTapped)))
        
        missedCallsTitleLabel.isUserInteractionEnabled = true
        missedCallsTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(missedCallsTitleTapped)))
        
        initStacks()
    }
    
    @objc func allCallsTitleTapped() {
        allCallsTitleLabel?.textColor = Theme.navbarTitleColor
        missedCallsTitleLabel?.textColor = UIColor.init(rgbHex: 0xDADADA)
        
        callsTitleDelegate.allCallsTitleDidPressed()
    }
    
    @objc func missedCallsTitleTapped() {
        allCallsTitleLabel?.textColor = UIColor.init(rgbHex: 0xDADADA)
        missedCallsTitleLabel?.textColor = Theme.navbarTitleColor
        
        callsTitleDelegate.missedCallsTitleDidPressed()
    }
    
    public func initStacks() {
        
        leftBarItemStack = UIStackView()
        // append leftBarItems stack
        leftBarItemStack.axis = .horizontal
        leftBarItemStack.alignment = .center
        leftBarItemStack.distribution = .equalCentering
        leftBarItemStack.spacing = 35
        leftBarItemStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(leftBarItemStack)
        
        rightBarItemStack = UIStackView()
        // append rightBarButton stack
        rightBarItemStack.axis = .horizontal
        rightBarItemStack.alignment = .center
        rightBarItemStack.distribution = .equalCentering
        rightBarItemStack.spacing = 35
        rightBarItemStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rightBarItemStack)
    }
    
    public func reloadStacks() {
        
        if allCallsTitleLabel != nil {
            allCallsTitleLabel!.removeFromSuperview()
        }
        
        if missedCallsTitleLabel != nil {
            missedCallsTitleLabel!.removeFromSuperview()
        }
        
        leftBarItemStack.removeFromSuperview()
        rightBarItemStack.removeFromSuperview()
        
        initStacks()
        
        leftBarItemStack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 15).isActive = true
        leftBarItemStack.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        leftBarItemStack.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        rightBarItemStack.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -15).isActive = true
        rightBarItemStack.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        rightBarItemStack.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        if allCallsTitleLabel != nil {
            view.addSubview(allCallsTitleLabel!)
            allCallsTitleLabel!.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 88.0).isActive = true
            allCallsTitleLabel!.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
        
        if missedCallsTitleLabel != nil {
            view.addSubview(missedCallsTitleLabel!)
            missedCallsTitleLabel!.leftAnchor.constraint(equalTo: allCallsTitleLabel.rightAnchor, constant: 27.0).isActive = true
            missedCallsTitleLabel!.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
    }
    
    public func updateBarButtons() {
        
        // clear buttons from left & right stack
        for item in leftBarItemStack.arrangedSubviews {
            item.removeFromSuperview()
        }
        
        for item in rightBarItemStack.arrangedSubviews {
            item.removeFromSuperview()
        }
        
        reloadStacks()
        
        for item in leftBarItems {
            let newButton = UIButton(type: .roundedRect)
            if let action = item.action {
                newButton.addTarget(item.target, action: action, for: .touchUpInside)
            }
            if let icon = item.image {
                newButton.setImage(icon.withRenderingMode(.alwaysTemplate), for: .normal)
                newButton.imageView?.contentMode = .scaleAspectFit
            } else {
                if let title = item.title {
                    if title.starts(with: "<") {
                        newButton.setImage(UIImage(named: "backArrowIcon"), for: .normal)
                        newButton.setTitle(title.substring(from: String.Index(encodedOffset: 1)), for: .normal)
                    } else {
                        newButton.setTitle(title, for: .normal)
                    }
                    newButton.titleLabel?.font = VinciStrings.regularFont.withSize(17.0)
                }
            }
            newButton.setTitleColor(UIColor.vinciBrandBlue, for: .normal)
            newButton.setTitleColor(UIColor.lightGray, for: .highlighted)
            newButton.setTitleColor(UIColor.init(rgbHex: 0xCACACA), for: .disabled)
            
            newButton.sizeToFit()
            newButton.autoSetDimension(.height, toSize: 24.0, relation: .lessThanOrEqual)
            
            leftBarItemStack.addArrangedSubview(newButton)
        }
        
        for item in rightBarItems {
            let newButton = UIButton(type: .roundedRect)
            if let action = item.action {
                newButton.addTarget(item.target, action: action, for: .touchUpInside)
            }
            if let icon = item.image {
                if item.title != nil && item.title == "vinciAvatar" {
                    newButton.setImage(icon.withRenderingMode(.alwaysOriginal), for: .normal)
                    newButton.layer.cornerRadius = 12
                } else {
                    newButton.setImage(icon.withRenderingMode(.alwaysTemplate), for: .normal)
                }
                newButton.imageView?.contentMode = .scaleAspectFit
            } else {
                if let title = item.title {
                    newButton.setTitle(title, for: .normal)
                    newButton.titleLabel?.font = VinciStrings.regularFont.withSize(17.0)
                }
            }
            newButton.setTitleColor(UIColor.vinciBrandBlue, for: .normal)
            newButton.setTitleColor(UIColor.lightGray, for: .highlighted)
            newButton.setTitleColor(UIColor.init(rgbHex: 0xCACACA), for: .disabled)
            
            newButton.sizeToFit()
            newButton.autoSetDimension(.height, toSize: 24.0, relation: .lessThanOrEqual)
            
            rightBarItemStack.addArrangedSubview(newButton)
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
