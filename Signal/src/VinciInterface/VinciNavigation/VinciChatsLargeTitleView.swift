//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

protocol VinciChatsLargeTitleViewDelegate {
    func vinciChatsTitlePressed()
    func vinciGroupsTitlePressed()
}

class VinciChatsLargeTitleView: VinciTopMenuRowView {
    
    var chatsButton: UIButton!
    var groupsButton: UIButton!
    
    var chatsButtonBottomConstraint: NSLayoutConstraint!
    var chatsButtonLeftConstraint: NSLayoutConstraint!
    var groupsButtonBottomConstraint: NSLayoutConstraint!
    var groupsButtonLeftConstraint: NSLayoutConstraint!
    
    public var delegate: VinciChatsLargeTitleViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        chatsButton = UIButton(type: .system)
        chatsButton.setTitle("Chats", for: .normal)
        chatsButton.titleLabel?.font = VinciStrings.largeTitleFont
        chatsButton.addTarget(self, action: #selector(chatsButtonPressed), for: .touchUpInside)
        addSubview(chatsButton)
        
        groupsButton = UIButton(type: .system)
        groupsButton.setTitle("Groups", for: .normal)
        groupsButton.titleLabel?.font = VinciStrings.largeTitleFont
        groupsButton.addTarget(self, action: #selector(groupsButtonPressed), for: .touchUpInside)
        addSubview(groupsButton)
        
        chatsButton.translatesAutoresizingMaskIntoConstraints = false
        groupsButton.translatesAutoresizingMaskIntoConstraints = false
        
        chatsButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 15.0).isActive = true
//        chatsButtonLeftConstraint = chatsButton.leftAnchor.constraint(equalTo: leftAnchor, constant: 8.0)
//        chatsButtonLeftConstraint.isActive = true
        
        chatsButtonBottomConstraint = chatsButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -chatsButton.frame.height/2)
        chatsButtonBottomConstraint.isActive = true
        
        groupsButtonLeftConstraint = groupsButton.leftAnchor.constraint(equalTo: chatsButton.rightAnchor, constant: 32.0)
        groupsButtonLeftConstraint.isActive = true
        
        groupsButtonBottomConstraint = groupsButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -groupsButton.frame.height/2)
        groupsButtonBottomConstraint.isActive = true
        
        chatsButtonPressed()
    }
    
    @objc func chatsButtonPressed() {
        print("chatsButtonPressed")
        chatsButton.setTitleColor(UIColor.black, for: .normal)
        groupsButton.setTitleColor(UIColor.init(rgbHex: 0xDADADA), for: .normal)
        
        delegate?.vinciChatsTitlePressed()
    }
    
    @objc func groupsButtonPressed() {
        print("groupsButtonPressed")
        chatsButton.setTitleColor(UIColor.init(rgbHex: 0xDADADA), for: .normal)
        groupsButton.setTitleColor(UIColor.black, for: .normal)
        
        delegate?.vinciGroupsTitlePressed()
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
        chatsButton.titleLabel?.font = VinciStrings.largeTitleFont.withSize(fontSize)
        groupsButton.titleLabel?.font = VinciStrings.largeTitleFont.withSize(fontSize)
        
        chatsButtonBottomConstraint.constant = 0.0
        groupsButtonBottomConstraint.constant = 0.0
        
        // left anchor offset
        if let leftConstraint = chatsButtonLeftConstraint {
            let xPositionToCentered:CGFloat = 15.0 + 66.0 // (superview!.frame.width - titleLabel.frame.width) / 2
            let newLabelXOffset = (xPositionToCentered) * (42.0 - selfHeight) / 42.0
            let oldLabelPositionX = leftConstraint.constant
            leftConstraint.constant -= (oldLabelPositionX - newLabelXOffset) / 2
            
            groupsButtonLeftConstraint.constant -= (oldLabelPositionX - newLabelXOffset) / 10
        }
    }
}
