//
//  VinciMenuSearchBar.swift
//  VinciNavigationBar
//
//  Created by Илья on 16/08/2019.
//  Copyright © 2019 Vinci Technologies. All rights reserved.
//

import UIKit

@objc class VinciMenuSearchBar: VinciTopMenuRowView {
    
    var searchBar = UISearchBar()
    var searchTextField: UITextField?
    var searchTextFieldHeightConstraint: NSLayoutConstraint!
    var searchTextFieldRightConstraint: NSLayoutConstraint!
    
    var cancelButton: UIButton!
    var cancelButtonRightConstraint: NSLayoutConstraint!
    
    @objc public var searchDelegate: UISearchBarDelegate?
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        if searchBar.constraints.isEmpty {
            searchBar.barTintColor = UIColor.white
            
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            addSubview(searchBar)
            searchBar.topAnchor.constraint(equalTo: topAnchor).isActive = true
            searchBar.leftAnchor.constraint(equalTo: leftAnchor, constant: 7.0).isActive = true
            searchBar.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            searchBar.rightAnchor.constraint(equalTo: rightAnchor, constant: -7.0).isActive = true
            
            searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
            searchBar.showsCancelButton = false
            
            searchBar.delegate = self
        }
        
        if let textFieldInsideSearchBar = searchBar.value(forKey:"searchField") as? UITextField {
            
            if let backgroundview = textFieldInsideSearchBar.subviews.first {
                // Background color
                backgroundview.backgroundColor = UIColor.init(rgbHex: 0xF4F4F4)
                // Rounded corner
                backgroundview.layer.cornerRadius = 8;
                backgroundview.clipsToBounds = true;
            }
            
            if let glassIconView = textFieldInsideSearchBar.leftView as? UIImageView {
                //Magnifying glass
                glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
                glassIconView.tintColor = UIColor.init(rgbHex: 0xB1B1B1)
            }
            
            textFieldInsideSearchBar.font = VinciStrings.regularFont.withSize(13)
            textFieldInsideSearchBar.textColor = Theme.primaryColor
            textFieldInsideSearchBar.backgroundColor = UIColor.clear
            
            textFieldInsideSearchBar.translatesAutoresizingMaskIntoConstraints = false
            searchTextField = textFieldInsideSearchBar
            
            if let heightConstraint = (textFieldInsideSearchBar.constraints.filter{$0.firstAttribute == .height}.first) {
                searchTextFieldHeightConstraint = heightConstraint
            }
            
            textFieldInsideSearchBar.leftAnchor.constraint(equalTo: leftAnchor, constant: 15).isActive = true
            
            let centerYConstraint = textFieldInsideSearchBar.centerYAnchor.constraint(equalTo: centerYAnchor)
            centerYConstraint.isActive = true
        }
        
        if cancelButton == nil {
            cancelButton = UIButton(type: .system)
            cancelButton.setTitle("Cancel", for: .normal)
            searchBar.addSubview(cancelButton)
            cancelButton.translatesAutoresizingMaskIntoConstraints = false
            cancelButton.addTarget(self, action: #selector(searchBarCancelButtonPressed), for: .touchUpInside)
            
            cancelButton.sizeToFit()
            
            cancelButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            cancelButtonRightConstraint = cancelButton.rightAnchor.constraint(equalTo: rightAnchor, constant: cancelButton.frame.width)
            cancelButtonRightConstraint.isActive = true
            
            searchTextField?.rightAnchor.constraint(equalTo: cancelButton.leftAnchor, constant: -17.0).isActive = true
        }
        
        super.draw(rect)
    }
    
    public override func update(newHeight: CGFloat) {
        if let searchFieldFrame = searchTextField?.frame {
//            print("search field frame = \(searchFieldFrame)")
//            print("search bar height = \(searchBar.frame.height)")
            
            let searchFieldVerticalBorders:CGFloat = 13.0
            let newSearchFieldFrameHeight = searchBar.frame.height - searchFieldVerticalBorders * 2
            
            if newSearchFieldFrameHeight <= 30 && newSearchFieldFrameHeight > 0 {
                searchTextFieldHeightConstraint?.constant = newSearchFieldFrameHeight
            } else if newSearchFieldFrameHeight < 0 {
                searchTextFieldHeightConstraint?.constant = 0.0
            }
            
            if let backgroundview = searchTextField?.subviews.first {
                // Background color
                backgroundview.backgroundColor = UIColor.init(rgbHex: 0xF4F4F4)
                // Rounded corner
                backgroundview.layer.cornerRadius = 8;
                backgroundview.clipsToBounds = true;
            }
            
            if let glassIconView = searchTextField?.leftView as? UIImageView {
                //Magnifying glass
                glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
                glassIconView.tintColor = UIColor.init(rgbHex: 0xB1B1B1)
            }
            
            for subview in searchTextField!.subviews {
                if subview == searchTextField!.subviews.first {
                    continue
                }
                
                if newSearchFieldFrameHeight <= 30 && newSearchFieldFrameHeight >= 24 {
                    let newAlpha = (newSearchFieldFrameHeight - 24) / 6.0
                    subview.alpha = newAlpha
                    cancelButton.alpha = newAlpha
                } else if newSearchFieldFrameHeight < 24 {
                    subview.alpha = 0.0
                    cancelButton.alpha = 0.0
                }
            }
            
            searchBar.layoutIfNeeded()
        }
    }
    
    @objc func searchBarCancelButtonPressed() {
        self.searchBarCancelButtonClicked(searchBar)
    }
    
    public func searchBarIsReady() {
        cancelButtonRightConstraint.constant = -16.0
        UIView.animate(withDuration: 0.1) {
            self.cancelButton.alpha = 1.0
            self.layoutIfNeeded()
        }
    }
}

extension VinciMenuSearchBar : UISearchBarDelegate {
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchDelegate?.searchBarTextDidEndEditing?(searchBar)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchDelegate?.searchBarCancelButtonClicked?(searchBar)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchDelegate?.searchBarSearchButtonClicked?(searchBar)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchDelegate?.searchBarTextDidBeginEditing?(searchBar)
    }
    
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        self.searchDelegate?.searchBarBookmarkButtonClicked?(searchBar)
    }
    
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        self.searchDelegate?.searchBarResultsListButtonClicked?(searchBar)
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        cancelButtonRightConstraint.constant = cancelButton.frame.width
        UIView.animate(withDuration: 0.1) {
            self.cancelButton.alpha = 0.0
            self.layoutIfNeeded()
        }
        return self.searchDelegate?.searchBarShouldEndEditing?(searchBar) ?? true
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return self.searchDelegate?.searchBarShouldBeginEditing?(searchBar) ?? true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchDelegate?.searchBar?(searchBar, textDidChange: searchText)
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.searchDelegate?.searchBar?(searchBar, selectedScopeButtonIndexDidChange: selectedScope)
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return self.searchDelegate?.searchBar?(searchBar, shouldChangeTextIn: range, replacementText: text) ?? true
    }
    
}
