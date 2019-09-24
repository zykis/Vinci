//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

class VinciChallengeCollectionSmallCell: UICollectionViewCell {
    var challenge: Challenge?
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView = UIImageView(frame: self.bounds)
        let minEdge = min(self.bounds.width, self.bounds.height)
        self.imageView.layer.cornerRadius = minEdge / 8.0
        self.imageView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        self.imageView.clipsToBounds = true
        self.imageView.contentMode = .scaleAspectFill
        self.contentView.addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func setup(challenge: Challenge) {
        self.challenge = challenge
        // FIXME: Load an avatar instead of 1st Media
        if let firstMedia = challenge.medias.first, let url = URL(string: firstMedia.url) {
            self.imageView.downloadAndSetupImage(with: url, completion: nil)
        }
    }
}
