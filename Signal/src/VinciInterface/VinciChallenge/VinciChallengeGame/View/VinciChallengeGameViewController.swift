//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit


enum State {
    case new
    case existing
}


protocol Statable {
    func setup(state: State)
}


class VinciChallengeGameViewController: VinciViewController {
    var presenter: VinciChallengeGamePresenterProtocol?
    let imagePicker: UIImagePickerController = {
        let ip = UIImagePickerController()
        ip.sourceType = .photoLibrary
        ip.allowsEditing = true
        return ip
    }()
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var priceStackView: UIStackView!
    @IBOutlet weak var locationTextField: UITextField!
    @IBOutlet weak var locationStackView: UIStackView!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var resultsLabel: UILabel!
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


extension VinciChallengeGameViewController: Statable {
    func setup(state: State) {
        switch(state) {
        case .new:
            // setup new challenge
        case .existing:
            // load and setup existing challenge
        }
    }
}
