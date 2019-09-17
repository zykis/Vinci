//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit


@IBDesignable class VinciButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return self.layer.cornerRadius
        }
        set {
            self.layer.cornerRadius = newValue
        }
    }
}
