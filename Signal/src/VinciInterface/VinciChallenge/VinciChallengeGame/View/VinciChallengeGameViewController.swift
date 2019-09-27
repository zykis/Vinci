//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit
import CoreLocation


enum GameState {
    case new
    case saving
    case existing
}


protocol GameStatable {
    func setup(state: GameState)
}


class VinciChallengeGameViewController: VinciViewController {
    var presenter: VinciChallengeGamePresenterProtocol?
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
}


// MARK: Lifecycle
extension VinciChallengeGameViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rewardStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(VinciChallengeGameViewController.rewardPressed)))
        locationStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(VinciChallengeGameViewController.locationPressed)))
        
        startTextField.inputView = datePicker
        addInputAccessoryView(for: startTextField, with: #selector(VinciChallengeGameViewController.startDatePicked))
        endTextField.inputView = datePicker
        addInputAccessoryView(for: endTextField, with: #selector(VinciChallengeGameViewController.endDatePicked))
        resultsTextField.inputView = datePicker
        addInputAccessoryView(for: resultsTextField, with: #selector(VinciChallengeGameViewController.resultsDatePicked))
        
        locationManager.delegate = self
        imagePicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.isTranslucent = true
        
        rewardTextField.attributedPlaceholder = NSAttributedString(string: rewardTextField.placeholder!,
                                                                   attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
        titleTextField.attributedPlaceholder = NSAttributedString(string: titleTextField.placeholder!,
                                                                  attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
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
        if let sb = self.saveGameButton {
            let newBounds = CGRect(x: 0,
                                   y: 0,
                                   width: sb.bounds.height,
                                   height: sb.bounds.height)
            let ai = UIActivityIndicatorView(frame: newBounds.insetBy(dx: -4.0, dy: -4.0))
            ai.alpha = 0.0
            sb.addSubview(ai)
            
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
                sb.bounds = newBounds
                sb.setTitleColor(.clear, for: .normal)
            }) { (_) in
                ai.startAnimating()
                UIView.animate(withDuration: 0.4, animations: {
                    ai.alpha = 1.0
                })
            }
        }
        
        
    }
    
    @objc func rewardPressed() {
        
    }
    
    @objc func locationPressed() {
        
    }
    
    @objc func startDatePicked() {
        startTextField.text = dateFormatter.string(from: datePicker.date)
        view.endEditing(true)
    }
    
    @objc func endDatePicked() {
        endTextField.text = dateFormatter.string(from: datePicker.date)
        view.endEditing(true)
    }
    
    @objc func resultsDatePicked() {
        resultsTextField.text = dateFormatter.string(from: datePicker.date)
        view.endEditing(true)
    }
    
    @objc func cancelDatePicker() {
        view.endEditing(true)
    }
}


extension VinciChallengeGameViewController: UINavigationControllerDelegate {
    
}


extension VinciChallengeGameViewController: VinciChallengeGameViewProtocol {

}


extension VinciChallengeGameViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imagePicker.dismiss(animated: true) {
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            self.avatarImageView.image = image
        }
    }
}


extension VinciChallengeGameViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first, locationLabel != nil {
            location.representation { (representation) in
                DispatchQueue.main.async {
                    self.locationLabel.text = representation
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


extension VinciChallengeGameViewController: GameStatable {
    func setup(state: GameState) {
        switch(state) {
        case .new:
            return
            // setup new challenge
        case .saving:
            return
            // animate saving
        case .existing:
            return
            // load and setup existing challenge
        }
    }
}
