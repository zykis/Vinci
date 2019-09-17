//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit


class VinciChallengeAccountCell: UITableViewCell {
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    
    func setup(iconName: String, title: String) {
        self.iconImageView.image = UIImage(named: iconName)
        self.titleLabel.text = title
    }
}
