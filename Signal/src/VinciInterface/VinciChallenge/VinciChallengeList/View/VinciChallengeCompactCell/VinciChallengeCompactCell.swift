//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation

let VinciChallengeCompactCellNibName = "VinciChallengeCompactCell"
let VinciChallengeCompactCellReuseIdentifier = "VinciChallengeCompactCellRI"

class VinciChallengeCompactCell: UITableViewCell {
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var rewardLabel: UILabel!
    @IBOutlet var expiredInLabel: UILabel!
    @IBOutlet var likesLabel: UILabel!
    @IBOutlet var favouriteButton: UIButton!
    
    func commonInit() {
        iconImageView.layer.cornerRadius = iconImageView.bounds.height / 2.0
        iconImageView.clipsToBounds = true
        iconImageView.layer.borderColor = UIColor(white: 0.0, alpha: 0.2).cgColor
        iconImageView.layer.borderWidth = 0.5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.commonInit()
    }
    
    func setup(with challenge: Challenge) {
        if let iconUrl = challenge.iconUrl {
            if let url = URL(string: iconUrl) {
                self.iconImageView.downloadAndSetupImage(with: url, completion: nil)
            }
        }
        self.titleLabel.text = challenge.title
        self.rewardLabel.text = "$\(challenge.reward)"
        if challenge.expirationDate?.timeIntervalSince(Date()) ?? 0.0 >= 24 * 60 * 60 {
            self.expiredInLabel.text = "till \(challenge.expirationDate?.representation() ?? "???")"
        } else {
            self.expiredInLabel.text = "ends in less, then a day"
        }
    }
}
