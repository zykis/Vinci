//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

protocol MediaInfoCommentsEnabledProtocol {
    func commentsEnabledChanged(enabled: Bool)
}

class MediaInfoCommentsEnabledCell: UITableViewCell {
    var delegate: MediaInfoCommentsEnabledProtocol?
    
    private var switcher: UISwitch = {
        let s = UISwitch(frame: .null)
        s.isOn = true
        return s
    }()
    
    var label: UILabel = {
        let l = UILabel(frame: .null)
        l.font = UIFont.systemFont(ofSize: 17)
        l.textColor = .black
        l.text = "Comments on"
        return l
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(switcher)
        contentView.addSubview(label)
        let cv = contentView
        switcher.translatesAutoresizingMaskIntoConstraints = false
        switcher.centerYAnchor.constraint(equalTo: cv.centerYAnchor).isActive = true
        switcher.rightAnchor.constraint(equalTo: cv.rightAnchor, constant: -8.0).isActive = true
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerYAnchor.constraint(equalTo: cv.centerYAnchor).isActive = true
        label.leftAnchor.constraint(equalTo: cv.leftAnchor, constant: 8.0).isActive = true
        
        switcher.addTarget(self, action: #selector(MediaInfoCommentsEnabledCell.switcherStateChanged(switcher:)), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    @objc func switcherStateChanged(switcher: UISwitch) {
        delegate?.commentsEnabledChanged(enabled: switcher.isOn)
    }
}
