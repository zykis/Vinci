//
//  VinciRegViewController.swift
//  VinciWelcome
//
//  Created by Ilya Klemyshev on 04/06/2019.
//  Copyright © 2019 KimCo. All rights reserved.
//

import UIKit

@objc protocol VinciRegViewControllerDelegate {
    func regAccount(number:String)
}

@objc class VinciRegistrationViewController: VinciViewController {
    
    var inviteRegLabel = UILabel()
    var termsLabel = UITextView()
    
    var countryCode:String?
    var callingCode:String?
    
    var countryCodeField:VinciRegTextField!
    var phoneNumberField:VinciRegTextField!
    
    let actionButton = UIButton()
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
    
    var contentTopConstraint:NSLayoutConstraint!
    var inputTopConstraint:NSLayoutConstraint!
    var inputsSpacer:NSLayoutConstraint!
    var buttonTopConstraint:NSLayoutConstraint!
    var buttonButtomConstraint:NSLayoutConstraint!
    
    var safeTopOffset:CGFloat!
    
    var contentPreserved = false
    var isRegistrationInProgress = false {
        didSet {
            self.updateViewState()
        }
    }
    
    var delegate:VinciRegViewControllerDelegate?
    
    @objc func keyboardFrameChange(notification: Notification) {
        guard let info = notification.userInfo else { return }
        guard let frameInfo = info[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = frameInfo.cgRectValue
        let keyboardTop = keyboardFrame.origin.y
        
        if ( keyboardTop != actionButton.frame.origin.y + actionButton.frame.size.height + 16 ) {
            
            if ( keyboardTop < self.view.frame.origin.y + self.view.frame.height ) {
                buttonButtomConstraint.constant = -16 - keyboardFrame.height
                buttonButtomConstraint.isActive = true
            } else {
                buttonButtomConstraint.isActive = false
            }
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
            }) { (success) in
                if ( success ) {
                }
            }
        } else {
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
            }) { (success) in
                if ( success ) {
                }
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        
        shouldUseTheme = false
        createViews()
        
        populateDefaultCountryNameAndCode()
        //        assert(self.navigationController == nil)
        SignalApp.shared().signUpFlowNavigationController = self.navigationController as? OWSNavigationController
    }
    
    func createViews() {
        safeTopOffset = navigationController!.navigationBar.frame.origin.y + navigationController!.navigationBar.frame.size.height
        
        // emplace labels
        inviteRegLabel = UILabel()
        inviteRegLabel.attributedText = VinciStrings.welcomeAttributedStrings(type: .inviteReg)
        inviteRegLabel.numberOfLines = 2
        inviteRegLabel.sizeToFit()
        view.addSubview(inviteRegLabel)
        inviteRegLabel.translatesAutoresizingMaskIntoConstraints = false
        contentTopConstraint = inviteRegLabel.topAnchor.constraint(lessThanOrEqualTo: view.topAnchor, constant: safeTopOffset + 8 + 80.0)
        contentTopConstraint.isActive = true
        inviteRegLabel.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: safeTopOffset + 8).isActive = true
        inviteRegLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30.0 + 16.0).isActive = true
        
        termsLabel.backgroundColor = UIColor.clear
        termsLabel.isEditable = false
        termsLabel.isScrollEnabled = true
        termsLabel.dataDetectorTypes = .link
        termsLabel.sizeToFit()
        termsLabel.isSelectable = false
        view.addSubview(termsLabel)
        termsLabel.translatesAutoresizingMaskIntoConstraints = false
        termsLabel.topAnchor.constraint(equalTo: inviteRegLabel.topAnchor, constant: 69.0).isActive = true
        termsLabel.leftAnchor.constraint(equalTo: inviteRegLabel.leftAnchor, constant: 2.0).isActive = true
        termsLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        termsLabel.heightAnchor.constraint(equalToConstant: 36).isActive = true
        
        termsLabel.linkTextAttributes = [NSAttributedString.Key.foregroundColor.rawValue: UIColor.vinciBrandOrange]
        termsLabel.attributedText = VinciStrings.welcomeAttributedStrings(type: .vinciTerms)
        
        countryCodeField = VinciRegTextField(text: "", title: "your country code", frame: CGRect.zero)
        view.addSubview(countryCodeField)
        countryCodeField.translatesAutoresizingMaskIntoConstraints = false
        countryCodeField.leftAnchor.constraint(equalTo: termsLabel.leftAnchor).isActive = true
        countryCodeField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16.0).isActive = true
        countryCodeField.heightAnchor.constraint(equalToConstant: 24.0).isActive = true
        inputTopConstraint = countryCodeField.topAnchor.constraint(lessThanOrEqualTo: termsLabel.bottomAnchor, constant: 40.0)
        inputTopConstraint.isActive = true
        countryCodeField.topAnchor.constraint(greaterThanOrEqualTo: termsLabel.bottomAnchor, constant: 12.0).isActive = true
        countryCodeField.textField.isEnabled = false
        countryCodeField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(countryCodeFieldWasTapped(sender:))))
        
        countryCodeField.textField.delegate = self
        
        phoneNumberField = VinciRegTextField(text: "", title: "phone number", frame: CGRect.zero)
        view.addSubview(phoneNumberField)
        phoneNumberField.translatesAutoresizingMaskIntoConstraints = false
        phoneNumberField.leftAnchor.constraint(equalTo: termsLabel.leftAnchor).isActive = true
        phoneNumberField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16.0).isActive = true
        phoneNumberField.heightAnchor.constraint(equalToConstant: 24.0).isActive = true
        inputsSpacer = phoneNumberField.topAnchor.constraint(lessThanOrEqualTo: countryCodeField.bottomAnchor, constant: 24.0)
        inputsSpacer.isActive = true
        phoneNumberField.topAnchor.constraint(greaterThanOrEqualTo: countryCodeField.bottomAnchor, constant: 16.0).isActive = true
        
        phoneNumberField.textField.delegate = self
        phoneNumberField.textField.keyboardType = .phonePad
        
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionButton)
        actionButton.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        actionButton.leftAnchor.constraint(equalTo: countryCodeField.leftAnchor, constant: 2.0).isActive = true
        actionButton.rightAnchor.constraint(equalTo: countryCodeField.rightAnchor, constant: -2.0).isActive = true
        buttonTopConstraint = actionButton.topAnchor.constraint(lessThanOrEqualTo: phoneNumberField.bottomAnchor, constant: 30.0)
        buttonTopConstraint.isActive = true
        actionButton.topAnchor.constraint(greaterThanOrEqualTo: phoneNumberField.bottomAnchor, constant: 16.0).isActive = true
        
        buttonButtomConstraint = actionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        buttonButtomConstraint.isActive = false
        
        actionButton.setTitle("SEND CODE", for: .normal)
        actionButton.setTitle("", for: .highlighted)
        actionButton.titleLabel!.font = VinciStrings.regularFont.withSize(12.0)
        actionButton.titleLabel!.font = actionButton.titleLabel!.font.withSize(12.0)
        actionButton.setTitleColor(UIColor.white, for: .normal)
        if #available(iOS 10.0, *) {
            actionButton.backgroundColor = UIColor.init(displayP3Red: 189/255, green: 168/255, blue: 103/255, alpha: 255/255)
        } else {
            // Fallback on earlier versions
        }
        actionButton.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        
        // activity indicator
        activityIndicator.hidesWhenStopped = true
        actionButton.addSubview(activityIndicator)
        activityIndicator.autoCenterInSuperview()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameChange), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.stopAnimating()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        activityIndicator.stopAnimating()
    }
    
    func updateViewState() {
        if isRegistrationInProgress {
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
            actionButton.isHighlighted = true
        } else {
            activityIndicator.stopAnimating()
            actionButton.isHighlighted = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        actionButton.isEnabled = true
        phoneNumberField.becomeFirstResponder()
        
        if ( TSAccountManager.sharedInstance().isReregistering() ) {
            // If re-registering, pre-populate the country (country code, calling code, country name)
            // and phone number state.
            let phoneNumberE164:String = TSAccountManager.sharedInstance().reregisterationPhoneNumber()
            if ( tryToApplyPhoneNumberE164(phoneNumberE164: phoneNumberE164) ) {
                // Don't let user edit their phone number while re-registering.
                self.phoneNumberField.textField.isEnabled = false
            }
        }
    }
    
    func tryToApplyPhoneNumberE164(phoneNumberE164: String) -> Bool {
        
        if ( phoneNumberE164.count < 1 ) {
            // OWSFailDebug(@"Could not resume re-registration; invalid phoneNumberE164.");
            return false
        }
        guard let parsedPhoneNumber:PhoneNumber = PhoneNumber(fromE164: phoneNumberE164) else {
            // OWSFailDebug(@"Could not resume re-registration; couldn't parse phoneNumberE164.");
            return false
        }
        guard let callingCode:NSNumber = parsedPhoneNumber.getCountryCode() else {
            // OWSFailDebug(@"Could not resume re-registration; missing callingCode.");
            return false
        }
        let callingCodeText = String(format: "+%d", callingCode.intValue)
        let countryCodes:[String] = PhoneNumberUtil.sharedThreadLocal()?.countryCodes(fromCallingCode: callingCodeText) as! [String]
        if ( countryCodes.count < 1 ) {
            // OWSFailDebug(@"Could not resume re-registration; unknown countryCode.");
            return false
        }
        let countryCode = countryCodes.first
        guard let countryName:String = PhoneNumberUtil.countryName(fromCountryCode: countryCode) else {
            // OWSFailDebug(@"Could not resume re-registration; unknown countryName.");
            return false
        }
        if ( !phoneNumberE164.hasPrefix(callingCodeText) ) {
            // OWSFailDebug(@"Could not resume re-registration; non-matching calling code.");
            return false
        }
        
        let phoneNumberWithoutCallingCode = phoneNumberE164.substring(from: String.Index(encodedOffset: callingCodeText.count))
        
        updateCountry(name: countryName, callingCode: callingCodeText, countryCode: countryCode ?? "")
        self.phoneNumberField.text = phoneNumberWithoutCallingCode
        
        return true
    }
    
    // COUNTRY
    
    func populateDefaultCountryNameAndCode() {
        let countryCode = PhoneNumber.defaultCountryCode()
        
        let callingCode = PhoneNumberUtil.sharedThreadLocal()?.nbPhoneNumberUtil.getCountryCode(forRegion: countryCode)
        let countryName = PhoneNumberUtil.countryName(fromCountryCode: countryCode)!
        updateCountry(name: countryName, callingCode: String(format: "%@%@", COUNTRY_CODE_PREFIX, callingCode!), countryCode: countryCode!)
    }
    
    func updateCountry(name countryName:String, callingCode:String, countryCode:String) {
        self.countryCode = countryCode
        self.callingCode = callingCode
        
        let title = String(format: "%@ (%@)", callingCode, countryCode.localizedUppercase)
        countryCodeField.text = title
        
    }
    
    // ACTIONS
    @objc func actionButtonPressed() {
        let phoneNumberText = NSString(format: "%@", phoneNumberField.textField.text ?? "").ows_stripped()
        if ( phoneNumberText.count < 1 ) {
            OWSAlerts.showAlert(title: NSLocalizedString("REGISTRATION_VIEW_NO_PHONE_NUMBER_ALERT_TITLE",
                                                         comment: "Title of alert indicating that users needs to enter a phone number to register."),
                                message: NSLocalizedString("REGISTRATION_VIEW_NO_PHONE_NUMBER_ALERT_MESSAGE",
                                                           comment: "Message of alert indicating that users needs to enter a phone number to register."))
            return
        }
        
        let countryCode = self.countryCode
        let phoneNumber = String(format: "%@%@", callingCode!, phoneNumberText)
        let localNumber = PhoneNumber.tryParsePhoneNumber(fromUserSpecifiedText: phoneNumber)
        let parsedPhoneNumber = localNumber?.toE164()
        if ( parsedPhoneNumber != nil && parsedPhoneNumber!.count < 1 ) {
            OWSAlerts.showAlert(title: NSLocalizedString("REGISTRATION_VIEW_INVALID_PHONE_NUMBER_ALERT_TITLE",
                                                         comment: "Title of alert indicating that users needs to enter a valid phone number to register."),
                                message: NSLocalizedString("REGISTRATION_VIEW_INVALID_PHONE_NUMBER_ALERT_MESSAGE",
                                                           comment: "Message of alert indicating that users needs to enter a valid phone number to register."))
            return
        }
        
        if ( UIDevice.current.isIPad ) {
            OWSAlerts.showConfirmationAlert(title: NSLocalizedString("REGISTRATION_IPAD_CONFIRM_TITLE"
                ,comment: "alert title when registering an iPad"),
                                            message: NSLocalizedString("REGISTRATION_IPAD_CONFIRM_BODY"
                                                ,comment: "alert body when registering an iPad"),
                                            proceedTitle: NSLocalizedString("REGISTRATION_IPAD_CONFIRM_BUTTON"
                                                ,comment: "button text to proceed with registration when on an iPad")) { (action) in
                                                    self.sendCodeAction(parsedPhoneNumber: parsedPhoneNumber!,
                                                                        phoneNumberText: phoneNumberText,
                                                                        countryCode: countryCode)
            }
        } else {
            isRegistrationInProgress = true
            sendCodeAction(parsedPhoneNumber: parsedPhoneNumber!,
                           phoneNumberText: phoneNumberText,
                           countryCode: countryCode)
        }
    }
    
    func sendCodeAction(parsedPhoneNumber:String, phoneNumberText:String, countryCode:String?) {
        //        actionButton.isEnabled = false
        
        countryCodeField.textField.resignFirstResponder()
        phoneNumberField.textField.resignFirstResponder()
        
        TSAccountManager.register(withPhoneNumber: parsedPhoneNumber,
                                  success: {
                                    self.delegate?.regAccount(number: self.phoneNumberField.textField.text ?? "")
                                    self.isRegistrationInProgress = false
                                    //                                    self.actionButton.isEnabled = true
        },
                                  failure: { (error) in
                                    //                                    if ( error. == 400 ) {
                                    //                                        OWSAlerts.showAlert(title: NSLocalizedString("REGISTRATION_ERROR",
                                    //                                                                                     comment: nil),
                                    //                                                            message: NSLocalizedString("REGISTRATION_NON_VALID_NUMBER",
                                    //                                                                                       comment: nil))
                                    //                                    } else {
                                    //                                        OWSAlerts.showAlert(title: error.localizedDescription,
                                    //                                                            message: error.localizedRecoverySuggestion)
                                    //                                    }
                                    
                                    self.isRegistrationInProgress = false
                                    
                                    OWSAlerts.showAlert(title: NSLocalizedString("REGISTRATION_ERROR", comment:""),
                                                        message: error.localizedDescription)
                                    
                                    //                                    self.actionButton.isEnabled = true
                                    self.phoneNumberField.becomeFirstResponder()
        }, smsVerification: true)
    }
    
    @objc func countryCodeFieldWasTapped(sender: UIGestureRecognizer) {
        if TSAccountManager.sharedInstance().isReregistering() {
            // Don't let user edit their phone number while re-registering.
            return
        }
        
        if sender.state == .recognized {
            changeCountryCodeTapped()
        }
    }
    
    //    - (void)didTapLegalTerms:(UIButton *)sender
    //    {
    //    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kLegalTermsUrlString]];
    //    }
    
    func changeCountryCodeTapped() {
        let countryCodeController = CountryCodeViewController()
        countryCodeController.countryCodeDelegate = self
        
        let navigationController = OWSNavigationController.init(rootViewController: countryCodeController)
        present(navigationController, animated: true, completion: nil)
    }
    
    //    - (void)backgroundTapped:(UIGestureRecognizer *)sender
    //    {
    //    if (sender.state == UIGestureRecognizerStateRecognized) {
    //    [self.phoneNumberTextField becomeFirstResponder];
    //    }
    //    }
}

// MARK - CountryCodeViewController Delegate
extension VinciRegistrationViewController : CountryCodeViewControllerDelegate {
    func countryCodeViewController(_ vc: CountryCodeViewController!, didSelectCountryCode countryCode: String!, countryName: String!, callingCode: String!) {
        assert(countryCode.count > 0)
        assert(countryName.count > 0)
        assert(callingCode.count > 0)
        
        updateCountry(name: countryName, callingCode: callingCode, countryCode: countryCode)
        
        // Trigger the formatting logic with a no-op edit.
        textField(phoneNumberField.textField, shouldChangeCharactersIn: NSMakeRange(0, 0), replacementString: "")
    }
}

// MARK - UITextField Delegate
extension VinciRegistrationViewController : UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        ViewControllerUtils.phoneNumber(textField,
                                        shouldChangeCharactersIn: range,
                                        replacementString: string,
                                        countryCode: self.callingCode ?? "")
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        actionButtonPressed()
        textField.resignFirstResponder()
        return false
    }
}

