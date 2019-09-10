//
//  VinciTopMenuController.swift
//  VinciNavigationBar
//
//  Created by Илья on 15/08/2019.
//  Copyright © 2019 Vinci Technologies. All rights reserved.
//

import UIKit

@objc class VinciTopMenuController: UIViewController {
    
    enum LargeTitleType {
        case chatsTitle
        case callsTitle
        case contactsTitle
        case appsTitle
        case noTitle
    }
    
    enum SearchBarMode {
        case hidden
        case opened
    }
    
    var titleType:LargeTitleType = .noTitle
    var searchBarMode:SearchBarMode = .opened {
        didSet {
            var searchBarHeight:CGFloat = 0.0
            switch self.searchBarMode {
            case .opened:
                searchBarHeight = 56.0
            default:
                searchBarHeight = 0.0
            }
            searchBarHeightConstraint?.constant = searchBarHeight
            self.view.layoutIfNeeded()
        }
    }
    
    var selfTitle = ""
    
    @objc var topTitleView: UIViewController!
    var mainStackView: UIStackView!
    var largeTitleWrapperView: VinciTopMenuRowView!
    var largeTitleView: VinciTopMenuRowView!
    @objc public var searchBar = VinciMenuSearchBar()
    var searchBarHeightConstraint: NSLayoutConstraint!
    var largeTitleHeightConstraint: NSLayoutConstraint!
    
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
        
        // Do any additional setup after loading the view.
        switch titleType {
        case .callsTitle:
            topTitleView = VinciCallsTitleViewController()
        default:
            topTitleView = VinciTopMenuRowViewController(title: selfTitle)
        }
        
        topTitleView.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topTitleView.view)
        topTitleView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topTitleView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        topTitleView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        topTitleView.view.heightAnchor.constraint(equalToConstant: 42.0).isActive = true
        
        var largeTitleViewHeight:CGFloat = 0.0
        switch titleType {
        case .chatsTitle, .callsTitle, .contactsTitle:
            largeTitleViewHeight = 42.0
        default:
            largeTitleViewHeight = 0.0
        }
        
        var searchBarHeight:CGFloat = 0.0
        switch searchBarMode {
        case .opened:
            searchBarHeight = 56.0
        default:
            searchBarHeight = 0.0
        }
        
        largeTitleWrapperView = VinciTopMenuRowView()
        largeTitleWrapperView.translatesAutoresizingMaskIntoConstraints = false
        largeTitleHeightConstraint = largeTitleWrapperView.heightAnchor.constraint(equalToConstant: largeTitleViewHeight)
        largeTitleHeightConstraint.isActive = true
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBarHeightConstraint = searchBar.heightAnchor.constraint(lessThanOrEqualToConstant: searchBarHeight)
        searchBarHeightConstraint.isActive = true
        
        mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.alignment = .fill
        mainStackView.spacing = 0
        
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStackView)
        mainStackView.topAnchor.constraint(equalTo: topTitleView.view.bottomAnchor).isActive = true
        mainStackView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mainStackView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        mainStackView.addArrangedSubview(largeTitleWrapperView)
        mainStackView.addArrangedSubview(searchBar)
        
        // and now i put really large title view and anchor it to the fake one (wrapper)
        switch titleType {
        case .chatsTitle:
            largeTitleView = VinciChatsLargeTitleView()
        case .callsTitle:
            largeTitleView = VinciCallsLargeTitleView()
        case .contactsTitle:
            largeTitleView = VinciContactsLargeTitleView()
        default:
            largeTitleView = VinciTopMenuRowView()
            largeTitleView.heightAnchor.constraint(equalToConstant: largeTitleViewHeight).isActive = true
        }
        
        view.addSubview(largeTitleView)
        
        if let largeChatsTitleView = largeTitleView as? VinciChatsLargeTitleView {
            largeChatsTitleView.translatesAutoresizingMaskIntoConstraints = false
            largeChatsTitleView.heightAnchor.constraint(equalToConstant: largeTitleViewHeight).isActive = true
            largeChatsTitleView.bottomAnchor.constraint(equalTo: largeTitleWrapperView.bottomAnchor).isActive = true
            largeChatsTitleView.chatsButtonLeftConstraint = largeChatsTitleView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0.0)
            largeChatsTitleView.chatsButtonLeftConstraint.isActive = true
            largeChatsTitleView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -42.0).isActive = true
            
            largeChatsTitleView.bringSubview(toFront: view)
        }
        
        if let largeCallsTitleView = largeTitleView as? VinciCallsLargeTitleView {
            largeCallsTitleView.translatesAutoresizingMaskIntoConstraints = false
            largeCallsTitleView.heightAnchor.constraint(equalToConstant: largeTitleViewHeight).isActive = true
            largeCallsTitleView.bottomAnchor.constraint(equalTo: largeTitleWrapperView.bottomAnchor).isActive = true
            largeCallsTitleView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0.0).isActive = true
            largeCallsTitleView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -42.0).isActive = true
            
            largeCallsTitleView.bringSubview(toFront: view)
        }
        
        if let largeContactsTitleView = largeTitleView as? VinciContactsLargeTitleView {
            largeContactsTitleView.translatesAutoresizingMaskIntoConstraints = false
            largeContactsTitleView.heightAnchor.constraint(equalToConstant: largeTitleViewHeight).isActive = true
            largeContactsTitleView.bottomAnchor.constraint(equalTo: largeTitleWrapperView.bottomAnchor).isActive = true
            largeContactsTitleView.contactsLeftConstraint = largeContactsTitleView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0.0)
            largeContactsTitleView.contactsLeftConstraint.isActive = true
            largeContactsTitleView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -42.0).isActive = true
            
            largeContactsTitleView.bringSubview(toFront: view)
        }
    }
    
    @objc public let maxBarHeight:CGFloat = 140.0
    @objc public let minBarHeight:CGFloat = 42.0
    
    var viewHeightConstraint: NSLayoutConstraint!
    
    var seachBarCollapsed = false
    var largeTitleCollapsed = false
    
    func setLargeTitle(collapsed: Bool) {
        if collapsed {
            largeTitleHeightConstraint.constant = 0.0
            largeTitleView.isHidden = true
            
            largeTitleCollapsed = true
        } else {
            largeTitleHeightConstraint.constant = 42.0
            largeTitleView.isHidden = false
            
            largeTitleCollapsed = false
        }
    }
    
    public func isCollapsed() -> Bool {
        let minHeight = isSearching ? minBarHeight + 42.0 : minBarHeight
        return self.viewHeightConstraint.constant == minHeight ? true : false
    }
    
    public var isSearching: Bool {
        guard let searchText = self.searchBar.searchTextField?.text else {
            return false
        }
        return searchText.isEmpty ? false : true
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    public func defineStates() {
        seachBarCollapsed = searchBar.frame.height == 0.0 ? true : false
        largeTitleCollapsed = largeTitleWrapperView.frame.height == 0.0 ? true : false
    }
    
    public func scrollToPosition(isSearching: Bool = false) -> CGFloat {
        
        var retValue:CGFloat = 0.0
        
        let searchBarHeight = self.searchBar.frame.height
        var catchOffset:CGFloat = seachBarCollapsed ? 46.0 : 10.0
        
        if searchBarHeight < 56.0 - catchOffset {
            retValue = -searchBarHeight
        } else {
            retValue = 56.0 - searchBarHeight
        }
        
        let largeTitleHeight = self.largeTitleWrapperView.frame.height
        catchOffset = largeTitleCollapsed ? 32.0 : 10.0
        if largeTitleHeight < 42.0 - catchOffset {
            retValue -= largeTitleHeight
        } else {
            retValue += 42.0 - largeTitleHeight
        }
        
        return retValue
    }
    
    public func update(newHeight: CGFloat) {
//        print("update TopMenu height with \(viewHeightConstraint.constant)")
        viewHeightConstraint.constant = newHeight
        searchBar.update(newHeight: newHeight)
        largeTitleWrapperView.update(newHeight: newHeight)
        largeTitleView.update(newHeight: largeTitleWrapperView.frame.height)
    }
    
    @objc public func pinToTop() -> NSLayoutConstraint! {
        if let superView = self.view.superview {
            
            view.translatesAutoresizingMaskIntoConstraints = false
            
            let topConstraint = view.topAnchor.constraint(equalTo: superView.layoutMarginsGuide.topAnchor)
            topConstraint.isActive = true
            
            view.leftAnchor.constraint(equalTo: superView.leftAnchor).isActive = true
            view.rightAnchor.constraint(equalTo: superView.rightAnchor).isActive = true
            
            viewHeightConstraint = view.heightAnchor.constraint(lessThanOrEqualToConstant: maxBarHeight)
            viewHeightConstraint.isActive = true
            
            // need to do this to have true searchBar sizes and constraints
            view.layoutIfNeeded()
            searchBar.draw(searchBar.frame)
            
            return topConstraint
        }
        
        return NSLayoutConstraint()
    }
    
}
