//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let kEndpointGetMediaComments = kHost + "getMediaComments"


class VinciChallengeCommentsViewController: VinciViewController {
    var mediaID: String?
    var comments: [Comment] = []
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var totalCommentsLabel: UILabel!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    @IBAction func closePressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setupTableView() {
        self.tableView.register(VinciChallengeCommentCell.self, forCellReuseIdentifier: kVinciChallengeCommentCellReuseIdentifier)
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 84.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTableView()
        self.getComments(for: self.mediaID) {
            self.tableView.reloadData()
        }
    }
}


extension VinciChallengeCommentsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: kVinciChallengeCommentCellReuseIdentifier) as? VinciChallengeCommentCell {
            if self.comments.indices.contains(indexPath.row) {
                let c = self.comments[indexPath.row]
                cell.comment = c
                cell.setup(comment: c.presenter())
            }
            return cell
        }
        return UITableViewCell()
    }
}


extension VinciChallengeCommentsViewController {
    func getComments(for mediaID: String?, completion: (() -> Void)?) {
        let signalID = TSAccountManager.sharedInstance().getOrGenerateRegistrationId()
        let urlString = kEndpointGetMediaComments + "?SIGNALID=\(signalID)&MEDIAMETAID=\(mediaID!)&LIMIT=20&OFFSET=0"
        if let url = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                guard let data = data
                    else { return }
                let decoder = JSONDecoder()
                do {
                    let comments: [Comment] = try decoder.decode([Comment].self, from: data)
                    self.comments = comments
                    DispatchQueue.main.async {
                        completion?()
                    }
                }
                catch {
                    print(error)
                }
            }
            task.resume()
        }
    }
}
