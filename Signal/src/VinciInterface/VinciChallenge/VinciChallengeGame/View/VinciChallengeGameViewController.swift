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
let kSaveGameButtonBottomConstraintConstantExisting: CGFloat = 28.0
let kExpandedSubviewHeightMultiplier: CGFloat = 0.6
let kCompactSubviewHeightMultiplier: CGFloat = 0.4
let kCollectionCellReuseIdentifier = "kCollectionCellRI"


class VinciChallengeGameViewController: VinciViewController {
    var presenter: VinciChallengeGamePresenterProtocol?
    
    var gameState: GameState
    var challengeID: String?
    
    @IBOutlet weak var changePhotoButton: UIButton!
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
    
    private var activityIndicatorView: UIActivityIndicatorView?
    @IBOutlet var subviewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var saveGameButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet var saveGameButtonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var saveGameButtonTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var saveGameButtonHeightConstraint: NSLayoutConstraint!
    
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
    
    private func disableControls() {
        locationManager.stopUpdatingLocation()
        titleTextField.isEnabled = false
        rewardTextField.isEnabled = false
        changePhotoButton.isHidden = true
        startTextField.isEnabled = false
        endTextField.isEnabled = false
        resultsTextField.isEnabled = false
        descriptionTextView.isEditable = false
        saveGameButton.isEnabled = true
    }
    
    func update(with challenge: Challenge) {
        titleTextField.text = challenge.title
        rewardTextField.text = "\(challenge.reward)"
        descriptionTextView.text = challenge.description
        startTextField.text = dateFormatter.string(from: challenge.startDate)
        endTextField.text = dateFormatter.string(from: challenge.endDate!)
        resultsTextField.text = dateFormatter.string(from: challenge.expirationDate!)
        
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
        // FIXME: Use RxSwift
        saveGameButton.isEnabled = saveButtonEnabled
        saveGameButton.translatesAutoresizingMaskIntoConstraints = false
        
        rewardTextField.keyboardType = .numberPad
        
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
    
    @IBAction func saveGamePressed() {
        if gameState == .existing {
            return
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
                        self.disableControls()
                        self.presenter?.createChallenge(challenge: ch, completion: { (challengeID) in
                            let imageData = UIImageJPEGRepresentation(self.avatarImageView!.image!, 0.5)!
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


extension VinciChallengeGameViewController: UINavigationControllerDelegate {
    
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
        imagePicker.dismiss(animated: true) {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            self.avatarImageView.image = image
            
            // FIXME: Use RxSwift
            self.saveGameButton.isEnabled = self.saveButtonEnabled
        }
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
//    func fetchChallengeSuccess(challenge: Challenge) {
//        // animate loading button onto plus button
//        if gameState == .new {
//            if let ai = activityIndicatorView {
//                UIView.animate(withDuration: 2.0, animations: {
//                    self.saveGameButtonBottomConstraint.constant = kSaveGameButtonBottomConstraintConstantExisting
//                    self.subviewHeightConstraint.constant = kExpandedSubviewHeightMultiplier * self.view.bounds.height
//                    self.view.layoutIfNeeded()
//                    ai.alpha = 0.0
//                }) { (_) in
//                    ai.removeFromSuperview()
//                    self.gameState = .existing
//                    self.update(with: self.presenter!.challenge!)
//                }
//            }
//        } else {
//            // Call only after creatioin
////            self.presenter?.uploadAvatar(imageData: UIImageJPEGRepresentation(avatarImageView.image!, 1.0)!, challengeID: challengeID!)
//
//            update(with: challenge)
//            collectionView.reloadData()
//        }
//    }
}


extension VinciChallengeGameViewController: GameStatable {
    func initialSetup(state: GameState) {
        switch(state) {
        case .new:
            subviewHeightConstraint.constant = kCompactSubviewHeightMultiplier * view.bounds.height
            return
        case .existing:
            // block all controls
            disableControls()
            
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
