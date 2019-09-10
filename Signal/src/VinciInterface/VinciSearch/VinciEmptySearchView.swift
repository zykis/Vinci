//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

class VinciEmptySearchView: UIView {
    
    var imageView: UIImageView!
    var largeTitle: UILabel!
    var subtitleLabel: UILabel!
    
    var isSearching: Bool = false {
        didSet {
            imageView.isHidden = self.isSearching
            largeTitle.isHidden = self.isSearching
            subtitleLabel.isHidden = self.isSearching
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
            
        imageView = UIImageView(image: UIImage(named: "startSearchIcon"))
        largeTitle = UILabel(frame: CGRect.zero)
        subtitleLabel = UILabel(frame: CGRect.zero)
        
        largeTitle.attributedText = VinciStrings.emptyAttributedStrings(type: .emptyLookingForSmth)
        subtitleLabel.attributedText = VinciStrings.emptyAttributedStrings(type: .emptyStartSearching)
        
        largeTitle.numberOfLines = 2
        largeTitle.sizeToFit()
        
        subtitleLabel.numberOfLines = 2
        subtitleLabel.sizeToFit()
        
        addSubview(imageView)
        addSubview(largeTitle)
        addSubview(subtitleLabel)
        
        imageView.autoPinEdge(.top, to: .top, of: self, withOffset: 64.0)
        imageView.autoPinEdge(.left, to: .left, of: self, withOffset: 122.0)
        
        largeTitle.autoPinEdge(.left, to: .left, of: self, withOffset: 12.0)
        largeTitle.autoPinEdge(.top, to: .bottom, of: imageView, withOffset: 22.0)
        
        subtitleLabel.autoPinEdge(.left, to: .left, of: self, withOffset: 42.0)
        subtitleLabel.autoPinEdge(.top, to: .top, of: largeTitle, withOffset: 80.0)
        
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
