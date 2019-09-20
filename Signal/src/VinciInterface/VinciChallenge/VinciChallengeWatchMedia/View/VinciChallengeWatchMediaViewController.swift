//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import UIKit

let kMinTextViewHeight = 36.0
let kSeparatorBottomConstraintValue: CGFloat = 59.0
let kAnimationHideDuration = 0.2

class VinciChallengeWatchMediaViewController: VinciViewController, VinciChallengeWatchMediaViewProtocol {
    var presenter: VinciChallengeWatchMediaPresenterProtocol?
    
    private let likedImage = UIImage(named: "icon_like_white_60")!
    private let unlikedImage = UIImage(named: "icon_like_white_empty_60")!
    private weak var inputAccessoryTextView: UITextView?
    private var isUiHidden: Bool = false
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var mediaImageView: UIImageView!
    @IBOutlet var favouriteImageView: UIImageView!
    @IBOutlet var likeButton: VinciAnimatableButton!
    @IBOutlet var likeLabel: UILabel!
    @IBOutlet var commentsLabel: UILabel!
    @IBOutlet var repostsLabel: UILabel!
    @IBOutlet var nicknameLabel: UILabel!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var commentTextField: UITextField!
    
    @IBOutlet var leftStackView: UIStackView!
    @IBOutlet var rightStackView: UIStackView!
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var navigationBarTopConstraint: NSLayoutConstraint!
    
    @IBAction func pop() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func likePressed() {
        guard let media = self.presenter?.media
            else { return }
        let newLiked = !media.userLike
        let newLikes = newLiked ? media.likes + 1 : max(0, media.likes - 1)
        media.likes = newLikes
        media.userLike = newLiked
        
        // chaning locally, while waiting server response
        self.update(with: media)
        
        self.presenter?.likeOrUnlikeMedia(like: newLiked)
    }
    
    func likeOrUnlikeMediaSuccess() {
        self.update(with: (self.presenter?.media)!)
    }
    
    func likeOrUnlikeMediaFail() {
        self.update(with: (self.presenter?.media)!)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.phase == .began {
                if (self.inputAccessoryTextView!.isFirstResponder) {
                    self.commentTextField.resignFirstResponder()
                } else {
                    if self.isUiHidden {
                        self.showUI()
                    } else {
                        self.hideUI()
                    }
                }
            }
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        guard
            let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect)?.height,
            let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        self.inputAccessoryTextView?.becomeFirstResponder()
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
            self.bottomConstraint.constant = keyboardHeight
            self.navigationBarTopConstraint.constant = -keyboardHeight
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        guard
//            let keyboardHeight = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? CGRect)?.height,
            let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
            self.bottomConstraint.constant = kSeparatorBottomConstraintValue
            self.navigationBarTopConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func hideUI() {
        UIView.animate(withDuration: kAnimationHideDuration, animations: {
//            self.likeButton.alpha = 0.0
//            self.likeLabel.alpha = 0.0
            self.leftStackView.alpha = 0.0
            self.rightStackView.alpha = 0.0
        }) { (completed) in
//            self.likeButton.isHidden = true
//            self.likeLabel.isHidden = true
            self.leftStackView.isHidden = true
            self.rightStackView.isHidden = true
            self.isUiHidden = true
        }
    }
    
    func showUI() {
//        self.likeButton.isHidden = false
//        self.likeLabel.isHidden = false
        self.leftStackView.isHidden = false
        self.rightStackView.isHidden = false
        
        UIView.animate(withDuration: kAnimationHideDuration, animations: {
//            self.likeButton.alpha = 1.0
//            self.likeLabel.alpha = 1.0
            self.leftStackView.alpha = 1.0
            self.rightStackView.alpha = 1.0
        }) { (completed) in
            self.isUiHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.isTranslucent = true
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.addInputAccessoryView()
        let placeholderColor = UIColor(white: 1.0, alpha: 0.54)
        self.commentTextField.attributedPlaceholder = NSAttributedString(string: self.commentTextField.placeholder!,
                                                                         attributes: [NSAttributedStringKey.foregroundColor: placeholderColor])
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VinciChallengeWatchMediaViewController.keyboardWillShow(notification:)),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VinciChallengeWatchMediaViewController.keyboardWillHide(notification:)),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
        self.presenter?.startFetchMedia(with: (self.presenter?.mediaID)!)
    }
    
    func update(with media: Media) {
        if let mediaUrl = URL(string: media.url) {
            self.mediaImageView.downloadAndSetupImage(with: mediaUrl, completion: nil)
        }
        self.likeLabel.text = "\(media.likes)"
        self.likeButton.setImage(media.userLike ? likedImage : unlikedImage, for: .normal)
        self.descriptionTextView.text = media.description
    }
    
    @objc func sendMessagePressed() {
        if let comment = self.commentTextField.text {
            self.presenter?.startPostingComment(comment: comment)
        }
    }
    
    func postingCommentSuccess() {
        self.commentTextField.text = nil
        self.commentTextField.resignFirstResponder()
    }
    
    func addInputAccessoryView() {
        let toolbar = UIView(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: self.view.bounds.width,
                                              height: 44.0))
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = .white
        let inputTextView = ConversationInputTextView()
        self.inputAccessoryTextView = inputTextView
        toolbar.addSubview(inputTextView)
        inputTextView.layer.cornerRadius = CGFloat(kMinTextViewHeight / 2.0)
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.leftAnchor.constraint(equalTo: toolbar.leftAnchor, constant: 4.0).isActive = true
        inputTextView.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 4.0).isActive = true
        inputTextView.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: -4.0).isActive = true
        inputTextView.delegate = self
        
        let sendButton = UIButton(type: .custom)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(named: "sendMessageIcon"), for: .normal)
        sendButton.addTarget(self, action: #selector(VinciChallengeWatchMediaViewController.sendMessagePressed), for: .touchUpInside)
        toolbar.addSubview(sendButton)
        
        sendButton.widthAnchor.constraint(equalToConstant: 36.0).isActive = true
        sendButton.rightAnchor.constraint(equalTo: toolbar.rightAnchor, constant: -4.0).isActive = true
        sendButton.leftAnchor.constraint(equalTo: inputTextView.rightAnchor, constant: 4.0).isActive = true
        sendButton.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 4.0).isActive = true
//        sendButton.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: -4.0).isActive = true
        
        self.commentTextField.inputAccessoryView = toolbar
    }
}


extension VinciChallengeWatchMediaViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        print("TEXT: \(textView.text)")
    }
}


extension VinciChallengeWatchMediaViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
