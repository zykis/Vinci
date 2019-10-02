//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit


@IBDesignable class VinciTextView: UITextView {
    private var placeholderLabel: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = UIFont.systemFont(ofSize: 17.0)
        l.text = nil
        l.lineBreakMode = .byWordWrapping
        l.textColor = .lightGray
        return l
    }()
    
    @IBInspectable var placeholder: String? = nil {
        didSet {
            placeholderLabel.text = self.placeholder
            placeholderLabel.sizeToFit()
        }
    }
    @IBInspectable var placeholderColor: UIColor = .lightGray {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }
    
    override var font: UIFont? {
        didSet {
            placeholderLabel.font = self.font
        }
    }
    
    override var text: String! {
        didSet {
            checkPlaceholderVisibility()
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        addSubview(placeholderLabel)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VinciTextView.didBeginEditing(notification:)), name: .UITextViewTextDidBeginEditing, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(VinciTextView.didEndEditing(notification:)), name: .UITextViewTextDidEndEditing, object: self)
        checkPlaceholderVisibility()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let sizeThatFit = placeholderLabel.sizeThatFits(bounds.size)
        placeholderLabel.frame = CGRect(origin: CGPoint(x: 0, y: 0),
                                         size: sizeThatFit)
    }
    
    private func checkPlaceholderVisibility() {
        if text.isEmpty && !isFirstResponder {
            placeholderLabel.alpha = 1.0
        } else {
            placeholderLabel.alpha = 0.0
        }
    }
    
    @objc func didBeginEditing(notification: Notification) {
        checkPlaceholderVisibility()
    }
    
    @objc func didEndEditing(notification: Notification) {
        checkPlaceholderVisibility()
    }
}
