//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

protocol VinciInviteTabPanelDelegate {
    func inviteButtonPressed()
}

class UILabelWithInsets : UILabel {
    override func drawText(in rect: CGRect) {
        let labelInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, labelInsets))
    }
}

class VinciInviteTabPanel: UIView {
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    var countLabel: InsetLabel!
    var delegate:VinciInviteTabPanelDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let editModeStack = UIStackView()
        editModeStack.axis = .horizontal
        editModeStack.alignment = .center
        editModeStack.spacing = 8
        
        countLabel = InsetLabel()
        countLabel.insets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        countLabel.textColor = UIColor.white
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 24).isActive = true
        countLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
        countLabel.layer.backgroundColor = UIColor.vinciBrandBlue.cgColor
        countLabel.textAlignment = .center
        countLabel.layer.cornerRadius = 12.0
        countLabel.text = "0"
        
        let inviteButton = UIButton(type: .custom)
        inviteButton.setTitle("Invites to Vinci", for: .normal)
        inviteButton.setTitleColor(UIColor.vinciBrandBlue, for: .normal)
        
        editModeStack.addArrangedSubview(countLabel)
        editModeStack.addArrangedSubview(inviteButton)
        
        addSubview(editModeStack)
        editModeStack.autoHCenterInSuperview()
        editModeStack.autoPinBottomToSuperviewMargin()
        editModeStack.autoPinTopToSuperviewMargin(withInset: 8)
        
        let topLine = UIView()
        topLine.autoSetDimension(.height, toSize: 0.5)
        topLine.backgroundColor = Theme.cellSeparatorColor
        
        addSubview(topLine)
        topLine.autoPinWidthToSuperview()
        topLine.topAnchor.constraint(equalTo: self.topAnchor, constant: -1)
    }
    
    func setCount(count: Int) {
        countLabel.text = "\(count)"
    }
}
