//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

class VinciContactsLargeTitleView: VinciTopMenuRowView {
    
    var titleLabel: UILabel!
    
    var contactsBottomConstraint: NSLayoutConstraint!
    var contactsLeftConstraint: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.text = "Contacts"
        titleLabel.font = VinciStrings.largeTitleFont
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15.0).isActive = true
//                chatsButtonLeftConstraint = title.leftAnchor.constraint(equalTo: leftAnchor, constant: 8.0)
//                chatsButtonLeftConstraint.isActive = true
        
        contactsBottomConstraint = titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -titleLabel.frame.height/2)
        contactsBottomConstraint.isActive = true
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
    }
    
    override func update(newHeight: CGFloat) {
        
        let selfHeight = newHeight
        let largeTitleFontSize = VinciStrings.largeTitleFont.pointSize
        let fontSize = (largeTitleFontSize - 17.0) * selfHeight / 42.0 + 17.0
        
        //        let oldFontSize = chatsButton.titleLabel!.font.pointSize
        //        print("new font size = \(fontSize), oldFontSize = \(oldFontSize)")
        titleLabel.font = VinciStrings.largeTitleFont.withSize(fontSize)
        
        contactsBottomConstraint.constant = 0.0
        
        // left anchor offset
        if let leftConstraint = contactsLeftConstraint {
            let xPositionToCentered:CGFloat = (superview!.frame.width - titleLabel.frame.width) / 2 - 15.0
            let newLabelXOffset = (xPositionToCentered) * (42.0 - selfHeight) / 42.0
            let oldLabelPositionX = leftConstraint.constant
            leftConstraint.constant -= (oldLabelPositionX - newLabelXOffset) / 2
        }
    }
}
