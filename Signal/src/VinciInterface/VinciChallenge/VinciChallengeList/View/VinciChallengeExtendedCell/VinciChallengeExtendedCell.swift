//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let VinciChallengeExtendedCellNibName = "VinciChallengeExtendedCell"
let VinciChallengeExtendedCellReuseIdentifier = "VinciChallengeExtendedCellRI"
let kCellCollectionViewHeight: CGFloat = 88.0

class VinciChallengeExtendedCell: VinciChallengeCompactCell {
    var collectionView: UICollectionView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.collectionView = UICollectionView(frame: .null, collectionViewLayout: UICollectionViewFlowLayout())
        self.collectionView.backgroundColor = UIColor.gray
        self.contentView.addSubview(self.collectionView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.compactCellViewBottomConstraint?.isActive = false
        self.collectionView.topAnchor.constraint(equalTo: self.compactCellView.bottomAnchor, constant: kCellMargin).isActive = true
        self.collectionView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: kCellMargin).isActive = true
        self.collectionView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -kCellMargin).isActive = true
        self.collectionView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -kCellMargin).isActive = true
        self.collectionView.heightAnchor.constraint(equalToConstant: kCellCollectionViewHeight).isActive = true
    }
    
    func setupCollectionView() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
}


extension VinciChallengeExtendedCell: UICollectionViewDelegate {
    
}


extension VinciChallengeExtendedCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
}
