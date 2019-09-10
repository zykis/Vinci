//
//  VinciLargeTitleView.swift
//  VinciNavigationBar
//
//  Created by Илья on 16/08/2019.
//  Copyright © 2019 Vinci Technologies. All rights reserved.
//

import UIKit

class VinciLargeTitleView: VinciTopMenuRowView {
    
//    var titleLabelBottomConstraint: NSLayoutConstraint!
//    var titleLabelLeftConstraint: NSLayoutConstraint!
    
    var titleText: String = "" {
        didSet {
            titleLabel.text = self.titleText
            titleLabel.sizeToFit()
        }
    }
    
    var titleLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    init(titleText: String) {
        super.init(frame: CGRect.zero)
        commonInit()
        
        self.titleText = titleText
        
        titleLabel.text = self.titleText
        titleLabel.sizeToFit()
    }
    
    func commonInit() {
        titleLabel.font = UIFont.systemFont(ofSize: 24.0)
        titleLabel.textColor = UIColor.black
        titleLabel.sizeToFit()
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 8.0).isActive = true
        
        let titleLabelBottomOffset = (frame.height - titleLabel.frame.height) / 2
        titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -titleLabelBottomOffset).isActive = true
        
        super.draw(rect)
    }
    
    public override func update(newHeight: CGFloat) {
        print("update large title height, now is \(frame.height)")
    }
}
