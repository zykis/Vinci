//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

class VinciAvatarWithIcon: UIView {
    
    let kStandardAvatarSize = 48
    let kLargeAvatarSize = 68
    var iconImageView = UIImageView(image: UIImage(named: "editArchiveIcon"))
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.backgroundColor = UIColor.vinciBrandBlue.cgColor
        layer.cornerRadius = CGFloat(kStandardAvatarSize / 2)
        layer.borderColor = Theme.cellSeparatorColor.cgColor
        layer.borderWidth = 1.0
        iconImageView.autoSetDimensions(to: CGSize(width: CGFloat(kStandardAvatarSize / 3), height: CGFloat(kStandardAvatarSize / 3)))
        
        addSubview(iconImageView)
        iconImageView.autoCenterInSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
    }
    
}
