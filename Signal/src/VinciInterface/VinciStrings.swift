
import UIKit

@objc enum welcomeStringsType:Int {
    case welcomeVinci
    case inviteReg
    case vinciTerms
}

@objc enum confirmationStringsType:Int {
    case enterCode
    case codeProblems
}

@objc enum newProfileStringsType:Int {
    case enterNickname
    case profileNote
}

@objc enum emptySearchStringsType:Int {
    case emptyLookingForSmth
    case emptyStartSearching
}

@objc enum emptyChatsStringsType:Int {
    case startConversation
    case toBegin
}

@objc enum emptyCallsStringsType:Int {
    case startCalls
    case toBegin
}

@objc class VinciStrings : NSObject {
    
    @objc
    static public let regularFont = UIFont(name: "SFProText-Regular", size: 24.0) ?? UIFont.ows_fontAwesomeFont(24.0)
    
    @objc
    static public let navigationTitleFont = UIFont(name: "SFProText-Semibold", size: 17.0) ?? UIFont.ows_fontAwesomeFont(17.0)
    
    @objc
    static public let largeTitleFont = UIFont(name: "SFProDisplay-Bold", size: 34.0) ?? UIFont.ows_fontAwesomeFont(34.0)
    
    @objc
    static public let tinyFont = UIFont(name: "SFProText-Regular", size: 11.0) ?? UIFont.ows_fontAwesomeFont(11.0)
    
    @objc
    static public let sectionTitleFont = UIFont(name: "SFProDisplay-Bold", size: 22.0) ?? UIFont.ows_fontAwesomeFont(22.0)
    
    @objc
    static public var welcomeVinciString: NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "Welcome\nto Vinci")
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0.0
        paragraphStyle.lineHeightMultiple = 0.87
        
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
        attributedString.addAttribute(NSAttributedString.Key.font, value:UIFont(name: "SFProDisplay-Black", size: 60.0) ?? UIFont.ows_fontAwesomeFont(60.0),
                                      range:NSRange(location: 0, length: attributedString.length))
        
        if #available(iOS 10.0, *) {
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.init(rgbHex: 0xF3F3F3), range:NSRange(location: 0, length: attributedString.length))
        } else {
            // Fallback on earlier versions
        }
        
        return attributedString
    }
    
    class func emptyAttributedStrings(type:emptySearchStringsType) -> NSAttributedString {
        
        let attributedString:NSMutableAttributedString
        
        switch type {
        case .emptyLookingForSmth:
            attributedString = NSMutableAttributedString(string: "Looking\nfor smth?")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 0.0
            paragraphStyle.lineHeightMultiple = 0.87
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:UIFont(name: "SFProDisplay-Black", size: 60.0) ?? UIFont.ows_fontAwesomeFont(60.0),
                                          range:NSRange(location: 0, length: attributedString.length))
            if #available(iOS 10.0, *) {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.init(rgbHex: 0xF3F3F3),
                                              range:NSRange(location: 0, length: attributedString.length))
            } else {
                // Fallback on earlier versions
            }
            
            break
        case .emptyStartSearching:
            attributedString = NSMutableAttributedString(string: "Start searching\n&you'll find the answer")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 7
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:regularFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.black, range:NSRange(location: 0, length: attributedString.length))
            break
        }
        
        return attributedString
    }
    
    class func welcomeAttributedStrings(type:welcomeStringsType) -> NSAttributedString {
        
        let attributedString:NSMutableAttributedString
        
        switch type {
        case .welcomeVinci:
            attributedString = NSMutableAttributedString(string: "Welcome\nto Vinci")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 0.0
            paragraphStyle.lineHeightMultiple = 0.87
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:UIFont(name: "SFProDisplay-Black", size: 60.0) ?? UIFont.ows_fontAwesomeFont(60.0),
                                          range:NSRange(location: 0, length: attributedString.length))
            if #available(iOS 10.0, *) {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.init(rgbHex: 0xF3F3F3),
                                              range:NSRange(location: 0, length: attributedString.length))
            } else {
                // Fallback on earlier versions
            }
            
            break
        case .inviteReg:
            attributedString = NSMutableAttributedString(string: "Please, enter your\nphone number")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 7
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:regularFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.black, range:NSRange(location: 0, length: attributedString.length))
            break
        case .vinciTerms:
            attributedString = NSMutableAttributedString(string: "by continuing, you agree with the terms\nof use and privacy policy")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:tinyFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            
            attributedString.addAttribute(NSAttributedString.Key.link, value: "https://vinci.id/messanger.html", range: NSRange(location: 30, length: 16))
            attributedString.addAttribute(NSAttributedString.Key.link, value: "https://vinci.id/messanger.html", range: NSRange(location: 51, length: 14))
            
            if #available(iOS 10.0, *) {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.init(displayP3Red: 160/255, green: 163/255, blue: 159/255, alpha: 255/255), range:NSRange(location: 0, length: attributedString.length))
            } else {
                // Fallback on earlier versions
            }
            
            break
        }
        
        return attributedString
    }
    
    class func confirmationAttributedStrings(type:confirmationStringsType, attribute:String?) -> NSAttributedString {
        
        let attributedString:NSMutableAttributedString
        
        switch type {
        case .enterCode:
            attributedString = NSMutableAttributedString(string: "Enter verification code\nsent to \(attribute ?? "")")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 7
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:regularFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.black, range:NSRange(location: 0, length: attributedString.length))
            break
        case .codeProblems:
            attributedString = NSMutableAttributedString(string: "Any problems? send again\nor change the phone number")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:tinyFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            
            attributedString.addAttribute(NSAttributedString.Key.link, value: "repeatSMSCode", range: NSRange(location: 14, length: 10))
            attributedString.addAttribute(NSAttributedString.Key.link, value: "back", range: NSRange(location: 28, length: 23))
            
            if #available(iOS 10.0, *) {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.init(displayP3Red: 160/255, green: 163/255, blue: 159/255, alpha: 255/255), range:NSRange(location: 0, length: attributedString.length))
            } else {
                // Fallback on earlier versions
            }
            break
        }
        
        return attributedString
    }
    
    class func newProfileAttributedStrings(type:newProfileStringsType) -> NSAttributedString {
        
        let attributedString:NSMutableAttributedString
        
        switch type {
        case .enterNickname:
            attributedString = NSMutableAttributedString(string: "Please, create\na nickname")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 7
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:regularFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.black, range:NSRange(location: 0, length: attributedString.length))
            break
        case .profileNote:
            attributedString = NSMutableAttributedString(string: "Your profile will be visible to your contacts when you start\na conversation or share something with other users and groups")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:tinyFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            if #available(iOS 10.0, *) {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.init(displayP3Red: 160/255, green: 163/255, blue: 159/255, alpha: 255/255), range:NSRange(location: 0, length: attributedString.length))
            } else {
                // Fallback on earlier versions
            }
            break
        }
        
        return attributedString
    }
    
    class func emptyChatsAttributedStrings(type:emptyChatsStringsType) -> NSAttributedString {
        
        let attributedString:NSMutableAttributedString
        
        switch type {
        case .startConversation:
            attributedString = NSMutableAttributedString(string: "Start your first Vinci\nconversation!")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 3
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:regularFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.black, range:NSRange(location: 0, length: attributedString.length))
            break
        case .toBegin:
            attributedString = NSMutableAttributedString(string: "Tap on the compose button to begin")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 0
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:tinyFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            if #available(iOS 10.0, *) {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.init(displayP3Red: 160/255, green: 163/255, blue: 159/255, alpha: 255/255), range:NSRange(location: 0, length: attributedString.length))
            } else {
                // Fallback on earlier versions
            }
            break
        }
        
        return attributedString
    }
    
    class func emptyCallsAttributedStrings(type:emptyCallsStringsType) -> NSAttributedString {
        
        let attributedString:NSMutableAttributedString
        
        switch type {
        case .startCalls:
            attributedString = NSMutableAttributedString(string: "Start your first Vinci\ncall!")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 7
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:regularFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.black, range:NSRange(location: 0, length: attributedString.length))
            break
        case .toBegin:
            attributedString = NSMutableAttributedString(string: "Tap on the phone button to begin")
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            paragraphStyle.lineHeightMultiple = 1.0
            
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attributedString.length))
            attributedString.addAttribute(NSAttributedString.Key.font, value:tinyFont,
                                          range:NSRange(location: 0, length: attributedString.length))
            if #available(iOS 10.0, *) {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value:UIColor.init(displayP3Red: 160/255, green: 163/255, blue: 159/255, alpha: 255/255), range:NSRange(location: 0, length: attributedString.length))
            } else {
                // Fallback on earlier versions
            }
            break
        }
        
        return attributedString
    }
}

extension String {
    
    func contains(_ find: String) -> Bool{
        return self.range(of: find) != nil
    }
    
    func containsIgnoringCase(_ find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
}

class InsetLabel: UILabel {
    var topInset: CGFloat = 0.0
    var leftInset: CGFloat = 0.0
    var bottomInset: CGFloat = 0.0
    var rightInset: CGFloat = 0.0
    
    var insets: UIEdgeInsets {
        get {
            return UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        }
        set {
            topInset = newValue.top
            leftInset = newValue.left
            bottomInset = newValue.bottom
            rightInset = newValue.right
        }
    }
    
    override func drawText(in rect: CGRect) {
        let insetsRect = CGRect(x: rect.minX + insets.left, y: rect.minY + insets.top, width: rect.width - (insets.left + insets.right), height: rect.height - (insets.top + insets.bottom))
        super.drawText(in: insetsRect)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var adjSize = super.sizeThatFits(size)
        adjSize.width += leftInset + rightInset
        adjSize.height += topInset + bottomInset
        
        return adjSize
    }
    
    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += leftInset + rightInset
        contentSize.height += topInset + bottomInset
        
        return contentSize
    }
}
