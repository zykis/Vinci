//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit


let _kMinTextViewHeight: CGFloat = 36
let _kMaxTextViewHeight: CGFloat = 98


class VinciToolbar: UIToolbar {
    var textViewHeight: CGFloat = 0.0
    var textViewHeightConstraint: NSLayoutConstraint = NSLayoutConstraint()
    var inputTextView: UITextView = UITextView()
    
    func ensureTextViewHeight() {
        updateHeight(with: inputTextView)
    }
    
    func updateHeight(with textView: UITextView) {
        let currentSize = textView.frame.size
        let newHeight = clampedHeight(with: textView, fixedWidth: currentSize.width)
        
        if newHeight != textViewHeight {
            textViewHeight = newHeight
            textViewHeightConstraint.constant = newHeight
            invalidateIntrinsicContentSize()
        }
    }
    
    func clampedHeight(with textView: UITextView, fixedWidth: CGFloat) -> CGFloat {
        let fixedWidthSize = CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude)
        let contentSize = textView.sizeThatFits(fixedWidthSize)
        
        return CGFloatClamp(contentSize.height, _kMinTextViewHeight, _kMaxTextViewHeight)
    }
}
