//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import UIKit

class VinciEmptyChatsView: UIView {
    
    var imageView: UIImageView!
    var largeTitle: UILabel!
    var subtitleLabel: UILabel!
    var smallTextLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        
        imageView = UIImageView(image: UIImage(named: "emptyChatsIcon"))
        largeTitle = UILabel(frame: CGRect.zero)
        subtitleLabel = UILabel(frame: CGRect.zero)
        smallTextLabel = UILabel(frame: CGRect.zero)
        
        largeTitle.attributedText = VinciStrings.welcomeVinciString
        subtitleLabel.attributedText = VinciStrings.emptyChatsAttributedStrings(type: .startConversation)
        smallTextLabel.attributedText = VinciStrings.emptyChatsAttributedStrings(type: .toBegin)
        
        largeTitle.numberOfLines = 2
        largeTitle.sizeToFit()
        
        subtitleLabel.numberOfLines = 2
        subtitleLabel.sizeToFit()
        
        smallTextLabel.sizeToFit()
        
        addSubview(imageView)
        addSubview(largeTitle)
        addSubview(subtitleLabel)
        addSubview(smallTextLabel)
        
        imageView.autoSetDimension(.height, toSize: 287.0)
        imageView.autoSetDimension(.width, toSize: 361.0)
        imageView.autoPinEdge(.top, to: .top, of: self, withOffset: 56.0)
        imageView.autoPinEdge(.left, to: .left, of: self, withOffset: 83.0)
        
        largeTitle.autoPinEdge(.left, to: .left, of: self, withOffset: 15.0)
        largeTitle.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 25.0)
        
        subtitleLabel.autoPinEdge(.left, to: .left, of: largeTitle, withOffset: 30.5)
        subtitleLabel.autoPinEdge(.top, to: .top, of: largeTitle, withOffset: 80.0)
        
        smallTextLabel.autoPinEdge(.left, to: .left, of: largeTitle, withOffset: 30.0)
        smallTextLabel.autoPinEdge(.top, to: .top, of: subtitleLabel, withOffset: 65.0)
        
        backgroundColor = Theme.backgroundColor
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}

class VinciEmptyChatsViewCell: UITableViewCell {
    static let reuseIdentifier = "VinciEmptyChatsViewCell"
    
    let emptyView: VinciEmptyChatsView
    let isSearching: Bool = false
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.emptyView = VinciEmptyChatsView()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(emptyView)
        
        emptyView.autoPinEdge(toSuperviewEdge: .top, withInset: 0.0, relation: .greaterThanOrEqual)
        emptyView.autoPinEdge(toSuperviewEdge: .leading, withInset: 0.0, relation: .greaterThanOrEqual)
        emptyView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0.0, relation: .greaterThanOrEqual)
        emptyView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 0.0, relation: .greaterThanOrEqual)
        
        emptyView.autoVCenterInSuperview()
        emptyView.autoHCenterInSuperview()
        
        emptyView.setContentHuggingHigh()
        emptyView.setCompressionResistanceHigh()
    }
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    public func configure(size: CGSize) {
        emptyView.autoSetDimensions(to: size)
    }
}
