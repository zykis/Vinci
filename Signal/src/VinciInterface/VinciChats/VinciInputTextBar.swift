//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

@objc protocol VinciInputTextBarDelegate {
    func stickerButtonDidPressed()
    func timerButtonDidPressed()
}

@objc class VinciInputTextBar: UIView {
    
    @objc public let inputTextView = ConversationInputTextView()
    let stickerButton = UIButton(frame: CGRect.zero)
    let timerButton = UIButton(frame: CGRect.zero)
    
    @objc public var delegate: VinciInputTextBarDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    init() {
        super.init(frame: CGRect.zero)
        commonInit()
    }
    
    func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(inputTextView)
        inputTextView.autoPinEdgesToSuperviewEdges()
        
        stickerButton.setImage(UIImage(named: "plusStickerIcon"), for: .normal)
        timerButton.setImage(UIImage(named: "plusTimerIcon"), for: .normal)
        
        stickerButton.addTarget(self, action: #selector(stickerButtonDidPressed), for: .touchUpInside)
        timerButton.addTarget(self, action: #selector(timerButtonDidPressed), for: .touchUpInside)
        
        stickerButton.autoSetDimensions(to: CGSize(width: 25.0, height: 25.0))
        timerButton.autoSetDimensions(to: CGSize(width: 25.0, height: 25.0))
        
        addSubview(timerButton)
        addSubview(stickerButton)
        
        timerButton.autoPinEdge(.bottom, to: .bottom, of: self, withOffset: -4.0)
        timerButton.autoPinEdge(.right, to: .right, of: self, withOffset: -8.0)
        
        stickerButton.autoPinEdge(.bottom, to: .bottom, of: self, withOffset: -4.0)
        stickerButton.autoPinEdge(.right, to: .left, of: timerButton, withOffset: -8.0)
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    @objc func stickerButtonDidPressed() {
        delegate?.stickerButtonDidPressed()
    }
    
    @objc func timerButtonDidPressed() {
        delegate?.timerButtonDidPressed()
    }

}
