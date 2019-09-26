//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit


@IBDesignable class VinciCard: UIView {
    @IBInspectable @IBOutlet var contentView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        self.contentView = UIView()
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.clipsToBounds = true
        self.addSubview(self.contentView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //        self.contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        //        self.contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        //        self.contentView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        //        self.contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        self.contentView.layer.cornerRadius = self.layer.cornerRadius
    }
    
    @IBInspectable var cornerRadius: Double {
        get {
            return Double(self.layer.cornerRadius)
        }
        set {
            self.layer.cornerRadius = CGFloat(newValue)
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var borderWidth: Double {
        get {
            return Double(self.layer.borderWidth)
        }
        set {
            self.layer.borderWidth = CGFloat(newValue)
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
        set {
            self.layer.borderColor = newValue?.cgColor
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var shadowColor: UIColor? {
        get {
            return UIColor(cgColor: self.layer.shadowColor!)
        }
        set {
            self.layer.shadowColor = newValue?.cgColor
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var shadowOpacity: Double {
        get {
            return Double(self.layer.shadowOpacity)
        }
        set {
            self.layer.shadowOpacity = Float(newValue)
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var shadowOffset: CGSize {
        get {
            return self.layer.shadowOffset
        }
        set {
            self.layer.shadowOffset = newValue
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var masksToBounds: Bool {
        get {
            return self.layer.masksToBounds
        }
        set {
            self.layer.masksToBounds = newValue
            self.setNeedsDisplay()
        }
    }
}
