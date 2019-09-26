//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let VinciChallengeCompactCellNibName = "VinciChallengeCompactCell"
let VinciChallengeCompactCellViewNibName = "VinciChallengeCompactCellView"
let VinciChallengeCompactCellReuseIdentifier = "VinciChallengeCompactCellRI"
let kCellMargin: CGFloat = 4.0
let kSecondsInDay: Double = 24 * 60 * 60
let kEndpointFavourChallenge = kHost + "favChallenge"
let kFavouriteImage = "icon_favourite_filled_32"
let kUnfavouriteImage = "icon_favourite_empty_32"


protocol VinciChallengeMoveToChallengeProtocol {
    func moveToChallenge(challengeID: String)
}


class VinciChallengeCompactCell: UITableViewCell {
    private var challengeID: String? {
        return self.challenge?.id
    }
    private var challenge: Challenge?
    var delegate: VinciChallengeMoveToChallengeProtocol?
    
    private let tapGestureRecognizer: UITapGestureRecognizer = {
        let gr = UITapGestureRecognizer()
        return gr
    }()
    
    var compactCellView: UIView!
    var compactCellViewBottomConstraint: NSLayoutConstraint?
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var rewardLabel: UILabel!
    @IBOutlet var expiredInLabel: UILabel!
    @IBOutlet var likesLabel: UILabel!
    @IBOutlet var favouriteButton: VinciAnimatableButton!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addCompactCellView()
        
        tapGestureRecognizer.addTarget(self, action: #selector(VinciChallengeCompactCell.moveToGame))
        compactCellView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    @objc func moveToGame() {
        print("moving to game with id: \(challengeID ?? "nil")")
        delegate?.moveToChallenge(challengeID: challengeID!)
    }
    
    func addCompactCellView() {
        let bundle = Bundle(for: type(of: self))
        let views = bundle.loadNibNamed(VinciChallengeCompactCellViewNibName, owner: self, options: nil)
        if let view = views?.first as? UIView {
            self.compactCellView = view
            self.contentView.addSubview(view)
        }
        
        self.favouriteButton.addTarget(self, action: #selector(VinciChallengeCompactCell.favouriteButtonPressed), for: .touchDown)
        
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
    
    @objc func favouriteButtonPressed() {
        let newFavourite: Bool = !self.challenge!.favourite
        self.favouriteButton.setImage(UIImage(named: newFavourite ? kFavouriteImage : kUnfavouriteImage), for: .normal)
        self.favourChallenge()
    }
    
    func favourChallenge() {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        guard
            let url = URL(string: kEndpointFavourChallenge)
            else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = "SIGNALID=\(signalID)&CHID=\(self.challengeID!)".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data
                else { return }
            do {
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: []) as! [AnyHashable: Any]
                let favourite = jsonObj["USERFAV"] as! Bool
                self.challenge?.favourite = favourite
                DispatchQueue.main.async {
                    self.favouriteButton.setImage(UIImage(named: favourite ? kFavouriteImage: kUnfavouriteImage), for: .normal)
                }
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    
    func setup(with challenge: Challenge) {
        self.challenge = challenge
        self.cleanUpWithColor(color: .clear)
        
        if let iconUrl = challenge.iconUrl {
            if let url = URL(string: iconUrl) {
                self.iconImageView.downloadAndSetupImage(with: url, completion: nil)
            }
        }
        self.titleLabel.text = challenge.title
        self.rewardLabel.text = "$\(challenge.reward)"
        self.favouriteButton.setImage(UIImage(named: challenge.favourite ? kFavouriteImage: kUnfavouriteImage), for: .normal)
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.cleanUp()
    }
    
    func cleanUp() {
        let lightGray = UIColor.init(white: 0.95, alpha: 1.0)
        self.cleanUpWithColor(color: lightGray)
    }
    
    private func cleanUpWithColor(color: UIColor) {
        self.iconImageView.image = nil
        self.iconImageView.backgroundColor = color
        
        self.titleLabel.text = nil
        self.titleLabel.backgroundColor = color
        
        self.rewardLabel.text = nil
        self.rewardLabel.backgroundColor = color
        
        self.expiredInLabel.text = nil
        self.expiredInLabel.backgroundColor = color
        
        self.likesLabel.text = nil
        self.likesLabel.backgroundColor = color
    }
}
