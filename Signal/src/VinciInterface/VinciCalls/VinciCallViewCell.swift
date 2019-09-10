//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

class VinciCallViewCell: UITableViewCell {
    
    var delChecker:VinciChecker!
    var delButton:UIButton!
    var infoButton:UIButton!
    
    var avatarView:AvatarImageView!
    var nameLabel:UILabel!
    var snippetLabel:UILabel!
    var dateTimeLabel:UILabel!
    var callTypeIcon:UIImageView!
    
    var separatorLine = UIView()
    var separatorLeftInset: NSLayoutConstraint!
    
    var call:CallViewModel?
    var overrideSnippet:NSAttributedString?
    var isBlocked:Bool = false
    
    var delCheckerLeadingOffset:NSLayoutConstraint!
    var infoButtonTrailingOffset:NSLayoutConstraint!
    
    var isCheckable:Bool = false {
        didSet {
            if ( self.isCheckable ) {
                delCheckerLeadingOffset.constant = 0
                separatorLeftInset.constant = 48.0 + 32.0 + 24.0 + 16.0
            } else {
                delCheckerLeadingOffset.constant = -23 - 16
                separatorLeftInset.constant = 48.0 + 32.0
            }
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                self.layoutIfNeeded()
                if ( self.isCheckable ) {
                    self.delButton.alpha = 1.0
                } else {
                    self.delButton.alpha = 0.0
                }
            }) { (finiched) in
                return
            }
        }
    }
    
    var viewConstraints:[NSLayoutConstraint] = []
    
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
        //        OWSAssertDebug(!self.avatarView);
        
        self.backgroundColor = Theme.backgroundColor
        
        self.delChecker = VinciChecker(checked: true)
        self.delChecker.autoSetDimensions(to: CGSize(width: 23.0, height: 23.0))
        
        delButton = UIButton(type: .custom)
        delButton.setImage(UIImage(named: "delCheckerIcon"), for: .normal)
        delButton.alpha = 0.0
        delButton.autoSetDimensions(to: CGSize(width: 23, height: 23))
        self.delButton.setContentHuggingHorizontalHigh()
        self.delButton.setCompressionResistanceHorizontalHigh()
        
        delButton.addTarget(self, action: #selector(delButtonPressed), for: .touchUpInside)
        
        self.contentView.addSubview(self.delButton)
        self.delCheckerLeadingOffset = self.delButton.autoPinLeadingToSuperviewMargin(withInset: -23 - 16)
        self.delButton.autoVCenterInSuperview()
        
        self.delButton.addTarget(self, action: #selector(delButtonPressed), for: .touchUpInside)
        
        self.avatarView = AvatarImageView()
        self.contentView.addSubview(self.avatarView)
        self.avatarView.autoSetDimensions(to: CGSize(width: CGFloat(self.avatarSize())
            , height: CGFloat(self.avatarSize())))
        self.avatarView.autoPinLeading(toTrailingEdgeOf: self.delButton, offset: 16)
        self.avatarView.autoVCenterInSuperview()
        self.avatarView.setContentHuggingHigh()
        self.avatarView.setCompressionResistanceHigh()
        // Ensure that the cell's contents never overflow the cell bounds.
        self.avatarView.autoPinEdge(toSuperviewMargin: .top, relation: .greaterThanOrEqual)
        self.avatarView.autoPinEdge(toSuperviewMargin: .bottom, relation: .greaterThanOrEqual)
        
        self.nameLabel = UILabel()
        self.nameLabel.lineBreakMode = .byTruncatingTail
        self.nameLabel.font = self.nameFont()
        self.nameLabel.setContentHuggingHorizontalLow()
        self.nameLabel.setCompressionResistanceHorizontalLow()
        
        self.dateTimeLabel = UILabel()
        self.dateTimeLabel.textColor = UIColor.init(rgbHex: 0xA2A2A2)
        self.dateTimeLabel.setContentHuggingHorizontalHigh()
        self.dateTimeLabel.setCompressionResistanceHorizontalHigh()
        
        let topRowView:UIStackView = UIStackView.init(arrangedSubviews: [
            self.nameLabel
            ])
        topRowView.axis = .horizontal
        topRowView.alignment = .lastBaseline
        topRowView.spacing = 6.0
        
        self.snippetLabel = UILabel()
        self.snippetLabel.font = self.snippetFont()
        snippetLabel.textColor = UIColor.init(rgbHex: 0xA2A2A2)
        self.snippetLabel.numberOfLines = 1
        self.snippetLabel.lineBreakMode = .byTruncatingTail
        self.snippetLabel.setContentHuggingHorizontalLow()
        self.snippetLabel.setCompressionResistanceHorizontalLow()
        
        callTypeIcon = UIImageView(image: UIImage())
//        callTypeIcon.autoSetDimensions(to: CGSize(width: 16, height: 12))
        self.callTypeIcon.setContentHuggingHorizontalHigh()
        self.callTypeIcon.setCompressionResistanceHorizontalHigh()
        
        infoButton = UIButton(type: .custom)
        infoButton.setImage(UIImage(named: "infoIcon"), for: .normal)
        infoButton.autoSetDimensions(to: CGSize(width: 23, height: 23))
        self.infoButton.setContentHuggingHorizontalHigh()
        self.infoButton.setCompressionResistanceHorizontalHigh()
        
        infoButton.addTarget(self, action: #selector(infoButtonPressed), for: .touchUpInside)
        
        let bottomRowView:UIStackView = UIStackView.init(arrangedSubviews: [
            callTypeIcon,
            self.snippetLabel
            ])
        bottomRowView.axis = .horizontal
        bottomRowView.alignment = .lastBaseline
        bottomRowView.spacing = 10.0
        
        let vStackView:UIStackView = UIStackView.init(arrangedSubviews: [
            topRowView,
            bottomRowView
            ])
        vStackView.axis = .vertical
        vStackView.alignment = .fill
        
        self.contentView.addSubview(vStackView)
        self.contentView.addSubview(dateTimeLabel)
        self.contentView.addSubview(infoButton)
        
        infoButton.autoVCenterInSuperview()
        infoButtonTrailingOffset = infoButton.autoPinTrailingToSuperviewMargin(withInset: 0)
        
        dateTimeLabel.autoVCenterInSuperview()
        dateTimeLabel.autoPinTrailing(toLeadingEdgeOf: infoButton, offset: 8)
        
        vStackView.autoPinLeading(toTrailingEdgeOf: self.avatarView, offset: CGFloat(self.avatarHSpacing()))
        vStackView.autoVCenterInSuperview()
        // Ensure that the cell's contents never overflow the cell bounds.
        vStackView.autoPinEdge(toSuperviewMargin: .top, relation: .greaterThanOrEqual)
        vStackView.autoPinEdge(toSuperviewMargin: .bottom, relation: .greaterThanOrEqual)
        vStackView.autoPinTrailing(toLeadingEdgeOf: infoButton, offset: 8)
        
        vStackView.isUserInteractionEnabled = true
        
        separatorLine.backgroundColor = UIColor.init(rgbHex: 0xEDEDED)
        addSubview(separatorLine)
        separatorLine.autoPinTrailing(toEdgeOf: self)
        separatorLine.autoSetDimension(.height, toSize: 0.5)
        separatorLine.autoPinEdge(.bottom, to: .bottom, of: self)
        
        separatorLeftInset = separatorLine.autoPinLeading(toEdgeOf: self, offset: 48.0 + 32.0)
        separatorLeftInset.isActive = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    class func cellReuseIdentifier() -> String {
        return "VinciCallViewCell"
    }
    
    func initializeLayout() {
        self.selectionStyle = .default
    }
    
    func reuseIdentifier() -> String? {
        return "VinciCallViewCell"
    }
    
    @objc func infoButtonPressed() {
        guard let call = self.call else {
            return
        }
        
        SignalApp.shared().presentCallInfo(call.callRecord)
    }
    
    @objc func delButtonPressed() {
        if let call = self.call {
            SignalApp.shared().delete(call.callRecord)
        }
    }
    
    func configure(withCall call:CallViewModel, isBlocked blocked:Bool) {
        
        self.call = call
        let thread = call.callRecord.thread
        
        // name
        self.nameLabel.font = self.nameFont()
        
        let name = contactsManager.attributedContactOrProfileName(forPhoneIdentifier: thread.contactIdentifier() ?? ""
            , primaryFont: nameFont(), secondaryFont: nameSecondaryFont())
        
        self.nameLabel.attributedText = name;
        
        // call type icon
        switch call.callRecord.callType {
        case RPRecentCallTypeIncoming, RPRecentCallTypeIncomingDeclined, RPRecentCallTypeIncomingIncomplete:
            callTypeIcon.image = UIImage(named: "callTypeIncoming")
            nameLabel.textColor = Theme.primaryColor
            snippetLabel.text = "incoming"
        case RPRecentCallTypeIncomingMissed:
            callTypeIcon.image = UIImage(named: "callTypeIncoming")
            nameLabel.textColor = UIColor.red
            snippetLabel.text = "missed"
        case RPRecentCallTypeOutgoing, RPRecentCallTypeOutgoingIncomplete, RPRecentCallTypeOutgoingMissed:
            callTypeIcon.image = UIImage(named: "callTypeOutgoing")
            nameLabel.textColor = Theme.primaryColor
            snippetLabel.text = "outgoing"
        default:
            return
        }
        
        // date time
        let callDateTime = NSDate.ows_date(withMillisecondsSince1970: call.callRecord.timestamp)
        self.dateTimeLabel.text = self.stringForDate(callDateTime)
        
        let textColor = Theme.secondaryColor
        //        if ( hasUnreadMessages && overrideSnippet == nil ) {
        //            textColor = Theme.primaryColor
        //            self.dateTimeLabel.font = self.dateTimeLabel.font.ows_mediumWeight()
        //        } else {
        self.dateTimeLabel.font = self.dateTimeFont()
        //        }
        self.dateTimeLabel.textColor = textColor
        
        // avatar
        self.avatarView.image = OWSAvatarBuilder.buildImage(thread: thread, diameter: self.avatarSize())
    }
    
//    func configure(withThread thread:ThreadViewModel, isBlocked blocked:Bool) {
//        self.configure(withThread: thread, isBlocked: blocked, overrideSnippet: nil, overrideDate: nil)
//    }
    
//    func configure(withThread thread:ThreadViewModel, isBlocked blocked:Bool, overrideSnippet:NSAttributedString?, overrideDate:NSDate?) {
//        //        OWSAssertIsOnMainThread();
//        //        OWSAssertDebug(thread);
//
//        OWSTableItem.configureCell(self)
//
//        self.thread = thread
//        self.overrideSnippet = overrideSnippet
//        self.isBlocked = blocked
//
//        NotificationCenter.default.addObserver(self
//            , selector: #selector(otherUsersProfileDidChange(notification:))
//            , name: NSNotification.Name(rawValue: kNSNotificationName_OtherUsersProfileDidChange)
//            , object: nil)
//        NotificationCenter.default.addObserver(self
//            , selector: #selector(typingIndicatorStateDidChange(notification:))
//            , name: TypingIndicatorsImpl.typingIndicatorStateDidChange
//            , object: nil)
//
//        self.updateNameLabel()
//        self.updateAvatarView()
//
//        // We update the fonts every time this cell is configured to ensure that
//        // changes to the dynamic type settings are reflected.
//        self.snippetLabel.font = self.snippetFont()
//
//        self.updatePreview()
//
//        self.dateTimeLabel.text =
//            overrideDate != nil ? self.stringForDate(overrideDate as Date?) : self.stringForDate(thread.lastMessageDate)
//
//        let textColor = Theme.secondaryColor
//        //        if ( hasUnreadMessages && overrideSnippet == nil ) {
//        //            textColor = Theme.primaryColor
//        //            self.dateTimeLabel.font = self.dateTimeLabel.font.ows_mediumWeight()
//        //        } else {
//        self.dateTimeLabel.font = self.dateTimeFont()
//        //        }
//        self.dateTimeLabel.textColor = textColor
//    }
    
    func updateAvatarView() {
//        let thread:ThreadViewModel? = self.thread
//        if ( thread == nil ) {
//            //            OWSFailDebug(@"thread should not be nil");
//            self.avatarView.image = nil
//            return
//        }
//
//        self.avatarView.image = OWSAvatarBuilder.buildImage(thread: thread!.threadRecord, diameter: self.avatarSize())
    }
    
    func attributedSnippetForThread(thread:ThreadViewModel, blocked isBlocked:Bool) -> NSAttributedString {
        //        OWSAssertDebug(thread);
        
        let hasUnreadMessages:Bool = thread.hasUnreadMessages
        let snippetText:NSMutableAttributedString = NSMutableAttributedString()
        
        if ( isBlocked ) {
            // If thread is blocked, don't show a snippet or mute status.
            snippetText.append(NSAttributedString(string: NSLocalizedString("HOME_VIEW_BLOCKED_CONVERSATION", comment: "Table cell subtitle label for a conversation the user has blocked.")
                , attributes: [
                    NSAttributedString.Key.font : self.snippetFont().ows_mediumWeight(),
                    NSAttributedString.Key.foregroundColor : Theme.primaryColor]))
        } else {
            if ( thread.isMuted ) {
                snippetText.append(NSAttributedString(string: LocalizationNotNeeded("\u{e067}  ")
                    , attributes: [
                        NSAttributedString.Key.font : UIFont.ows_elegantIconsFont(9),
                        NSAttributedString.Key.foregroundColor :
                            (hasUnreadMessages ? Theme.primaryColor : Theme.secondaryColor) ]))
            }
            
            let displayableText:String? = thread.lastMessageText
            if ( displayableText != nil ) {
                snippetText.append(NSAttributedString(string: displayableText!
                    , attributes: [
                        NSAttributedString.Key.font :
                            ( hasUnreadMessages ? self.snippetFont().ows_mediumWeight() : self.snippetFont() ),
                        NSAttributedString.Key.foregroundColor :
                            ( hasUnreadMessages ? Theme.primaryColor : Theme.secondaryColor )
                    ]))
            }
        }
        
        return snippetText
    }
    
    // MARK: Date formatting
    func stringForDate(_ date:Date?) -> String {
        if ( date == nil ) {
            //            OWSFailDebug(@"date was unexpectedly nil");
            return ""
        }
        
        return DateUtil.formatDateShort(date!)
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
        
        self.call = nil
        self.overrideSnippet = nil
        self.avatarView.image = nil
        self.infoButton = nil
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Name
    
    @objc func otherUsersProfileDidChange(notification:NSNotification) {
        //        OWSAssertIsOnMainThread();
        
        let recipientId:String = notification.userInfo![kNSNotificationKey_ProfileRecipientId] as! String
        if ( recipientId.count == 0 ) {
            return;
        }
        
        if ( !self.call!.isKind(of: CallViewModel.self) ) {
            return
        }
        
//        if ( self.call!.contactIdentifier != recipientId ) {
//            return
//        }
        
        self.updateNameLabel()
        self.updateAvatarView()
    }
    
    func updateNameLabel() {
        //        OWSAssertIsOnMainThread();
        
//        self.nameLabel.font = self.nameFont()
//        self.nameLabel.textColor = Theme.primaryColor
//
//        let thread:ThreadViewModel? = self.thread
//        if ( thread == nil ) {
//            //            OWSFailDebug(@"thread should not be nil");
//            self.nameLabel.attributedText = nil
//            return
//        }
//
//        var name:NSAttributedString
//        if ( thread!.isGroupThread ) {
//            if ( thread!.name.count == 0 ) {
//                name = NSAttributedString.init(string: MessageStrings.newGroupDefaultTitle)
//            } else {
//                name = NSAttributedString.init(string: thread!.name)
//            }
//        } else {
//            if ( self.thread!.threadRecord.isNoteToSelf() ) {
//                name = NSAttributedString.init(string: NSLocalizedString("NOTE_TO_SELF", comment: "Label for 1:1 conversation with yourself.")
//                    , attributes: [NSAttributedString.Key.font : self.nameFont()])
//            } else {
//                name = self.contactsManager.attributedContactOrProfileName(forPhoneIdentifier: thread!.contactIdentifier!
//                    , primaryFont: self.nameFont()
//                    , secondaryFont: self.nameSecondaryFont())
//            }
//        }
//
//        self.nameLabel.attributedText = name;
    }
    
    // MARK: Typing Indicators
    
    func updatePreview() {
//        if ( self.typingIndicators.typingRecipientId(forThread: self.thread!.threadRecord) != nil ) {
//            // If we hide snippetLabel, our layout will break since UIStackView will remove
//            // it from the layout.  Wrapping the preview views (the snippet label and the
//            // typing indicator) in a UIStackView proved non-trivial since we're using
//            // UIStackViewAlignmentLastBaseline.  Therefore we hide the _contents_ of the
//            // snippet label using an empty string.
//            self.snippetLabel.text = " "
//        } else {
//            if ( self.overrideSnippet != nil ) {
//                self.snippetLabel.attributedText = self.overrideSnippet
//            } else {
//                self.snippetLabel.attributedText = self.attributedSnippetForThread(thread: self.thread!
//                    , blocked: self.isBlocked)
//            }
//        }
    }
    
    @objc func typingIndicatorStateDidChange(notification:NSNotification) {
        //        OWSAssertIsOnMainThread();
        //        OWSAssertDebug(self.thread);
        
//        guard let objString = notification.object as? String else {
//            return
//        }
//
//        if ( notification.object != nil && objString != self.thread!.threadRecord.uniqueId ) {
//            return
//        }
        
        self.updatePreview()
    }
}
