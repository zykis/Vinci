//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let kMediaInfoVisibilityCellReuseIdentifier = "kMediaInfoVisibilityCellRI"
let kMediaInfoCommentsEnabledCellReuseIdentifier = "kMediaInfoCommentsEnabledCellRI"

class VinciChallengeMediaInfoViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var postMediaButton: UIButton!
    var commentsEnabled: Bool = true
    var mediaDescription: String = ""
    var acceptedClosure: ((Bool, String) -> Void)?
    weak var image: UIImage?
    
    @IBAction func backButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func postButtonPressed() {
        dismiss(animated: true) {
            self.acceptedClosure?(self.commentsEnabled, self.descriptionTextView.text)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.phase == .began {
                view.endEditing(true)
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setupInputAccessoryView() {
        let toolbar = UIToolbar(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.bounds.width,
                                              height: 44.0))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(VinciChallengeMediaInfoViewController.dismissKeyboard))
        toolbar.items = [space, doneButton]
        self.descriptionTextView.inputAccessoryView = toolbar
    }
}


extension VinciChallengeMediaInfoViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = image {
            imageView.image = image
        }
        imageView.clipsToBounds = true
        
        tableView.keyboardDismissMode = .interactive
        tableView.register(MediaInfoCommentsEnabledCell.self, forCellReuseIdentifier: kMediaInfoCommentsEnabledCellReuseIdentifier)
        tableView.register(UINib(nibName: "MediaInfoVisibilityCell", bundle: nil), forCellReuseIdentifier: kMediaInfoVisibilityCellReuseIdentifier)
        tableView.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupInputAccessoryView()
        
        imageView.layer.cornerRadius = imageView.bounds.height / 8.0
        postMediaButton.layer.cornerRadius = postMediaButton.bounds.height / 2.0
    }
}


extension VinciChallengeMediaInfoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            if let cell = tableView.dequeueReusableCell(withIdentifier: kMediaInfoVisibilityCellReuseIdentifier) {
                return cell
            }
        case 1:
            if let cell = tableView.dequeueReusableCell(withIdentifier: kMediaInfoCommentsEnabledCellReuseIdentifier) as? MediaInfoCommentsEnabledCell {
                cell.delegate = self
                return cell
            }
        default:
            return UITableViewCell()
        }
        return UITableViewCell()
    }
}


extension VinciChallengeMediaInfoViewController: MediaInfoCommentsEnabledProtocol {
    func commentsEnabledChanged(enabled: Bool) {
        self.commentsEnabled = enabled
    }
}


extension VinciChallengeMediaInfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            // present visibility view controller
        }
    }
}
