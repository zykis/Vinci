//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let VinciChallengeCompactCellNibName = "VinciChallengeCompactCell"
let VinciChallengeCompactCellViewNibName = "VinciChallengeCompactCellView"
let VinciChallengeCompactCellReuseIdentifier = "VinciChallengeCompactCellRI"

class VinciChallengeCompactCell: UITableViewCell {
    var compactCellView: UIView!
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var rewardLabel: UILabel!
    @IBOutlet var expiredInLabel: UILabel!
    @IBOutlet var likesLabel: UILabel!
    @IBOutlet var favouriteButton: UIButton!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let bundle = Bundle(for: type(of: self))
        let views = bundle.loadNibNamed(VinciChallengeCompactCellViewNibName, owner: self, options: nil)
        if let view = views?.first as? UIView {
            self.compactCellView = view
            self.contentView.addSubview(view)
//            self.contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
//            self.contentView.frame = self.bounds
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.compactCellView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 4.0).isActive = true
        self.compactCellView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -4.0).isActive = true
        self.compactCellView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 4.0).isActive = true
        self.compactCellView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -4.0).isActive = true
        
        self.iconImageView.layer.cornerRadius = iconImageView.bounds.height / 2.0
        self.iconImageView.clipsToBounds = true
        self.iconImageView.layer.borderColor = UIColor(white: 0.0, alpha: 0.2).cgColor
        self.iconImageView.layer.borderWidth = 0.5
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
