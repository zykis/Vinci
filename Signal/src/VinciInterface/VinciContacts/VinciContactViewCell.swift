//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

@objc class VinciContactViewCell: UITableViewCell {
    
    var checker:VinciChecker!
    var cellView: ContactCellView!
    
    var checkerLeadingConstraint: NSLayoutConstraint?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
//        checker.setState(checked: selected, animated: false)
    }
    
    public func reuseIdentifier() -> String {
        return "VinciContactViewCell"
    }
    
    @objc func configure() {
        preservesSuperviewLayoutMargins = true
        contentView.preservesSuperviewLayoutMargins = true
        
        selectionStyle = .default
        backgroundColor = Theme.backgroundColor
        
        checker = VinciChecker(checked: false)
        checker.alpha = 1.0
        checker.autoSetDimensions(to: CGSize(width: 23.0, height: 23.0))
        
        contentView.addSubview(checker)
        checkerLeadingConstraint = checker.autoPinLeadingToSuperviewMargin(withInset: 0)
        checker.autoVCenterInSuperview()
        
        cellView = ContactCellView()
        contentView.addSubview(cellView)
        
        cellView.autoPinEdge(.leading, to: .trailing, of: checker, withOffset: 8.0)
        cellView.autoPinTrailing(toEdgeOf: contentView, offset: 0.0)
        cellView.autoPinTopToSuperviewMargin()
        cellView.autoPinBottomToSuperviewMargin()
        
        cellView.isUserInteractionEnabled = true
    }
    
    @objc func configure(contact:Contact) {
        OWSTableItem.configureCell(self)
        if contact.userTextPhoneNumbers.count > 0 {
            cellView.configure(withRecipientId: contact.userTextPhoneNumbers[0])
        }
        
        // Force layout, since imageView isn't being initally rendered on App Store optimized build.
        self.layoutSubviews()
    }
    
    @objc func configure(recipientId:String) {
        OWSTableItem.configureCell(self)
        cellView.configure(withRecipientId: recipientId)
        
        // Force layout, since imageView isn't being initally rendered on App Store optimized build.
        self.layoutSubviews()
    }
    
    @objc func configure(thread: TSThread) {
        OWSTableItem.configureCell(self)
        cellView.configure(with: thread)
        
        // Force layout, since imageView isn't being initally rendered on App Store optimized build.
        self.layoutSubviews()
    }
    
    func hideChecker(animated: Bool) {
        checkerLeadingConstraint?.constant = -23 - 8
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
                self.checker.alpha = 0.0
                self.layoutIfNeeded()
            }) { (finished) in
                return
            }
        } else {
            checker.alpha = 0.0
        }
    }
    
    @objc func setAccessoryMessage(_ message: String) {
        cellView.accessoryMessage = message
    }
    
    func verifiedSubtitle() -> NSAttributedString {
        return cellView.verifiedSubtitle()
    }
    
    func setAttributeSubtitle(_ subtitle: NSAttributedString) {
        cellView.setAttributedSubtitle(subtitle)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cellView.prepareForReuse()
        self.accessoryType = .none
    }
    
    func hasAccessoryText() -> Bool {
        return cellView.hasAccessoryText()
    }
    
    func ows_setAccessoryView(_ view: UIView) {
        return cellView.setAccessory(view)
    }
    
}
