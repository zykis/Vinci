//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let VinciChallengeCompactCellNibName = "VinciChallengeCompactCell"
let VinciChallengeCompactCellViewNibName = "VinciChallengeCompactCellView"
let VinciChallengeCompactCellReuseIdentifier = "VinciChallengeCompactCellRI"
let kCellMargin: CGFloat = 4.0
let kSecondsInDay: Double = 24 * 60 * 60

class VinciChallengeCompactCell: UITableViewCell {
    var compactCellView: UIView!
    var compactCellViewBottomConstraint: NSLayoutConstraint?
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var rewardLabel: UILabel!
    @IBOutlet var expiredInLabel: UILabel!
    @IBOutlet var likesLabel: UILabel!
    @IBOutlet var favouriteButton: UIButton!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addCompactCellView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func addCompactCellView() {
        let bundle = Bundle(for: type(of: self))
        let views = bundle.loadNibNamed(VinciChallengeCompactCellViewNibName, owner: self, options: nil)
        if let view = views?.first as? UIView {
            self.compactCellView = view
            self.contentView.addSubview(view)
        }
        
        self.compactCellView.translatesAutoresizingMaskIntoConstraints = false
        self.compactCellView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: kCellMargin).isActive = true
        self.compactCellView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -kCellMargin).isActive = true
        self.compactCellView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: kCellMargin).isActive = true
        self.compactCellViewBottomConstraint = self.compactCellView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -kCellMargin)
        self.compactCellViewBottomConstraint?.isActive = true
        
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
        if challenge.expirationDate?.timeIntervalSince(Date()) ?? 0.0 >= kSecondsInDay {
            let htmlString: String = "<p><font color=\"gray\">till </font><font color=\"black\"> \(challenge.expirationDate?.representation() ?? "???")</font></p>"
            if let attributedString = try? NSAttributedString(data: Data(htmlString.utf8),
                                                      options: [.documentType: NSAttributedString.DocumentType.html],
                                                      documentAttributes: nil) {
                self.expiredInLabel.attributedText = attributedString
            }
        } else {
            let htmlString: String = "<p><font color=\"gray\">ends in</font><font color=\"orange\"> less then a day</font></p>"
            if let attributedString = try? NSAttributedString(data: Data(htmlString.utf8),
                                                             options: [.documentType: NSAttributedString.DocumentType.html],
                                                             documentAttributes: nil) {
                self.expiredInLabel.attributedText = attributedString
            }
        }
        let amountAbbreviation: String = challenge.likes >= 1_000_000 ? "m" : challenge.likes >= 1_000 ? "k" : ""
        let amount: Double = challenge.likes > 1_000_000 ? Double(challenge.likes) / 1_000_000.0 : challenge.likes >= 1_000 ? Double(challenge.likes) / 1_000.0 : Double(challenge.likes)
        let formatType = amount >= 1_000 ? "%.1f" : "%i"
        self.likesLabel.text = String.init(format: formatType + amountAbbreviation, amount < 1_000 ? Int(amount) : amount)
    }
}
