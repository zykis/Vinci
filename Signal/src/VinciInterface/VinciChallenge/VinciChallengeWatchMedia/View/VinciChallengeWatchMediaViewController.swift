//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import Foundation
import UIKit

let kMinTextViewHeight = 36.0
let kSeparatorBottomConstraintValue: CGFloat = 59.0
let kAnimationHideDuration = 0.2
let kCommentHeightRatio: CGFloat = 0.6
let kPlaceholderColor = UIColor(white: 1.0, alpha: 0.54)

class VinciChallengeWatchMediaViewController: VinciViewController {
    var presenter: VinciChallengeWatchMediaPresenterProtocol?
    
    var overlayView: UIView = {
        let v = UIView()
        v.backgroundColor = .black
        return v
    }()
    
    private var isCommentsViewPresented: Bool = false {
        didSet {
            if self.isCommentsViewPresented {
                // FIXME: code T_T
                view.bringSubview(toFront: commentTextField)
                UIView.animate(withDuration: 0.2, animations: {
                    self.commentTextField.backgroundColor = .white
                }) { (_) in
                    self.commentTextField.attributedPlaceholder = NSAttributedString(string: self.commentTextField.placeholder!,
                                                                                     attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightGray])
                }
                presentCommentsView()
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.commentTextField.backgroundColor = .clear
                }) { (_) in
                    self.commentTextField.attributedPlaceholder = NSAttributedString(string: self.commentTextField.placeholder!,
                                                                                     attributes: [NSAttributedStringKey.foregroundColor: kPlaceholderColor])
                }
                view.bringSubview(toFront: commentsView)
                hideCommentsView()
            }
        }
    }

    private var commentsTopAnimatableConstraint: NSLayoutConstraint? {
        return view.constraints.first(where: { (c) -> Bool in
            return ((c.firstItem as? VinciChallengeCommentsView == commentsView && c.secondItem as? UIView == view) ||
                (c.firstItem as? UIView == view && c.secondItem as? VinciChallengeCommentsView == commentsView))
                && c.firstAttribute == .top && c.secondAttribute == .top
                && c.isActive == true
        })
    }
    
    private let likedImage = UIImage(named: "icon_like_white_60")!
    private let unlikedImage = UIImage(named: "icon_like_white_empty_60")!
    private weak var inputAccessoryTextView: UITextView?
    private var isUiHidden: Bool = false
    
    private var commentsView: VinciChallengeCommentsView = {
        let cv = VinciChallengeCommentsView()
        return cv
    }()
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var mediaImageView: UIImageView!
    @IBOutlet var favouriteImageView: UIImageView!
    @IBOutlet var likeButton: VinciAnimatableButton!
    @IBOutlet var likeLabel: UILabel!
    @IBOutlet var commentsButton: VinciAnimatableButton!
    @IBOutlet var commentsLabel: UILabel!
    @IBOutlet var repostsLabel: UILabel!
    @IBOutlet var nicknameLabel: UILabel!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var commentTextField: UITextField!
    @IBOutlet var separator: UIView!
    var sendButton: UIButton?
    
    @IBOutlet var leftStackView: UIStackView!
    @IBOutlet var rightStackView: UIStackView!
    
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var navigationBarTopConstraint: NSLayoutConstraint!
    
    @IBAction func pop() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func sendButtonPressed(_ sender: UIButton) {
        if let comment = self.inputAccessoryTextView?.text {
            sender.isEnabled = false
            self.presenter?.postComment(comment: comment)
        }
    }
    
    @IBAction func likePressed() {
        guard let media = self.presenter?.media
            else { return }
        let newLiked = !media.userLike
        let newLikes = newLiked ? media.likes + 1 : max(0, media.likes - 1)
        let newMedia = Media(media: media)
        newMedia.likes = newLikes
        newMedia.userLike = newLiked
        
        // chaning locally, while waiting server response
        self.likeLabel.text = "\(newLikes)"
        self.likeButton.setImage(newLiked ? likedImage : unlikedImage, for: .normal)
        
        self.presenter?.likeOrUnlikeMedia()
    }
    
    @IBAction func commentsPressed() {
        isCommentsViewPresented = true
        self.presenter?.fetchComments()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.phase == .began {
                if (self.inputAccessoryTextView!.isFirstResponder) {
                    self.inputAccessoryTextView?.resignFirstResponder()
                    self.commentTextField.endEditing(true)
                } else if isCommentsViewPresented {
                    isCommentsViewPresented = false
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
//            self.bottomConstraint.constant = keyboardHeight
//            self.commentsTopAnimatableConstraint?.constant -= keyboardHeight
            self.navigationBarTopConstraint.constant = -keyboardHeight
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        guard
            let keyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect)?.height,
            let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? Double
        else { return }
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
//            self.bottomConstraint.constant = kSeparatorBottomConstraintValue
//            self.commentsTopAnimatableConstraint?.constant += keyboardHeight
            self.navigationBarTopConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func hideUI() {
        UIView.animate(withDuration: kAnimationHideDuration, animations: {
            self.leftStackView.alpha = 0.0
            self.rightStackView.alpha = 0.0
            self.commentTextField.alpha = 0.0
            self.separator.alpha = 0.0
        }) { (completed) in
            self.leftStackView.isHidden = true
            self.rightStackView.isHidden = true
            self.commentTextField.isHidden = true
            self.separator.isHidden = true
            
            self.isUiHidden = true
        }
    }
    
    func showUI() {
        self.leftStackView.isHidden = false
        self.rightStackView.isHidden = false
        self.commentTextField.isHidden = false
        self.separator.isHidden = false
        
        UIView.animate(withDuration: kAnimationHideDuration, animations: {
            self.leftStackView.alpha = 1.0
            self.rightStackView.alpha = 1.0
            self.commentTextField.alpha = 1.0
            self.separator.alpha = 1.0
        }) { (completed) in
            self.isUiHidden = false
        }
    }
    
    private func presentCommentsView() {
        if let tc = commentsTopAnimatableConstraint {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
                tc.constant = self.view.bounds.height * (1.0 - kCommentHeightRatio)
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    private func hideCommentsView() {
        if let tc = commentsTopAnimatableConstraint {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
                tc.constant = self.view.bounds.height
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
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
        inputTextView.inputTextViewDelegate = self
        inputTextView.textViewToolbarDelegate = self
        
        let sendButton = UIButton(type: .custom)
        self.sendButton = sendButton
        sendButton.addTarget(self, action: #selector(VinciChallengeWatchMediaViewController.sendButtonPressed(_:)), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(named: "sendMessageIcon"), for: .normal)
        toolbar.addSubview(sendButton)
        
        sendButton.widthAnchor.constraint(equalToConstant: 36.0).isActive = true
        sendButton.rightAnchor.constraint(equalTo: toolbar.rightAnchor, constant: -4.0).isActive = true
        sendButton.leftAnchor.constraint(equalTo: inputTextView.rightAnchor, constant: 4.0).isActive = true
        sendButton.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 4.0).isActive = true
        
        
        self.commentTextField.inputAccessoryView = toolbar
    }
}


// MARK: Lifecycle
extension VinciChallengeWatchMediaViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.shadowImage = UIImage()
        view.addSubview(commentsView)
        commentsView.delegate = self
        commentsView.viewController = self
        
        self.addInputAccessoryView()
        self.commentTextField.attributedPlaceholder = NSAttributedString(string: self.commentTextField.placeholder!,
                                                                         attributes: [NSAttributedStringKey.foregroundColor: kPlaceholderColor])
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VinciChallengeWatchMediaViewController.keyboardWillShow(notification:)),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(VinciChallengeWatchMediaViewController.keyboardWillHide(notification:)),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
        self.presenter?.fetchMedia(mediaID: (self.presenter?.mediaID)!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.addSubview(self.overlayView)
        self.overlayView.translatesAutoresizingMaskIntoConstraints = false
        self.overlayView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.overlayView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.overlayView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        self.overlayView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.isTranslucent = true
        self.view.bringSubview(toFront: navigationBar)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        print("WILLLAYOUTSUBVIEWCALLED")
        // FIXME: Multiple addition of same constraints
        commentsView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: view.bounds.height, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: view.bounds.height * kCommentHeightRatio + commentsView.layer.cornerRadius, enableInsets: false)
    }
}


extension VinciChallengeWatchMediaViewController: VinciChallengeWatchMediaViewProtocol {
    func update(media: Media) {
        if let mediaUrl = URL(string: media.url) {
            self.mediaImageView.downloadAndSetupImage(with: mediaUrl, completion: nil)
        }
        self.likeLabel.text = "\(media.likes)"
        self.likeButton.setImage(media.userLike ? likedImage : unlikedImage, for: .normal)
        self.commentsLabel.text = "\(media.comments)"
//        self.repostsLabel.text = "\(media.reposts)"
        self.descriptionTextView.text = media.description
    }
    
    func hideOverlay() {
        UIView.animate(withDuration: 0.15, animations: {
            self.overlayView.alpha = 0.0
        }) { (_) in
            self.overlayView.isHidden = true
        }
    }
    
    func likeOrUnlikeMediaSuccess() {
        self.presenter?.fetchMedia(mediaID: (self.presenter?.mediaID)!)
    }
    
    func likeOrUnlikeMediaFail(error: Error) {
        self.presenter?.fetchMedia(mediaID: (self.presenter?.mediaID)!)
    }
    
    func postingCommentFail(error: Error) {
        self.sendButton?.isEnabled = true
    }
    
    func postingCommentSuccess() {
        self.sendButton?.isEnabled = true
        // Clearing text
        self.inputAccessoryTextView?.text = nil
        self.commentTextField.text = nil
        // Dismissing keyboard
        self.inputAccessoryTextView?.resignFirstResponder()
        self.commentTextField.endEditing(true)
        // Fetch new comments, if comment view is open
        if isCommentsViewPresented {
            self.presenter?.fetchComments()
            self.commentsView.reloadData()
        }
        
        self.presenter?.fetchMedia(mediaID: (self.presenter?.mediaID)!)
    }
    
    func fetchCommentsSuccess() {
        commentsView.reloadData()
    }
}


extension VinciChallengeWatchMediaViewController: VinciChallengeCommentsViewProtocol {
    func closeButtonTapped() {
        isCommentsViewPresented = false
    }
}


extension VinciChallengeWatchMediaViewController: ConversationInputTextViewDelegate {
    func didPaste(_ attachment: SignalAttachment?) {
    }
    
    func inputTextViewSendMessagePressed() {
    }
    
    func textViewDidChange(_ textView: UITextView) {
    }
}


extension VinciChallengeWatchMediaViewController: ConversationTextViewToolbarDelegate {
}
