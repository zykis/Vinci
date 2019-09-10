//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc class VinciWelcomeViewController: UIViewController {
    
    var safeTopOffset:CGFloat!
    var welcomeLabel:UILabel!
    var welcomeTopConstraint:NSLayoutConstraint!
    
    var regNumberViewController:VinciRegistrationViewController!
    var codeConfirmationViewController:VinciCodeConfirmationViewController!
    var inputNicknameViewController:VinciNicknameViewController!
    
    let backButton = UIButton(type: .custom)
    var isBackDirection = true
    
    enum WelcomeControllerMode: Int {
        case registerPhoneNumber
        case confirmCode
        case inputNickname
    }
    
    var welcomeMode:WelcomeControllerMode = .registerPhoneNumber
    
    var backButtonHidden = true {
        didSet {
            if !self.backButtonHidden {
                self.backButton.frame = self.backButton.frame.offsetBy(dx: 34, dy: 0)
            }
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
                self.backButton.alpha = self.backButtonHidden ? 0.0 : 1.0
                let backButtonFrame = self.backButton.frame
                let backButtonVisibleFrame = CGRect(x: -10.0, y: backButtonFrame.origin.y, width: backButtonFrame.width, height: backButtonFrame.height)
                
                let backButtonOutOffset: CGFloat!
                if self.isBackDirection {
                    backButtonOutOffset = CGFloat(34.0)
                } else {
                    backButtonOutOffset = CGFloat(-backButtonFrame.width)
                }
                
                let newFrame = CGRect(x: backButtonOutOffset, y: backButtonFrame.origin.y, width: backButtonFrame.width, height: backButtonFrame.height)
                self.backButton.frame = self.backButtonHidden ? newFrame : backButtonVisibleFrame
                
            }) { (finished) in
                if self.backButtonHidden {
                    self.backButton.frame = self.backButton.frame.offsetBy(dx: -34, dy: 0)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        addBackButton()
        
        view.backgroundColor = Theme.backgroundColor
        safeTopOffset = navigationController!.navigationBar.frame.origin.y + navigationController!.navigationBar.frame.size.height
        
        // set VINCI title
        navigationItem.titleView = UIImageView(image: UIImage(named: "vinci"))
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        
        // welcome label
        welcomeLabel = UILabel()
        welcomeLabel.attributedText = VinciStrings.welcomeAttributedStrings(type: .welcomeVinci)
        welcomeLabel.numberOfLines = 2
        welcomeLabel.sizeToFit()
        view.addSubview(welcomeLabel)
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeTopConstraint = welcomeLabel.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: safeTopOffset + 8)
        welcomeTopConstraint.isActive = true
        welcomeLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16.0).isActive = true
        
        configureRegViewController()
    }
    
    func configureRegViewController() {
        regNumberViewController = VinciRegistrationViewController()
        regNumberViewController.delegate = self
        addChildViewController(regNumberViewController)
        view.addSubview(regNumberViewController.view)
        regNumberViewController.didMove(toParentViewController: self)
    }
    
    func configureCodeConfirmationViewController() {
        codeConfirmationViewController = VinciCodeConfirmationViewController()
        codeConfirmationViewController.delegate = self
        addChildViewController(codeConfirmationViewController)
        
        view.addSubview(codeConfirmationViewController.view)
        codeConfirmationViewController.view.frame = codeConfirmationViewController.view.frame.offsetBy(dx: codeConfirmationViewController.view.frame.width, dy: 0)
        codeConfirmationViewController.didMove(toParentViewController: self)
        
        codeConfirmationViewController.view.alpha = 1.0
    }
    
    func configureInputNicknameViewController() {
        inputNicknameViewController = VinciNicknameViewController()
        inputNicknameViewController.delegate = self
        addChildViewController(inputNicknameViewController)

        view.addSubview(inputNicknameViewController.view)
        inputNicknameViewController.view.frame = inputNicknameViewController.view.frame.offsetBy(dx: inputNicknameViewController.view.frame.width, dy: 0)
        inputNicknameViewController.didMove(toParentViewController: self)
    }
    
    func addBackButton() {
        backButton.setImage(UIImage(named: "NavBarBack")?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = UIColor.vinciBrandOrange
        backButton.addTarget(self, action: #selector(self.backAction(_:)), for: .touchUpInside)
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(UIColor.clear, for: .normal)
        backButton.setTitleColor(UIColor.clear, for: .highlighted)
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        backButton.alpha = 0.0
    }
    
    @objc func backAction(_ sender: UIButton) {
                let _ = self.navigationController?.popViewController(animated: true)
        navigateBack()
    }
    
    @objc func skipProfileNickname() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.showVinciMainInterface()
    }
}

extension VinciWelcomeViewController : VinciRegViewControllerDelegate {
    func regAccount(number: String) {
        
        configureCodeConfirmationViewController()
        backButtonHidden = false
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.regNumberViewController.view.frame = self.regNumberViewController.view.frame.offsetBy(dx: -self.regNumberViewController.view.frame.width, dy: 0)
            self.codeConfirmationViewController.view.frame = self.codeConfirmationViewController.view.frame.offsetBy(dx: -self.codeConfirmationViewController.view.frame.width, dy: 0)
            
            self.regNumberViewController.view.alpha = 0.0
            
        }) { (success) in
            if success {
                self.welcomeMode = .confirmCode
            }
            
            return
        }
    }
}

extension VinciWelcomeViewController : VinciCodeConfirmationViewControllerDelegate {
    
    func navigateBack() {
        if welcomeMode == .confirmCode {
            
            backButtonHidden = true
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.regNumberViewController.view.frame = self.regNumberViewController.view.frame.offsetBy(dx: self.regNumberViewController.view.frame.width, dy: 0)
                self.codeConfirmationViewController.view.frame = self.codeConfirmationViewController.view.frame.offsetBy(dx: self.codeConfirmationViewController.view.frame.width, dy: 0)
                
                self.regNumberViewController.view.alpha = 1.0
                self.codeConfirmationViewController.view.alpha = 0.0
                
            }) { (success) in
                if success {
                    self.welcomeMode = .registerPhoneNumber
                    self.regNumberViewController.phoneNumberField.becomeFirstResponder()
                }
                
                return
            }
        }
        
        return
    }
    
    func requestSMSCode() {
        return
    }
    
    func registrationComplete() {
        
        let skipButton = UIBarButtonItem(title: "Skip", style: .plain, target: self, action: #selector(skipProfileNickname))
        skipButton.tintColor = UIColor.vinciBrandBlue
        navigationItem.rightBarButtonItem = skipButton
        navigationItem.title = "Your Profile"
        navigationItem.titleView = nil
        
        configureInputNicknameViewController()
        isBackDirection = false
        backButtonHidden = true
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.codeConfirmationViewController.view.frame = self.codeConfirmationViewController.view.frame.offsetBy(dx: -self.codeConfirmationViewController.view.frame.width, dy: 0)
            self.inputNicknameViewController.view.frame = self.inputNicknameViewController.view.frame.offsetBy(dx: -self.inputNicknameViewController.view.frame.width, dy: 0)

            self.codeConfirmationViewController.view.alpha = 0.0

        }) { (success) in
            if success {
                self.welcomeMode = .inputNickname
            }

            return
        }
        
//        if ( self.navigationController != nil ) {
//            ProfileViewController.present(forRegistration: self.navigationController!)
//        }
    }
}

extension VinciWelcomeViewController : VinciNicknameViewControllerDelegate {
    
    func updateSkipButtonState(enabled: Bool) {
        if let skipButton = navigationItem.rightBarButtonItem {
            skipButton.isEnabled = enabled
        }
    }
}
