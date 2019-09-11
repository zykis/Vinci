//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let VinciChallengeExtendedCellNibName = "VinciChallengeExtendedCell"
let VinciChallengeExtendedCellReuseIdentifier = "VinciChallengeExtendedCellRI"

class VinciChallengeExtendedCell: VinciChallengeCompactCell {
    var collectionView: UICollectionView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.addCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addCollectionView()
    }
    
    func addCollectionView() {
        self.collectionView = UICollectionView()
    }
}
