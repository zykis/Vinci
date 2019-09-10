//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

class VinciArchivedTableViewCell: UITableViewCell {
    
    var checker:VinciChecker!
    
    var nameLabel:UILabel!
    var snippetLabel:UILabel!
    var dateTimeLabel:UILabel!
    var messageStatusView:UIImageView!
    var typingIndicatorView:TypingIndicatorView!
    
    var separatorLine = UIView()
    var separatorLeftInset: NSLayoutConstraint!
    
    var unreadBadge:UIView!
    var unreadLabel:UILabel!
    
    var thread:ThreadViewModel?
    var overrideSnippet:NSAttributedString?
    var isBlocked:Bool = false
    
    var viewConstraints:[NSLayoutConstraint] = []
    let archAvatar = UIImageView(image: UIImage(named: "archiveRowAvatar"))

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK - Dependencies
    
    var contactsManager:OWSContactsManager {
        get {
            //            OWSAssertDebug(Environment.shared.contactsManager);
            return Environment.shared.contactsManager
        }
    }
    
    var typingIndicators:TypingIndicators {
        get {
            return SSKEnvironment.shared.typingIndicators
        }
    }
    
    var tsAccountManager:TSAccountManager {
        get {
            //            OWSAssertDebug(SSKEnvironment.shared.tsAccountManager);
            return SSKEnvironment.shared.tsAccountManager
        }
    }
    
    // MARK -
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        
        for subview:UIView in self.contentView.subviews {
            subview.removeFromSuperview()
        }
        
        //        cell.contentView.backgroundColor = Theme.middleGrayColor
        
        let titleLabel:UILabel = UILabel()
        //        label.text = NSLocalizedString("CHATS_VIEW_ARCHIVED_CONVERSATIONS", comment: "Label for 'archived conversations' button.")
        titleLabel.text = "Archived chats"
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.ows_dynamicTypeBody
        titleLabel.textColor = Theme.primaryColor
        
        let recipLabel = UILabel()
        recipLabel.text = "recipients"
        recipLabel.textAlignment = .left
        recipLabel.font = UIFont.ows_dynamicTypeBody
        recipLabel.textColor = Theme.secondaryColor
        
        let vStackView = UIStackView()
        vStackView.axis = .vertical
        vStackView.alignment = .leading
        vStackView.spacing = 2
        
        vStackView.addArrangedSubview(titleLabel)
        vStackView.addArrangedSubview(recipLabel)
        
        let stackView:UIStackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.spacing = 12
        // If alignment isn't set, UIStackView uses the height of
        // disclosureImageView, even if label has a higher desired height.
        stackView.alignment = .center
        stackView.addArrangedSubview(archAvatar)
        stackView.addArrangedSubview(vStackView)
        self.contentView.addSubview(stackView)
        // Constrain to cell margins.
        stackView.autoPinEdge(toSuperviewEdge: .leading, withInset: 15.0)
        stackView.autoPinEdge(toSuperviewEdge: .trailing, withInset: -15.0)
        stackView.autoPinEdge(toSuperviewEdge: .top, withInset: 8.0)
        stackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 8.0)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    class func cellReuseIdentifier() -> String {
        return "VinciArchivedViewCell"
    }
    
    func initializeLayout() {
        self.selectionStyle = .default
    }
    
    func reuseIdentifier() -> String? {
        return "VinciArchivedViewCell"
    }
    
    // MARK: Constraints
    func unreadFont() -> UIFont {
        return UIFont.ows_dynamicTypeCaption1.ows_mediumWeight()
    }
    
    func dateTimeFont() -> UIFont {
        return UIFont.ows_dynamicTypeCaption1
    }
    
    func snippetFont() -> UIFont {
        return UIFont.ows_dynamicTypeSubheadline
    }
    
    func nameFont() -> UIFont {
        return UIFont.ows_dynamicTypeBody.ows_mediumWeight()
    }
    
    // Used for profile names.
    func nameSecondaryFont() -> UIFont {
        return UIFont.ows_dynamicTypeBody.ows_italic()
    }
    
    func avatarSize() -> UInt {
        return kStandardAvatarSize
    }
    
    func avatarHSpacing() -> UInt {
        return 12
    }
    
    // MARK: Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        
        NSLayoutConstraint.deactivate(self.viewConstraints)
        self.viewConstraints.removeAll()
        
        self.thread = nil
        self.overrideSnippet = nil
        
        NotificationCenter.default.removeObserver(self)
    }
}
