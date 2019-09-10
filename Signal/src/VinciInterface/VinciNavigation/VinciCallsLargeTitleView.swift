//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

class VinciCallsLargeTitleView: VinciTopMenuRowView {
    
    var titleLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.text = "Calls"
        titleLabel.font = VinciStrings.largeTitleFont
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15.0).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0.0).isActive = true
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
    }
    
    override func update(newHeight: CGFloat) {
        
        let selfHeight = newHeight
        let largeTitleFontSize = VinciStrings.largeTitleFont.pointSize
        let fontSize = (largeTitleFontSize - 17.0) * selfHeight / 42.0 + 17.0
        
        titleLabel.font = VinciStrings.largeTitleFont.withSize(fontSize)
        
        let heightDiff = 42.0 - selfHeight
        titleLabel.alpha = heightDiff > 15 ? 0.0 : 1 - heightDiff / 15.0
    }
}
