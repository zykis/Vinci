//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc protocol VinciConversationHeaderSubmenuDelegate {
    func menuButtonDidPressed(action:VinciConversationHeaderSubmenuActions)
}

@objc enum VinciConversationHeaderSubmenuActions:Int {
    case noAction
    case searchAction
    case muteAction
    case callAction
    case infoAction
}

@objc class VinciConversationHeaderSubmenu: UIView {
    
    @objc var delegate:VinciConversationHeaderSubmenuDelegate?
    
    let searchButton:UIButton = UIButton()
    let muteButton:UIButton = UIButton()
    let callButton:UIButton = UIButton()
    let infoButton:UIButton = UIButton()
    
    let contentStack:UIStackView = UIStackView()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        self.layer.backgroundColor = Theme.backgroundColor.cgColor
        
        searchButton.autoSetDimensions(to: CGSize(width: 25, height: 25))
        muteButton.autoSetDimensions(to: CGSize(width: 25, height: 25))
        callButton.autoSetDimensions(to: CGSize(width: 25, height: 25))
        infoButton.autoSetDimensions(to: CGSize(width: 25, height: 25))
        
        searchButton.setImage(UIImage(named: "chatSearchIcon")?.asTintedImage(color: UIColor.vinciBrandBlue), for: .normal)
        muteButton.setImage(UIImage(named: "chatMuteIcon")?.asTintedImage(color: UIColor.vinciBrandBlue), for: .normal)
        callButton.setImage(UIImage(named: "chatCallIcon")?.asTintedImage(color: UIColor.vinciBrandBlue), for: .normal)
        infoButton.setImage(UIImage(named: "chatInfoIcon")?.asTintedImage(color: UIColor.vinciBrandBlue), for: .normal)
        
        searchButton.setImage(UIImage(named: "chatSearchIcon")?.asTintedImage(color: UIColor.lightGray), for: .highlighted)
        muteButton.setImage(UIImage(named: "chatMuteIcon")?.asTintedImage(color: UIColor.lightGray), for: .highlighted)
        callButton.setImage(UIImage(named: "chatCallIcon")?.asTintedImage(color: UIColor.lightGray), for: .highlighted)
        infoButton.setImage(UIImage(named: "chatInfoIcon")?.asTintedImage(color: UIColor.lightGray), for: .highlighted)
        
        searchButton.addTarget(self, action: #selector(buttonDidPressed(sender:)), for: .touchUpInside)
        muteButton.addTarget(self, action: #selector(buttonDidPressed(sender:)), for: .touchUpInside)
        callButton.addTarget(self, action: #selector(buttonDidPressed(sender:)), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(buttonDidPressed(sender:)), for: .touchUpInside)
        
        contentStack.axis = .horizontal
        contentStack.alignment = .fill
        contentStack.spacing = 8
        contentStack.distribution = .equalCentering
        
        contentStack.addArrangedSubview(self.searchButton)
        contentStack.addArrangedSubview(self.muteButton)
        contentStack.addArrangedSubview(self.callButton)
        contentStack.addArrangedSubview(self.infoButton)
        
        self.addSubview(contentStack)
        contentStack.autoPinEdge(.top, to: .top, of: self)
        contentStack.autoPinEdge(.bottom, to: .bottom, of: self)
        contentStack.autoPinWidthToSuperview(withMargin: 16)
    }
    
    @objc func setOnlyButtonActive(action:VinciConversationHeaderSubmenuActions) {
        
        searchButton.isSelected = false
        muteButton.isSelected = false
        callButton.isSelected = false
        infoButton.isSelected = false
        
        switch action {
        case .searchAction:
            searchButton.isSelected = true
            break
        case .muteAction:
            muteButton.isSelected = true
            break
        case .callAction:
            callButton.isSelected = true
            break
        case .infoAction:
            infoButton.isSelected = true
            break
        default:
            break
        }
    }
    
    @objc func disableButton(action:VinciConversationHeaderSubmenuActions) {
        switch action {
        case .searchAction:
            searchButton.isEnabled = false
            break
        case .muteAction:
            muteButton.isEnabled = false
            break
        case .callAction:
            callButton.isEnabled = false
            break
        case .infoAction:
            infoButton.isEnabled = false
            break
        default:
            break
        }
    }
    
    @objc func setUnmutedIcon() {
        muteButton.setImage(UIImage(named: "unmuteChat")?.asTintedImage(color: UIColor.gray), for: .normal)
        muteButton.setImage(UIImage(named: "unmuteChat")?.asTintedImage(color: UIColor.vinciBrandBlue), for: .selected)
    }
    
    @objc func setMutedIcon() {
        muteButton.setImage(UIImage(named: "table_ic_mute_thread")?.asTintedImage(color: UIColor.gray), for: .normal)
        muteButton.setImage(UIImage(named: "table_ic_mute_thread")?.asTintedImage(color: UIColor.vinciBrandBlue), for: .selected)
    }
    
    @objc func buttonDidPressed(sender: UIButton) {
        switch sender {
        case self.searchButton:
            self.delegate?.menuButtonDidPressed(action: .searchAction)
        case self.muteButton:
            self.delegate?.menuButtonDidPressed(action: .muteAction)
        case self.callButton:
            self.delegate?.menuButtonDidPressed(action: .callAction)
        case self.infoButton:
            self.delegate?.menuButtonDidPressed(action: .infoAction)
        default:
            self.delegate?.menuButtonDidPressed(action: .noAction)
        }
    }
}
