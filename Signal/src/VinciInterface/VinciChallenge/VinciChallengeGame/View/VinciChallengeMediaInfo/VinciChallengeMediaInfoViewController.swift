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
    
    @IBAction func postButtonPressed() {
        print("post media")
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
            if let cell = tableView.dequeueReusableCell(withIdentifier: kMediaInfoCommentsEnabledCellReuseIdentifier) {
                return cell
            }
        }
        return UITableViewCell()
    }
}
