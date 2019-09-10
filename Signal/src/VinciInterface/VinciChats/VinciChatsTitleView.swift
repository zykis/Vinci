//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc protocol VinciChatsTitleViewDelegate {
    func titleDidPressed()
    func lockDidPressed()
}

@objc class VinciChatsTitleView: UIView {
    
    var lockIcon = UIImageView(frame: CGRect.zero)
    var chatNameLabel = UILabel(frame: CGRect.zero)
    var statusLabel = UILabel(frame: CGRect.zero)
    
    var topRowStack = UIStackView(frame: CGRect.zero)
    var bottomRowStack = UIStackView(frame: CGRect.zero)
    var viewStack = UIStackView(frame: CGRect.zero)
    
    var thread:TSThread?
    
    @objc public var delegate: VinciChatsTitleViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    @objc init(thread:TSThread?) {
        super.init(frame: CGRect.zero)
        self.thread = thread
        
        commonInit()
    }
    
    func commonInit() {
        
        chatNameLabel.isUserInteractionEnabled = true
        lockIcon.isUserInteractionEnabled = true
        
        chatNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleLabelDidPressed)))
        lockIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(lockIconDidPressed)))
        
        lockIcon.image = UIImage(named: "chatLockIcon")
        if thread != nil {
            chatNameLabel.text = thread!.name()
            statusLabel.text = "last seen recently"
            statusLabel.textColor = UIColor.lightGray
        }
        
        topRowStack.axis = .horizontal
        topRowStack.alignment = .center
        topRowStack.spacing = 8
        
        topRowStack.addArrangedSubview(lockIcon)
        topRowStack.addArrangedSubview(chatNameLabel)
        
        bottomRowStack.axis = .horizontal
        bottomRowStack.alignment = .center
        bottomRowStack.spacing = 8
        
        bottomRowStack.addArrangedSubview(statusLabel)
        
        viewStack.axis = .vertical
        viewStack.alignment = .center
        viewStack.addArrangedSubview(topRowStack)
        viewStack.addArrangedSubview(bottomRowStack)
        
        addSubview(viewStack)
        viewStack.autoPinEdgesToSuperviewEdges()
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    @objc func titleLabelDidPressed() {
        delegate?.titleDidPressed()
    }
    
    @objc func lockIconDidPressed() {
        delegate?.lockDidPressed()
    }
    
}
