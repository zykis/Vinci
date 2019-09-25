//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let kCloseButtonImage = "icon_close_black_40.png"
let kCornerRadius: CGFloat = 16.0

protocol VinciChallengeCommentsViewProtocol {
    func closeButtonTapped()
}

class VinciChallengeCommentsView: UIView {
    weak var viewController: VinciChallengeWatchMediaViewController?
    var delegate: VinciChallengeCommentsViewProtocol?
    
    private var tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.estimatedRowHeight = 84.0
        tv.rowHeight = UITableViewAutomaticDimension
        return tv
    }()
    
    private var closeButton: UIButton = {
        let cb = UIButton()
        cb.imageView?.contentMode = .scaleAspectFill
        cb.setImage(UIImage(named: kCloseButtonImage), for: .normal)
        cb.adjustsImageWhenHighlighted = false
        return cb
    }()
    
    private var totalCommentsLabel: UILabel = {
        let cl = UILabel()
        cl.font = UIFont.systemFont(ofSize: 17.0)
        cl.textColor = .black
        return cl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        layer.cornerRadius = kCornerRadius
        
        addSubview(closeButton)
        addSubview(totalCommentsLabel)
        addSubview(tableView)
        
        closeButton.anchor(top: topAnchor, left: nil, bottom: nil, right: rightAnchor, paddingTop: 20.0, paddingLeft: 0, paddingBottom: 0, paddingRight: 20.0, width: 16, height: 16, enableInsets: false)
        totalCommentsLabel.translatesAutoresizingMaskIntoConstraints = false
        totalCommentsLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        totalCommentsLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor).isActive = true
        tableView.anchor(top: closeButton.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 8.0, paddingLeft: 0, paddingBottom: kCornerRadius, paddingRight: 0, width: 0, height: 0, enableInsets: false)
        
        tableView.register(VinciChallengeCommentCell.self, forCellReuseIdentifier: kVinciChallengeCommentCellReuseIdentifier)
        tableView.dataSource = self
        
        closeButton.addTarget(self, action: #selector(VinciChallengeCommentsView.closeButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    @objc func closeButtonTapped() {
        delegate?.closeButtonTapped()
    }
    
    func reloadData() {
        self.totalCommentsLabel.text = "\(viewController?.presenter?.totalCommentsCount() ?? 0) comments"
        self.tableView.reloadData()
    }
}


extension VinciChallengeCommentsView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewController?.presenter?.commentsCount() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kVinciChallengeCommentCellReuseIdentifier, for: indexPath) as! VinciChallengeCommentCell
        if let comment = self.viewController?.presenter?.comment(at: indexPath.row) {
            cell.commentID = comment.id
            cell.setup(comment: comment.presenter())
        }
        return cell
    }
}
