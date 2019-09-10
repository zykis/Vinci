//
//  VinciCodeConfirmationViewController.swift
//  VinciWelcome
//
//  Created by Ilya Klemyshev on 04/06/2019.
//  Copyright © 2019 KimCo. All rights reserved.
//

import UIKit
import PromiseKit

protocol VinciCodeConfirmationViewControllerDelegate {
    func navigateBack()
    func requestSMSCode()
    func registrationComplete()
}

class VinciCodeConfirmationViewController: VinciViewController {
    
    let accountManager = AppEnvironment.shared.accountManager
    
    var enterCodeLabel:UILabel!
    var troublesLabel = UITextView()
    
    var codeField: VinciRegTextField!
    var hiddenField: VinciRegTextField!
    
    let actionButton = UIButton()
    
    var contentTopConstraint: NSLayoutConstraint!
    var inputTopConstraint: NSLayoutConstraint!
    var inputsSpacer: NSLayoutConstraint!
    var buttonTopConstraint: NSLayoutConstraint!
    var buttonButtomConstraint: NSLayoutConstraint!
    
    var safeTopOffset: CGFloat!
    
    var contentPreserved = false
    
    var delegate:VinciCodeConfirmationViewControllerDelegate?
    
    // business
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    func createViews() {
        safeTopOffset = navigationController!.navigationBar.frame.origin.y + navigationController!.navigationBar.frame.size.height
        
        // emplace labels
        enterCodeLabel = UILabel()
        enterCodeLabel.attributedText = VinciStrings.confirmationAttributedStrings(type: .enterCode, attribute: nil)
        enterCodeLabel.numberOfLines = 2
        enterCodeLabel.sizeToFit()
        view.addSubview(enterCodeLabel)
        enterCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        contentTopConstraint = enterCodeLabel.topAnchor.constraint(lessThanOrEqualTo: view.topAnchor, constant: safeTopOffset + 8 + 80.0)
        contentTopConstraint.isActive = true
        enterCodeLabel.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: safeTopOffset + 8).isActive = true
        enterCodeLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30.0 + 16.0).isActive = true
        
        troublesLabel.backgroundColor = UIColor.clear
        troublesLabel.isEditable = false
        troublesLabel.isScrollEnabled = false
        troublesLabel.dataDetectorTypes = .link
        view.addSubview(troublesLabel)
        troublesLabel.translatesAutoresizingMaskIntoConstraints = false
        troublesLabel.topAnchor.constraint(equalTo: enterCodeLabel.topAnchor, constant: 69.0).isActive = true
        troublesLabel.leftAnchor.constraint(equalTo: enterCodeLabel.leftAnchor, constant: 2.0).isActive = true
        troublesLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        troublesLabel.heightAnchor.constraint(equalToConstant: 36).isActive = true
        troublesLabel.delegate = self
        
        troublesLabel.linkTextAttributes = [NSAttributedString.Key.foregroundColor.rawValue: UIColor.vinciBrandOrange]
        troublesLabel.attributedText = VinciStrings.confirmationAttributedStrings(type: .codeProblems, attribute: nil)
        
        codeField = VinciRegTextField(text: "", title: "confirmation code", frame: CGRect.zero)
        view.addSubview(codeField)
        codeField.translatesAutoresizingMaskIntoConstraints = false
        codeField.leftAnchor.constraint(equalTo: troublesLabel.leftAnchor).isActive = true
        codeField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16.0).isActive = true
        codeField.heightAnchor.constraint(equalToConstant: 24.0).isActive = true
        inputTopConstraint = codeField.topAnchor.constraint(lessThanOrEqualTo: troublesLabel.bottomAnchor, constant: 40.0)
        inputTopConstraint.isActive = true
        codeField.topAnchor.constraint(greaterThanOrEqualTo: troublesLabel.bottomAnchor, constant: 12.0).isActive = true
        
        codeField.textField.delegate = self
        codeField.textField.keyboardType = .numberPad
        
        hiddenField = VinciRegTextField(text: "", title: "", frame: CGRect.zero)
        view.addSubview(hiddenField)
        hiddenField.translatesAutoresizingMaskIntoConstraints = false
        hiddenField.leftAnchor.constraint(equalTo: troublesLabel.leftAnchor).isActive = true
        hiddenField.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16.0).isActive = true
        hiddenField.heightAnchor.constraint(equalToConstant: 24.0).isActive = true
        inputsSpacer = hiddenField.topAnchor.constraint(lessThanOrEqualTo: codeField.bottomAnchor, constant: 24.0)
        inputsSpacer.isActive = true
        hiddenField.topAnchor.constraint(greaterThanOrEqualTo: codeField.bottomAnchor, constant: 16.0).isActive = true
        
        //        hiddenField.textField.delegate = self
        //        hiddenField.textField.keyboardType = .phonePad
        hiddenField.isHidden = true
        
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(actionButton)
        actionButton.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        actionButton.leftAnchor.constraint(equalTo: codeField.leftAnchor, constant: 2.0).isActive = true
        actionButton.rightAnchor.constraint(equalTo: codeField.rightAnchor, constant: -2.0).isActive = true
        buttonTopConstraint = actionButton.topAnchor.constraint(greaterThanOrEqualTo: hiddenField.bottomAnchor, constant: 30.0)
        buttonTopConstraint.isActive = true
        actionButton.topAnchor.constraint(greaterThanOrEqualTo: hiddenField.bottomAnchor, constant: 16.0).isActive = true
        
        buttonButtomConstraint = actionButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        buttonButtomConstraint.isActive = false
        
        actionButton.setTitle("CONFIRM", for: .normal)
        actionButton.titleLabel!.font = VinciStrings.regularFont.withSize(12.0)
        actionButton.titleLabel!.font = actionButton.titleLabel!.font.withSize(12.0)
        actionButton.setTitleColor(UIColor.white, for: .normal)
        if #available(iOS 10.0, *) {
            actionButton.backgroundColor = UIColor.init(displayP3Red: 189/255, green: 168/255, blue: 103/255, alpha: 255/255)
        } else {
            // Fallback on earlier versions
        }
        
        actionButton.addTarget(self, action: #selector(actionButtonPressed(sender:)), for: .touchUpInside)
    }
    
    @objc func keyboardFrameChange(notification: Notification) {
        guard let info = notification.userInfo else { return }
        guard let frameInfo = info[UIKeyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = frameInfo.cgRectValue
        let keyboardTop = keyboardFrame.origin.y
        
        if ( keyboardTop != actionButton.frame.origin.y + actionButton.frame.size.height + 16 ) {
            buttonButtomConstraint.constant = -16 - keyboardFrame.height
            buttonButtomConstraint.isActive = true
            
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        shouldUseTheme = false
        createViews()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameChange), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableServerActions(enabled: true)
        updatePhoneNumberLabel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    @objc func actionButtonPressed(sender:UIButton) {
        codeField.textField.resignFirstResponder()
        hiddenField.textField.resignFirstResponder()
        
        submitVerificationCode()
    }
    
    func phoneNumberText() -> String {
        return PhoneNumber.bestEffortFormatPartialUserSpecifiedText(toLookLikeAPhoneNumber: TSAccountManager.localNumber())
    }
    
    func updatePhoneNumberLabel() {
        let phoneNumber = phoneNumberText()
        enterCodeLabel.attributedText = VinciStrings.confirmationAttributedStrings(type: .enterCode,
                                                                                   attribute: phoneNumber)
    }
    
    func submitVerificationCode() {
        let promise = accountManager.registerVinciAccount(verificationCode: validationCodeFromTextField(), pin: nil)
        promise.done({ (promise) in
            self.verificationWasCompleted()
        }).catch { (error) in
            OWSLogger.info(error.localizedDescription)
        }
    }
    
    func verificationWasCompleted() {
        delegate?.registrationComplete()
    }
    
    func presentAlertWithVerificationError(error: Error) {
        let alert = UIAlertController(title: NSLocalizedString("REGISTRATION_VERIFICATION_FAILED_TITLE",
                                                               comment: "Alert view title"),
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CommonStrings.dismissButton,
                                      style: .default,
                                      handler: { (action) in
                                        self.codeField.textField.becomeFirstResponder()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func validationCodeFromTextField() -> String {
        let text = NSString(format: "%@", codeField.textField.text ?? "")
        return text.replacingOccurrences(of: "-", with: "")
    }
    
    // MARK: ACTIONS
    func sendCodeViaSMSAction(sender: Any?){
        enableServerActions(enabled: false)
        TSAccountManager.rerequestSMS(success: {
            self.enableServerActions(enabled: true)
        }) { (error) in
            self.enableServerActions(enabled: true)
        }
    }
    
    func showRegistrationErrorMessage(registrationError: Error) {
        OWSAlerts.showAlert(title: "Error", message: registrationError.localizedDescription)
    }
    
    func enableServerActions(enabled: Bool) {
        actionButton.isEnabled = enabled
    }
}

extension VinciCodeConfirmationViewController : UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Verification codes take this form: "123-456".
        //
        // * We only want to let the user "6 decimal digits + 1 hyphen = 7".
        // * The user shouldn't have to enter the hyphen - it should be added automatically.
        // * The user should be able to copy and paste freely.
        // * Invalid input (including extraneous hyphens) should be simply ignored.
        //
        // We accomplish this by being permissive and trying to "take as much of the user
        // input as possible".
        //
        // * Always accept deletes.
        // * Ignore invalid input.
        // * Take partial input if possible.
        
        let oldText = NSString(format: "%@", textField.text ?? "")
        // Construct the new contents of the text field by:
        // 1. Determining the "left" substring: the contents of the old text _before_ the deletion range.
        //    Filtering will remove non-decimal digit characters like hyphen "-".
        let left:NSString = oldText.substring(to: range.location).digitsOnly() as NSString
        // 2. Determining the "right" substring: the contents of the old text _after_ the deletion range.
        let right = oldText.substring(from: range.location + range.length).digitsOnly()
        // 3. Determining the "center" substring: the contents of the new insertion text.
        var center:NSString = NSString(format: "%@", string).digitsOnly() as NSString
        // 3a. Trim the tail of the "center" substring to ensure that we don't end up
        //     with more than 6 decimal digits.
        while center.length > 0 && left.length + center.length + right.count > 6 {
            center = center.substring(to: center.length - 1) as NSString
        }
        // 4. Construct the "raw" new text by concatenating left, center and right.
        let rawNewText = NSString(format: "%@", left.appending(center as String).appending(right))
        // 5. Construct the "formatted" new text by inserting a hyphen if necessary.
        var formattedText = ""
        if ( rawNewText.length > 3 ) {
            formattedText = rawNewText.substring(to: 3)
            formattedText.append("-")
            formattedText.append( rawNewText.substring(from: 3))
        }
        
        let formattedNewText = rawNewText.length <= 3 ? rawNewText as String : formattedText
        textField.text = formattedNewText
        
        // Move the cursor after the newly inserted text.
        var newInsertionPoint = left.length + center.length
        if ( newInsertionPoint > 3 ) {
            // Nudge the cursor to the right to reflect the hyphen
            // if necessary.
            newInsertionPoint += 1
        }
        
        if let newPosition = textField.position(from: textField.beginningOfDocument, offset: newInsertionPoint) {
            textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
        }
        
        return false
    }
}

extension VinciCodeConfirmationViewController : UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if textView == self.troublesLabel {
            if ( URL.absoluteString == "back" ) {
                // return back
                self.delegate?.navigateBack()
            } else if URL.absoluteString == "repeatSMSCode" {
                // send code again
                self.delegate?.requestSMSCode()
            }
            
            return false
        }
        
        return true
    }
}

