//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit
import CoreLocation


enum GameState {
    case new
    case existing
}


protocol GameStatable {
    func initialSetup(state: GameState)
}


let kPlusImage = "icon_plus_white_64"
let kFavouriteImageWhite = "icon_favourite_white_40"
let kUnfavouriteImageWhite = "icon_favourite_white_empty_60"
let kSaveGameButtonBottomConstraintConstantExisting: CGFloat = 28.0
let kExpandedSubviewHeightMultiplier: CGFloat = 0.65
let kCompactSubviewHeightMultiplier: CGFloat = 0.4
let kCollectionCellReuseIdentifier = "kCollectionCellRI"


class VinciChallengeGameViewController: VinciViewController {
    var presenter: VinciChallengeGamePresenterProtocol?
    
    var gameState: GameState
    var challengeID: String?
    
    @IBOutlet weak var changePhotoButton: UIButton!
    @IBOutlet weak var favouriteButton: VinciAnimatableButton!
    @IBOutlet weak var saveGameButton: UIButton!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var rewardTextField: UITextField!
    @IBOutlet weak var rewardStackView: UIStackView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationStackView: UIStackView!
    @IBOutlet weak var startTextField: UITextField!
    @IBOutlet weak var startStackView: UIStackView!
    @IBOutlet weak var endTextField: UITextField!
    @IBOutlet weak var endStackView: UIStackView!
    @IBOutlet weak var resultsTextField: UITextField!
    @IBOutlet weak var resultsStackView: UIStackView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var subview: UIView!
    @IBOutlet weak var inputAccessoryTextView: UIView?
    
    private var activityIndicatorView: UIActivityIndicatorView?
    @IBOutlet var subviewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var saveGameButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet var saveGameButtonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var saveGameButtonTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var saveGameButtonHeightConstraint: NSLayoutConstraint!
    
    private var selectedImageFrame: CGRect?
    private var selectedImage: UIImage?
    
    private var _lat: Double?
    private var _lon: Double?
    
    let imagePicker: UIImagePickerController = {
        let ip = UIImagePickerController()
        ip.sourceType = .photoLibrary
        ip.allowsEditing = true
        return ip
    }()
    
    private let locationManager: CLLocationManager = {
        let lm = CLLocationManager()
        lm.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        return lm
    }()
    
    private let datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        dp.datePickerMode = .date
        return dp
    }()
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        return df
    }()
    
    private var saveButtonEnabled: Bool {
        guard
            rewardTextField.text?.isEmpty == false,
            titleTextField.text?.isEmpty == false,
            avatarImageView.image != nil,
            startTextField.text?.isEmpty == false,
            endTextField.text?.isEmpty == false,
            resultsTextField.text?.isEmpty == false
        else { return false }
        return true
    }
    
    convenience init(gameState: GameState, nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.gameState = gameState
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.gameState = .new
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func addInputAccessoryView(for textField: UITextField, with selection: Selector?) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelDatePicker))
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: selection)
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        
        textField.inputAccessoryView = toolbar
    }
    
    private func addInputAccessoryTextView() {
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
        
        let doneButton = UIButton(type: .custom)
        doneButton.addTarget(inputTextView, action: #selector(ConversationInputTextView.resignFirstResponder), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(doneButton)
        
        doneButton.rightAnchor.constraint(equalTo: toolbar.rightAnchor, constant: -4.0).isActive = true
        doneButton.leftAnchor.constraint(equalTo: inputTextView.rightAnchor, constant: 4.0).isActive = true
        doneButton.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 4.0).isActive = true
        
        self.descriptionTextView.inputAccessoryView = toolbar
    }
    
    private func createChallenge() -> Challenge? {
        guard
        let title = titleTextField.text,
        let description = descriptionTextView.text,
        let sd = startTextField.text,
        let startDate = dateFormatter.date(from: sd),
        let ed = endTextField.text,
        let endDate = dateFormatter.date(from: ed),
        let rd = resultsTextField.text,
        let expirationDate = dateFormatter.date(from: rd),
        let rw = rewardTextField.text,
        let reward = Double(rw)
            else { return nil }
        
        let challenge: Challenge = Challenge(id: "", title: title, description: description, start: startDate, end: endDate, expiration: expirationDate, reward: reward, latitude: self._lat, longitude: self._lon, tags: [])
        return challenge
    }
    
    private func updateControls(for gameState: GameState) {
        if gameState == .new {
            descriptionTextView.text = kPlaceholderText
            descriptionTextView.textColor = .lightGray
            
            startTextField.text = dateFormatter.string(from: Date())
            endTextField.text = dateFormatter.string(from: Date().addingTimeInterval(7 * 24 * 60 * 60))
            resultsTextField.text = dateFormatter.string(from: Date().addingTimeInterval(8 * 24 * 60 * 60))
        } else if gameState == .existing {
            locationManager.stopUpdatingLocation()
            titleTextField.isEnabled = false
            rewardTextField.isEnabled = false
            changePhotoButton.isHidden = true
            startTextField.isEnabled = false
            endTextField.isEnabled = false
            resultsTextField.isEnabled = false
            descriptionTextView.isEditable = false
            favouriteButton.isHidden = false
            saveGameButton.isEnabled = true
        }
    }
    
    func update(with challenge: Challenge) {
        titleTextField.text = challenge.title
        rewardTextField.text = "\(challenge.reward)"
        descriptionTextView.text = challenge.description
        startTextField.text = dateFormatter.string(from: challenge.startDate)
        endTextField.text = dateFormatter.string(from: challenge.endDate!)
        resultsTextField.text = dateFormatter.string(from: challenge.expirationDate!)
        if let avatarUrl = challenge.avatarUrl, let url = URL(string: avatarUrl) {
            avatarImageView.downloadAndSetupImage(with: url, completion: nil)
        }
        favouriteButton.setImage(UIImage(named: challenge.favourite ? kFavouriteImageWhite : kUnfavouriteImageWhite), for: .normal)
        
        if let lat = challenge.latitude, let lon = challenge.longitude {
            let location = CLLocation(latitude: lat, longitude: lon)
            location.representation { (representation) in
                DispatchQueue.main.async {
                    self.locationLabel.text = representation
                }
            }
        }
    }
}


// MARK: Lifecycle
extension VinciChallengeGameViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        updateControls(for: gameState)
        
        // FIXME: Use RxSwift
        saveGameButton.isEnabled = saveButtonEnabled
        saveGameButton.translatesAutoresizingMaskIntoConstraints = false
        
        rewardTextField.keyboardType = .numberPad
        rewardTextField.delegate = self
        
        startTextField.inputView = datePicker
        addInputAccessoryView(for: startTextField, with: #selector(VinciChallengeGameViewController.startDatePicked))
        endTextField.inputView = datePicker
        addInputAccessoryView(for: endTextField, with: #selector(VinciChallengeGameViewController.endDatePicked))
        resultsTextField.inputView = datePicker
        addInputAccessoryView(for: resultsTextField, with: #selector(VinciChallengeGameViewController.resultsDatePicked))
        
        descriptionTextView.delegate = self
        locationManager.delegate = self
        imagePicker.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(VinciChallengeCollectionSmallCell.self, forCellWithReuseIdentifier: kCollectionCellReuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // fetching challenge if loading existing one
        if gameState == .existing, let challengeID = challengeID {
            presenter?.fetchChallenge(challengeID: challengeID, completion: { (challenge) in
                self.update(with: challenge)
                self.collectionView.reloadData()
            })
        }
        
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.isTranslucent = true
        
        rewardTextField.attributedPlaceholder = NSAttributedString(string: rewardTextField.placeholder!,
                                                                   attributes: [NSAttributedStringKey.foregroundColor: UIColor(white: 1.0, alpha: 0.54)])
        titleTextField.attributedPlaceholder = NSAttributedString(string: titleTextField.placeholder!,
                                                                  attributes: [NSAttributedStringKey.foregroundColor: UIColor(white: 1.0, alpha: 0.54)])
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if gameState == .existing {
            initialSetup(state: .existing)
        } else {
            initialSetup(state: .new)
        }
        
        saveGameButton.layer.cornerRadius = saveGameButton.bounds.height / 2.0
    }
}


// MARK: User input
extension VinciChallengeGameViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.phase == .began {
                view.endEditing(true)
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func changePhotoPressed(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func favouriteButtonPressed() {
        if let ch = self.presenter?.challenge {
            let newFav = !ch.favourite
            self.favouriteButton.setImage(UIImage(named: newFav ? kFavouriteImage : kUnfavouriteImage), for: .normal)
            ChallengeAPIManager.shared.favourChallenge(challengeID: ch.id) { (newFavourite) in
                self.favouriteButton.setImage(UIImage(named: newFavourite ? kFavouriteImage : kUnfavouriteImage), for: .normal)
            }
        }
    }
    
    @IBAction func saveGamePressed() {
        if gameState == .existing {
            if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
                present(imagePicker, animated: true, completion: nil)
            }
        } else {
            let height = saveGameButton.bounds.height
            saveGameButtonLeadingConstraint.isActive = false
            saveGameButtonTrailingConstraint.isActive = false
            saveGameButtonHeightConstraint.isActive = false
            
            self.activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 0,
                                                                               y: 0,
                                                                               width: height,
                                                                               height: height))
            self.activityIndicatorView!.alpha = 0.0
            saveGameButton.addSubview(self.activityIndicatorView!)
            self.activityIndicatorView!.startAnimating()
            
            if let sb = self.saveGameButton {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: {
                    
                    sb.heightAnchor.constraint(equalToConstant: height).isActive = true
                    sb.widthAnchor.constraint(equalToConstant: height).isActive = true
                    sb.setTitleColor(.clear, for: .normal)
                    
                    sb.layer.borderColor = UIColor.lightGray.cgColor
                    sb.layer.borderWidth = 4.0
                    sb.transform = CGAffineTransform.identity.scaledBy(x: 1.2, y: 1.2)
                    self.saveGameButtonBottomConstraint.constant = kSaveGameButtonBottomConstraintConstantExisting
                    self.activityIndicatorView!.alpha = 1.0
                    
                    self.subviewHeightConstraint.constant = self.view.bounds.height * kExpandedSubviewHeightMultiplier
                    
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                }) { (_) in
                    if let ch = self.createChallenge() {
                        self.updateControls(for: .existing)
                        self.presenter?.createChallenge(challenge: ch, completion: { (challengeID) in
                            let imageData = UIImageJPEGRepresentation(self.avatarImageView!.image!, 0.3)!
                            (self.presenter?.uploadAvatar(imageData: imageData,
                                                          challengeID: challengeID,
                                                          latitude: ch.latitude,
                                                          longitude: ch.longitude,
                                                          completion: {
                                                            self.presenter?.fetchChallenge(challengeID: challengeID, completion: { (challenge) in
                                                                self.activityIndicatorView?.removeFromSuperview()
                                                                UIView.animate(withDuration: 0.25, animations: {
                                                                    self.gameState = .existing
                                                                    self.view.setNeedsLayout()
                                                                    self.view.layoutIfNeeded()
                                                                }, completion: { (_) in
                                                                    self.update(with: challenge)
                                                                })
                                                            })
                            }))!
                        })
                    }
                }
            }
        }
    }
    
    @objc func startDatePicked() {
        startTextField.text = dateFormatter.string(from: datePicker.date)
        view.endEditing(true)
        // FIXME: Use RxSwift
        saveGameButton.isEnabled = saveButtonEnabled
    }
    
    @objc func endDatePicked() {
        endTextField.text = dateFormatter.string(from: datePicker.date)
        view.endEditing(true)
        // FIXME: Use RxSwift
        saveGameButton.isEnabled = saveButtonEnabled
    }
    
    @objc func resultsDatePicked() {
        resultsTextField.text = dateFormatter.string(from: datePicker.date)
        view.endEditing(true)
        // FIXME: Use RxSwift
        saveGameButton.isEnabled = saveButtonEnabled
    }
    
    @objc func cancelDatePicker() {
        view.endEditing(true)
        // FIXME: Use RxSwift
        saveGameButton.isEnabled = saveButtonEnabled
    }
}


extension VinciChallengeGameViewController: UITextViewDelegate {
    var kPlaceholderText: String {
        return "You can describe task and rules of the game here"
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == kPlaceholderText {
            textView.text = ""
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.count == 0 {
            textView.text = kPlaceholderText
            textView.textColor = .lightGray
        }
        // FIXME: Use RxSwift
        saveGameButton.isEnabled = saveButtonEnabled
    }
}


extension VinciChallengeGameViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        if gameState == .new {
            imagePicker.dismiss(animated: true) {
                self.avatarImageView.image = image
                
                // FIXME: Use RxSwift
                self.saveGameButton.isEnabled = self.saveButtonEnabled
            }
        } else {
            imagePicker.dismiss(animated: true) {
                let acceptedClosure: (Bool, String) -> Void = {(commentsOn, description) in
                    let imageData = UIImageJPEGRepresentation(image, 0.4)!
                    
                    self.presenter?.uploadMedia(imageData: imageData,
                                                challengeID: self.challengeID!,
                                                commentsEnabled: commentsOn,
                                                description: description,
                                                completion: {
                                                    self.presenter?.fetchChallenge(challengeID: self.challengeID!,
                                                                                   completion: { (challenge) in
                                                                                    self.collectionView.reloadData()
                                                    })
                    })
                }
                // show description, title, hashtags edit view
                let mediaInfoVC = VinciChallengeMediaInfoViewController(nibName: nil, bundle: nil)
                mediaInfoVC.image = image
                mediaInfoVC.acceptedClosure = acceptedClosure
                self.present(mediaInfoVC, animated: true, completion: nil)
            }
        }
    }
}


extension VinciChallengeGameViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        // FIXME: Use RxSwift
        saveGameButton.isEnabled = saveButtonEnabled
    }
}


extension VinciChallengeGameViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first, locationLabel != nil {
            location.representation { (representation) in
                if self.gameState == .new {
                    DispatchQueue.main.async {
                        self._lat = location.coordinate.latitude
                        self._lon = location.coordinate.longitude
                        self.locationLabel.text = representation
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
}


extension VinciChallengeGameViewController: VinciChallengeGameViewProtocol {
}


extension VinciChallengeGameViewController: GameStatable {
    func initialSetup(state: GameState) {
        switch(state) {
        case .new:
            subviewHeightConstraint.constant = kCompactSubviewHeightMultiplier * view.bounds.height
            return
        case .existing:
            // block all controls
            updateControls(for: .existing)
            
            // position subviews
            let height = saveGameButton.bounds.height
            saveGameButtonLeadingConstraint.isActive = false
            saveGameButtonTrailingConstraint.isActive = false
            saveGameButtonBottomConstraint.constant = kSaveGameButtonBottomConstraintConstantExisting
            saveGameButtonHeightConstraint.isActive = false
            saveGameButton.heightAnchor.constraint(equalToConstant: height).isActive = true
            saveGameButton.widthAnchor.constraint(equalToConstant: height).isActive = true
            saveGameButton.layer.borderColor = UIColor.lightGray.cgColor
            saveGameButton.layer.borderWidth = 4.0
            saveGameButton.setTitle("", for: .normal)
            saveGameButton.setImage(UIImage(named: kPlusImage), for: .normal)
            saveGameButton.transform = CGAffineTransform.identity.scaledBy(x: 1.2, y: 1.2)
            
            subviewHeightConstraint.constant = kExpandedSubviewHeightMultiplier * view.bounds.height
            return
        }
    }
}


extension VinciChallengeGameViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = self.presenter?.challenge?.medias.count {
            return count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let presenter = self.presenter,
            let challenge = presenter.challenge,
            challenge.medias.indices.contains(indexPath.row)
            else { return VinciChallengeCollectionSmallCell() }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kCollectionCellReuseIdentifier, for: indexPath) as! VinciChallengeCollectionSmallCell
        cell.imageView.image = nil
        
        let mediaUrlString = challenge.medias[indexPath.row].url
        if let mediaUrl = URL(string: mediaUrlString) {
            cell.imageView.downloadAndSetupImage(with: mediaUrl, completion: nil)
        }
        return cell
    }
}


extension VinciChallengeGameViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = collectionView.bounds.width / 3.0 - (4.0 * 2.0)
        let height: CGFloat = width * 4.0 / 3.0
        return CGSize(width: width, height: height)
    }
}


extension VinciChallengeGameViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let cell = collectionView.cellForItem(at: indexPath) as? VinciChallengeCollectionSmallCell,
            let cellImage = cell.imageView.image,
            self.presenter?.challenge?.medias.indices.contains(indexPath.row) == true
            else { return }
        
        let attributes = collectionView.layoutAttributesForItem(at: indexPath)
        let cellFrame = attributes!.frame
        let relatedToCollectionViewFrame = cellFrame
        let relatedToMainView = collectionView.convert(relatedToCollectionViewFrame, to: collectionView.superview)
        let media = self.presenter!.challenge!.medias[indexPath.row]
        
        mediaTapped(media: media, mediaFrame: relatedToMainView, image: cellImage)
    }
}


extension VinciChallengeGameViewController: VinciChallengeMediaTappedProtocol {
    func mediaTapped(media: Media, mediaFrame: CGRect, image: UIImage?) {
        selectedImageFrame = mediaFrame
        selectedImage = image

        let destVC: VinciChallengeWatchMediaViewController = VinciChallengeWatchMediaRouter.createModule()
        destVC.presenter!.mediaID = media.id
        navigationController?.delegate = self
        navigationController?.pushViewController(destVC, animated: true)
    }
}


extension VinciChallengeGameViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationControllerOperation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if toVC is VinciChallengeWatchMediaViewController {
            let expandAnimator = ExpandAnimator()
            expandAnimator.originFrame = selectedImageFrame!
            expandAnimator.originImage = selectedImage!
            return expandAnimator
        }
        return nil
    }
}


extension VinciChallengeGameViewController: ConversationInputTextViewDelegate {
    func didPaste(_ attachment: SignalAttachment?) {
    }
    
    func inputTextViewSendMessagePressed() {
    }
}

extension VinciChallengeGameViewController: ConversationTextViewToolbarDelegate {
    func textViewDidChange(_ textView: UITextView) {
    }
}
