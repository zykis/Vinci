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
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var rewardTextField: UITextField!
    @IBOutlet weak var rewardStackView: UIStackView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationStackView: UIStackView!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var startStackView: UIStackView!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var endStackView: UIStackView!
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var resultsStackView: UIStackView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}


// MARK: Lifecycle
extension VinciChallengeGameViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rewardStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(VinciChallengeGameViewController.rewardPressed)))
        locationStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(VinciChallengeGameViewController.locationPressed)))
        startStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(VinciChallengeGameViewController.startDatePressed)))
        endStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(VinciChallengeGameViewController.endDatePressed)))
        resultsStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(VinciChallengeGameViewController.resultsDatePressed)))
        
        locationManager.delegate = self
        imagePicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationBar.isTranslucent = true
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
    
    @objc func rewardPressed() {
        
    }
    
    @objc func locationPressed() {
        
    }
    
    @objc func startDatePressed() {
        
    }
    
    @objc func endDatePressed() {
        
    }
    
    @objc func resultsDatePressed() {
        
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
