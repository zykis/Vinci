//
//  VinciRegTextField.swift
//  VinciWelcome
//
//  Created by Ilya Klemyshev on 03/06/2019.
//  Copyright © 2019 KimCo. All rights reserved.
//

import UIKit

@objc class VinciRegTextField: UIView {
    
    var textField:UITextField = UITextField()
    var titleLabel:UILabel?
    var title = ""
    var text = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(text:String, title:String, frame:CGRect) {
        super.init(frame: frame)
        self.text = text
        self.title = title
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        textField.frame = rect
        textField.text = self.text
        
        textField.font = UIFont(name: "Lucida Grande", size: 15.0)
        textField.font = textField.font!.withSize(15.0)
        
        self.addSubview(textField)
        
        if ( title != "" ) {
            titleLabel = UILabel()
            titleLabel!.font = UIFont(name: "Lucida Grande", size: 12.0)
            titleLabel!.font = titleLabel!.font.withSize(12.0)
            
            let bounds = textField.bounds
            
            var newBounds = bounds
            let size = (title as! NSString).size(withAttributes: [NSAttributedString.Key.font:titleLabel!.font])
            let width = bounds.size.width - size.width
            newBounds.origin.x = width
            newBounds.size.width = size.width
            
            titleLabel!.frame = newBounds
            addSubview(titleLabel!)
            
            if #available(iOS 10.0, *) {
                titleLabel?.textColor = UIColor.init(displayP3Red: 186/255, green: 188/255, blue: 184/255, alpha: 255/255)
            } else {
                // Fallback on earlier versions
            }
            titleLabel?.text = title
        }
        
        let underline = UIView(frame: CGRect(x: rect.origin.x + 2, y: rect.size.height, width: rect.size.width - 4, height: 1))
        underline.backgroundColor = UIColor.gray
        
        addSubview(underline)
    }
    
}
