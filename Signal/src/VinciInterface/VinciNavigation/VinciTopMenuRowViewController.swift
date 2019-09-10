//
//  VinciTopMenuRowViewController.swift
//  VinciNavigationBar
//
//  Created by Илья on 16/08/2019.
//  Copyright © 2019 Vinci Technologies. All rights reserved.
//

import UIKit

@objc class VinciTopMenuRowViewController: UIViewController {
    
    @objc var titleView: UIView? {
        didSet {
            if self.titleView != nil {
                view.addSubview(self.titleView!)
            }
        }
    }
    @objc var titleViewLabel: UILabel?
    
    var leftBarItem: UIBarButtonItem?
    @objc var leftBarItems = [UIBarButtonItem]() {
        didSet {
            updateBarButtons()
        }
    }
    
    @objc var leftBarItemStack: UIStackView!
    
    var rightBarItem: UIBarButtonItem?
    @objc var rightBarItems = [UIBarButtonItem]() {
        didSet {
            updateBarButtons()
        }
    }
    @objc var rightBarItemStack: UIStackView!
    
    var selfTitle = ""
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(title: String?) {
        super.init(nibName: nil, bundle: nil)
        selfTitle = title == nil ? "" : title!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Theme.backgroundColor
        
        // Do any additional setup after loading the view.
        titleViewLabel = UILabel()
        titleViewLabel?.text = selfTitle
        titleViewLabel?.textColor = UIColor.black
        titleViewLabel?.font = VinciStrings.navigationTitleFont
        titleViewLabel?.sizeToFit()
        
        titleViewLabel?.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleViewLabel!)
        titleViewLabel?.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        titleViewLabel?.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        initStacks()
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
        
        if titleViewLabel != nil {
            titleViewLabel!.removeFromSuperview()
        }
        
        if titleView != nil {
            titleView!.removeFromSuperview()
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
        
        if titleViewLabel != nil {
            view.addSubview(titleViewLabel!)
            titleViewLabel!.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            titleViewLabel!.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        }
        
        if titleView != nil {
            view.addSubview(titleView!)
//            titleView!.leftAnchor.constraint(greaterThanOrEqualTo: leftBarItemStack.rightAnchor, constant: 8.0).isActive = true
//            titleView!.rightAnchor.constraint(lessThanOrEqualTo: rightBarItemStack.leftAnchor, constant: -8.0).isActive = true
            titleView!.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            titleView!.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
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
