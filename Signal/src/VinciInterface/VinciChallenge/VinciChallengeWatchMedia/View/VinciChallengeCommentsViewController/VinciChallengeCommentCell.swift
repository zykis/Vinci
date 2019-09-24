//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let kVinciChallengeCommentCellReuseIdentifier = "VinciChallengeCommentCellRI"
let kLikedImage = "icon_like_black_60"
let kUnlikedImage = "icon_like_black_empty_60"
let kMargin: CGFloat = 8.0
let kAvatarImageSize: CGFloat = 36.0
let kLikeButtonSize: CGFloat = 24.0
let kEndpointLikeOrUnlikeComment = kHost + "likeComment"

class VinciChallengeCommentCell: UITableViewCell {
    var commentID: String? {
        return self.comment?.id
    }
    var comment: Comment?
    
    private var avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = kAvatarImageSize / 2.0
        iv.layer.borderColor = UIColor.lightGray.cgColor
        iv.layer.borderWidth = 1.0
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private var usernameLabel: UILabel = {
        let ul = UILabel()
        ul.textColor = .black
        ul.font = UIFont.boldSystemFont(ofSize: 16.0)
        ul.textAlignment = .left
        return ul
    }()
    
    private var commentLabel: UILabel = {
        let ctv = UILabel()
        ctv.textColor = .black
        ctv.font = UIFont.systemFont(ofSize: 14.0)
        ctv.textAlignment = .left
        ctv.numberOfLines = 0
        return ctv
    }()
    
    private var likeButton: VinciAnimatableButton = {
        let lb = VinciAnimatableButton()
        lb.setImage(UIImage(named: kUnlikedImage), for: .normal)
        lb.imageView?.contentMode = .scaleAspectFit
//        lb.addTarget(self, action: #selector(VinciChallengeCommentCell.likePressed), for: .touchUpInside)
        // FIXME: Why doesnt work here?
        return lb
    }()
    
    private var likesLabel: UILabel = {
        let ll = UILabel()
        ll.textColor = .black
        ll.font = UIFont.boldSystemFont(ofSize: 16.0)
        ll.textAlignment = .center
        return ll
    }()

    private var postedLabel: UILabel = {
        let pl = UILabel()
        pl.textColor = .lightGray
        pl.font = UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        pl.textAlignment = .left
        return pl
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        let cv = self.contentView
        
        cv.addSubview(self.avatarImageView)
        cv.addSubview(self.usernameLabel)
        cv.addSubview(self.commentLabel)
        cv.addSubview(self.likeButton)
        cv.addSubview(self.likesLabel)
        cv.addSubview(self.postedLabel)
        
        self.avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        self.avatarImageView.leftAnchor.constraint(equalTo: cv.leftAnchor, constant: kMargin).isActive = true
        self.avatarImageView.topAnchor.constraint(equalTo: cv.topAnchor, constant: kMargin).isActive = true
        self.avatarImageView.widthAnchor.constraint(equalToConstant: kAvatarImageSize).isActive = true
        self.avatarImageView.heightAnchor.constraint(equalTo: self.avatarImageView.widthAnchor, multiplier: 1.0).isActive = true
        
        self.usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.usernameLabel.leftAnchor.constraint(equalTo: self.avatarImageView.rightAnchor, constant: kMargin).isActive = true
        self.usernameLabel.topAnchor.constraint(equalTo: cv.topAnchor, constant: kMargin).isActive = true
        
        self.commentLabel.translatesAutoresizingMaskIntoConstraints = false
        self.commentLabel.topAnchor.constraint(equalTo: self.usernameLabel.bottomAnchor, constant: kMargin).isActive = true
        self.commentLabel.leftAnchor.constraint(equalTo: self.usernameLabel.leftAnchor).isActive = true
        self.commentLabel.rightAnchor.constraint(equalTo: self.likeButton.leftAnchor, constant: -kMargin).isActive = true
        
        self.postedLabel.translatesAutoresizingMaskIntoConstraints = false
        self.postedLabel.topAnchor.constraint(equalTo: self.commentLabel.bottomAnchor, constant: kMargin).isActive = true
        self.postedLabel.leftAnchor.constraint(equalTo: self.usernameLabel.leftAnchor).isActive = true
        self.postedLabel.bottomAnchor.constraint(equalTo: cv.bottomAnchor, constant: -kMargin).isActive = true
        
        self.likeButton.translatesAutoresizingMaskIntoConstraints = false
        self.likeButton.topAnchor.constraint(equalTo: cv.topAnchor, constant: kMargin).isActive = true
        self.likeButton.rightAnchor.constraint(equalTo: cv.rightAnchor, constant: -kMargin * 2).isActive = true
        self.likeButton.widthAnchor.constraint(equalToConstant: kLikeButtonSize).isActive = true
        self.likeButton.heightAnchor.constraint(equalTo: self.likeButton.widthAnchor, multiplier: 1.0).isActive = true
        self.likeButton.addTarget(self, action: #selector(VinciChallengeCommentCell.likePressed), for: .touchUpInside)
        
        self.likesLabel.translatesAutoresizingMaskIntoConstraints = false
        self.likesLabel.centerXAnchor.constraint(equalTo: self.likeButton.centerXAnchor).isActive = true
        self.likesLabel.topAnchor.constraint(equalTo: self.likeButton.bottomAnchor, constant: kMargin).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    @objc func likePressed() {
        if let commentID = self.commentID {
            self.likeOrUnlikeComment(commentID: commentID, completion: nil)
        } else {
            fatalError("cant get comment ID")
        }
    }
    
    func likeOrUnlikeComment(commentID: String, completion: ((Comment) -> Void)?) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        guard
            let url = URL(string: kEndpointLikeOrUnlikeComment)
            else { return }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = "SIGNALID=\(signalID)&MEDIACOMMENTID=\(commentID)".data(using: .utf8)
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data
                else { return }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any]
                let userLike: Bool = json!["USERLIKE"] as! Bool
                let likes: Int = json!["LIKES"] as! Int
                DispatchQueue.main.async {
                    self.comment?.userLike = userLike
                    self.comment?.likes = likes
                    self.setup(comment: (self.comment?.presenter())!)
                }
            } catch {
                print(error)
            }
            
        }
        task.resume()
    }
    
    func setup(comment: CommentPresenter) {
        if let avatarUrl = comment.avatarUrl, let url = URL(string: avatarUrl) {
            self.avatarImageView.downloadAndSetupImage(with: url, completion: nil)
        }
        self.usernameLabel.text = comment.username
        self.commentLabel.text = comment.text
        self.likeButton.setImage(UIImage(named: comment.userLike ? kLikedImage : kUnlikedImage), for: .normal)
        self.likesLabel.text = comment.likes
        self.postedLabel.text = comment.posted
    }
    
    override func prepareForReuse() {
        self.avatarImageView.image = nil
        self.usernameLabel.text = nil
        self.commentLabel.text = nil
        self.likeButton.setImage(UIImage(named: kUnlikedImage), for: .normal)
        self.likesLabel.text = nil
        self.postedLabel.text = nil
    }
}
