//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

class VinciChatViewCell: UITableViewCell {
    
    var checker:VinciChecker!
    
    var avatarView:AvatarImageView!
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
    
    var checkerLeadingOffset:NSLayoutConstraint!
    
    var isCheckable:Bool = false {
        didSet {
            if ( self.isCheckable ) {
                checkerLeadingOffset.constant = 0
                separatorLeftInset.constant = 48.0 + 32.0 + 24.0 + 16.0
            } else {
                checkerLeadingOffset.constant = -23 - 16
                separatorLeftInset.constant = 48.0 + 32.0
            }
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                self.layoutIfNeeded()
                if ( self.isCheckable ) {
                    self.checker.alpha = 1.0
                } else {
                    self.checker.alpha = 0.0
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
    
    public func setCheckerAsDelete() {
        self.checker.setChecker(delImage: true)
    }
    
    func commonInit() {
        //        OWSAssertDebug(!self.avatarView);
        
        self.backgroundColor = Theme.backgroundColor
        
        self.checker = VinciChecker(checked: false)
        self.checker.autoSetDimensions(to: CGSize(width: 23.0, height: 23.0))
        
        self.contentView.addSubview(self.checker)
        self.checkerLeadingOffset = self.checker.autoPinLeadingToSuperviewMargin(withInset: -23 - 16)
        self.checker.autoVCenterInSuperview()
        
        self.avatarView = AvatarImageView()
        self.contentView.addSubview(self.avatarView)
        self.avatarView.autoSetDimensions(to: CGSize(width: CGFloat(self.avatarSize())
            , height: CGFloat(self.avatarSize())))
        self.avatarView.autoPinLeading(toTrailingEdgeOf: self.checker, offset: 16)
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
        self.dateTimeLabel.setContentHuggingHorizontalHigh()
        self.dateTimeLabel.setCompressionResistanceHorizontalHigh()
        
        contentView.addSubview(dateTimeLabel)
        dateTimeLabel.autoPinEdge(.trailing, to: .trailing, of: self.contentView, withOffset: -16.0)
        dateTimeLabel.autoPinTopToSuperviewMargin(withInset: 8.0)
        
        self.messageStatusView = UIImageView()
        self.messageStatusView.setContentHuggingHorizontalHigh()
        self.messageStatusView.setCompressionResistanceHorizontalHigh()
        
        contentView.addSubview(messageStatusView)
        messageStatusView.autoPinEdge(.trailing, to: .leading, of: dateTimeLabel, withOffset: -2.0)
        messageStatusView.autoPinTopToSuperviewMargin(withInset: 8.0)
        
        let topRowView:UIStackView = UIStackView.init(arrangedSubviews: [
            self.nameLabel
            ])
        topRowView.axis = .horizontal
        topRowView.alignment = .lastBaseline
        topRowView.spacing = 4.0
        
        self.snippetLabel = UILabel()
        self.snippetLabel.font = self.snippetFont()
        self.snippetLabel.numberOfLines = 1
        self.snippetLabel.lineBreakMode = .byTruncatingTail
        self.snippetLabel.setContentHuggingHorizontalLow()
        self.snippetLabel.setCompressionResistanceHorizontalLow()
        
        self.typingIndicatorView = TypingIndicatorView()
        self.contentView.addSubview(self.typingIndicatorView)
        
        let bottomRowView:UIStackView = UIStackView.init(arrangedSubviews: [
            self.snippetLabel
            ])
        bottomRowView.axis = .horizontal
        bottomRowView.alignment = .lastBaseline
        bottomRowView.spacing = 6.0
        
        let vStackView:UIStackView = UIStackView.init(arrangedSubviews: [
            topRowView,
            bottomRowView
            ])
        vStackView.axis = .vertical
        vStackView.alignment = .fill
        
        self.contentView.addSubview(vStackView)
        vStackView.autoPinLeading(toTrailingEdgeOf: self.avatarView, offset: CGFloat(self.avatarHSpacing()))
        vStackView.autoVCenterInSuperview()
        // Ensure that the cell's contents never overflow the cell bounds.
        vStackView.autoPinEdge(toSuperviewMargin: .top, relation: .greaterThanOrEqual)
        vStackView.autoPinEdge(toSuperviewMargin: .bottom, relation: .greaterThanOrEqual)
        vStackView.autoPinTrailing(toLeadingEdgeOf: dateTimeLabel, offset: messageStatusView.width() + 8.0)
        
        vStackView.isUserInteractionEnabled = true
        
        self.unreadLabel = UILabel()
        self.unreadLabel.textColor = UIColor.ows_black
        self.unreadLabel.lineBreakMode = .byTruncatingTail
        self.unreadLabel.textAlignment = .center
        self.unreadLabel.setContentHuggingHigh()
        self.unreadLabel.setCompressionResistanceHigh()
        
        self.unreadBadge = NeverClearView()
        self.unreadBadge.backgroundColor = UIColor.vinciBrandBlue
        unreadBadge.layer.backgroundColor = UIColor.vinciBrandBlue.cgColor
        self.unreadBadge.addSubview(self.unreadLabel)
        self.unreadLabel.autoCenterInSuperview()
        self.unreadBadge.setContentHuggingHigh()
        self.unreadBadge.setCompressionResistanceHigh()
        
        self.contentView.addSubview(self.unreadBadge)
        self.unreadBadge.autoAlignAxis(.horizontal, toSameAxisOf: self.snippetLabel)
        
        typingIndicatorView.autoPinEdge(.leading, to: .leading, of: self.snippetLabel)
        typingIndicatorView.autoAlignAxis(.horizontal, toSameAxisOf: self.snippetLabel)
        
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
        return "VinciChatsViewCell"
    }
    
    func initializeLayout() {
        self.selectionStyle = .default
    }
    
    func reuseIdentifier() -> String? {
        return "VinciChatsViewCell"
    }
    
    func configure(withThread thread:ThreadViewModel, isBlocked blocked:Bool) {
        self.configure(withThread: thread, isBlocked: blocked, overrideSnippet: nil, overrideDate: nil)
    }
    
    func configure(withThread thread:ThreadViewModel, isBlocked blocked:Bool, overrideSnippet:NSAttributedString?, overrideDate:NSDate?) {
        //        OWSAssertIsOnMainThread();
        //        OWSAssertDebug(thread);
        
        //        OWSTableItem.configureCell(self)
        
        self.thread = thread
        self.overrideSnippet = overrideSnippet
        self.isBlocked = blocked
        
        let hasUnreadMessages:Bool = thread.hasUnreadMessages
        
        NotificationCenter.default.addObserver(self
            , selector: #selector(otherUsersProfileDidChange(notification:))
            , name: NSNotification.Name(rawValue: kNSNotificationName_OtherUsersProfileDidChange)
            , object: nil)
        NotificationCenter.default.addObserver(self
            , selector: #selector(typingIndicatorStateDidChange(notification:))
            , name: TypingIndicatorsImpl.typingIndicatorStateDidChange
            , object: nil)
        
        self.updateNameLabel()
        self.updateAvatarView()
        
        // We update the fonts every time this cell is configured to ensure that
        // changes to the dynamic type settings are reflected.
        self.snippetLabel.font = self.snippetFont()
        
        self.updatePreview()
        
        self.dateTimeLabel.text =
            overrideDate != nil ? self.stringForDate(overrideDate as Date?) : self.stringForDate(thread.lastMessageDate)
        
        let textColor = Theme.secondaryColor
        //        if ( hasUnreadMessages && overrideSnippet == nil ) {
        //            textColor = Theme.primaryColor
        //            self.dateTimeLabel.font = self.dateTimeLabel.font.ows_mediumWeight()
        //        } else {
        self.dateTimeLabel.font = self.dateTimeFont()
        //        }
        self.dateTimeLabel.textColor = textColor
        
        let unreadCount = thread.unreadCount
        if ( overrideSnippet != nil ) {
            // If we're using the home view cell to render search results,
            // don't show "unread badge" or "message status" indicator.
            self.unreadBadge.isHidden = true
            self.messageStatusView.isHidden = true
            
        } else if ( unreadCount > 0 ) {
            // If there are unread messages, show the "unread badge."
            // The "message status" indicators is redundant.
            self.unreadBadge.isHidden = false
            self.messageStatusView.isHidden = true
            
            self.unreadLabel.text = OWSFormat.formatInt(Int32(unreadCount))
            self.unreadLabel.font = self.unreadFont()
            let unreadBadgeHeight:Int = Int(ceil(self.unreadLabel.font.lineHeight * 1.5))
            self.unreadBadge.layer.cornerRadius = CGFloat(unreadBadgeHeight / 2)
            self.unreadBadge.layer.borderColor = Theme.backgroundColor.cgColor
            self.unreadBadge.layer.borderWidth = 1.0
            
            NSLayoutConstraint.autoSetPriority(.defaultHigh) {
                // This is a bit arbitrary, but it should scale with the size of dynamic text
                let minMargin:CGFloat = CeilEven( CGFloat(unreadBadgeHeight) * 0.5 )
                
                // Spec check. Should be 12pts (6pt on each side) when using default font size.
                // OWSAssertDebug(UIFont.ows_dynamicTypeBodyFont.pointSize != 17 || minMargin == 12);
                
                // badge sizing
                self.viewConstraints.append(self.unreadBadge.autoMatch(.width
                    , to: .width
                    , of: self.unreadLabel
                    , withOffset: minMargin
                    , relation: .greaterThanOrEqual))
                
                self.viewConstraints.append(self.unreadBadge.autoSetDimension(.width
                    , toSize: CGFloat(24)
                    , relation: .greaterThanOrEqual))
                
                self.viewConstraints.append(self.unreadLabel.autoSetDimension(.height
                    , toSize: CGFloat(24)))
                
                self.viewConstraints.append(self.unreadBadge.autoPinEdge(.trailing
                    , to: .trailing
                    , of: self.contentView
                    , withOffset: -26.0))
            }
            
        } else {
            
            var statusIndicatorImage:UIImage? = nil
            // TODO: Theme, Review with design.
            var messageStatusViewTintColor = Theme.isDarkThemeEnabled ? UIColor.ows_gray25 : UIColor.ows_gray45
            var shouldAnimateStatusIcon:Bool = false
            
            // here '?? false' because it's possible to have thread with no messages if had only calls before and remove them from call controller
            if ( (self.thread?.lastMessageForInbox?.isKind(of: TSOutgoingMessage.self)) ?? false ) {
                let outgoingMessage:TSOutgoingMessage = self.thread?.lastMessageForInbox as! TSOutgoingMessage
                let messageStatus:MessageReceiptStatus = MessageRecipientStatusUtils.recipientStatus(outgoingMessage: outgoingMessage)
                
                switch messageStatus {
                case .uploading, .sending:
                    statusIndicatorImage = UIImage.init(named: "message_status_sending")
                    shouldAnimateStatusIcon = true
                    break
                case .sent, .skipped:
                    statusIndicatorImage = UIImage.init(named: "message_status_sent")
                    break
                case .delivered:
                    statusIndicatorImage = UIImage.init(named: "message_status_delivered")
                    break
                case .read:
                    statusIndicatorImage = UIImage.init(named: "message_status_read")
                    break
                case .failed:
                    statusIndicatorImage = UIImage.init(named: "message_status_failed")
                    messageStatusViewTintColor = UIColor.ows_destructiveRed
                    break
                }
            }
            
            self.messageStatusView.image = statusIndicatorImage?.withRenderingMode(.alwaysTemplate)
            self.messageStatusView.tintColor = messageStatusViewTintColor
            self.messageStatusView.isHidden = statusIndicatorImage == nil
            self.unreadBadge.isHidden = true
            
            if ( shouldAnimateStatusIcon ) {
                let animation:CABasicAnimation = CABasicAnimation.init(keyPath: "transform.rotation.z")
                animation.toValue = Double.pi * 2.0
                let kPeriodSeconds:CGFloat = 1.0
                animation.duration = CFTimeInterval(kPeriodSeconds)
                animation.isCumulative = true
                animation.repeatCount = Float.infinity
                self.messageStatusView.layer.add(animation, forKey: "animation")
            } else {
                self.messageStatusView.layer.removeAllAnimations()
            }
        }
    }
    
    func updateAvatarView() {
        let thread:ThreadViewModel? = self.thread
        if ( thread == nil ) {
            // OWSFailDebug(@"thread should not be nil");
            self.avatarView.image = nil
            return
        }
        
        self.avatarView.image = OWSAvatarBuilder.buildImage(thread: thread!.threadRecord, diameter: self.avatarSize())
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
//        return kStandardAvatarSize
        return 62
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
        self.avatarView.image = nil
        self.nameLabel.attributedText = nil
        self.nameLabel.text = ""
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Name
    
    @objc func otherUsersProfileDidChange(notification:NSNotification) {
        //        OWSAssertIsOnMainThread();
        
        let recipientId:String = notification.userInfo![kNSNotificationKey_ProfileRecipientId] as! String
        if ( recipientId.count == 0 ) {
            return;
        }
        
        if ( !self.thread!.isKind(of: TSContactThread.self) ) {
            return
        }
        
        if ( self.thread!.contactIdentifier != recipientId ) {
            return
        }
        
        self.updateNameLabel()
        self.updateAvatarView()
    }
    
    func updateNameLabel() {
        //        OWSAssertIsOnMainThread();
        
        self.nameLabel.font = self.nameFont()
        self.nameLabel.textColor = Theme.primaryColor
        
        let thread:ThreadViewModel? = self.thread
        if ( thread == nil ) {
            //            OWSFailDebug(@"thread should not be nil");
            self.nameLabel.attributedText = nil
            return
        }
        
        var name:NSAttributedString
        if ( thread!.isGroupThread ) {
            if ( thread!.name.count == 0 ) {
                name = NSAttributedString.init(string: MessageStrings.newGroupDefaultTitle)
            } else {
                let nameStr = thread!.name
                name = NSAttributedString.init(string: nameStr)
            }
        } else {
            if ( self.thread!.threadRecord.isNoteToSelf() ) {
                name = NSAttributedString.init(string: NSLocalizedString("Note to self", comment: "Label for 1:1 conversation with yourself.")
                    , attributes: [NSAttributedString.Key.font : self.nameFont()])
            } else {
                name = self.contactsManager.attributedContactOrProfileName(forPhoneIdentifier: thread!.contactIdentifier!
                    , primaryFont: self.nameFont()
                    , secondaryFont: self.nameSecondaryFont())
            }
        }
        
        self.nameLabel.attributedText = name;
    }
    
    // MARK: Typing Indicators
    
    func updatePreview() {
        if ( self.typingIndicators.typingRecipientId(forThread: self.thread!.threadRecord) != nil ) {
            // If we hide snippetLabel, our layout will break since UIStackView will remove
            // it from the layout.  Wrapping the preview views (the snippet label and the
            // typing indicator) in a UIStackView proved non-trivial since we're using
            // UIStackViewAlignmentLastBaseline.  Therefore we hide the _contents_ of the
            // snippet label using an empty string.
            self.snippetLabel.text = " "
            self.typingIndicatorView.isHidden = false
            self.typingIndicatorView.startAnimation()
        } else {
            if ( self.overrideSnippet != nil ) {
                self.snippetLabel.attributedText = self.overrideSnippet
            } else {
                self.snippetLabel.attributedText = self.attributedSnippetForThread(thread: self.thread!
                    , blocked: self.isBlocked)
            }
            self.typingIndicatorView.isHidden = true
            self.typingIndicatorView.stopAnimation()
        }
    }
    
    @objc func typingIndicatorStateDidChange(notification:NSNotification) {
        //        OWSAssertIsOnMainThread();
        //        OWSAssertDebug(self.thread);
        
        guard let objString = notification.object as? String else {
            return
        }
        
        if ( notification.object != nil && objString != self.thread!.threadRecord.uniqueId ) {
            return
        }
        
        self.updatePreview()
    }
}
