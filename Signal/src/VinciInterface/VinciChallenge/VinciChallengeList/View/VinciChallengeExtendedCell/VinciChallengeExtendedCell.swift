//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let kVinciChallengeExtendedCellReuseIdentifier = "VinciChallengeExtendedCellRI"
let kVinciChallengeCollectionCellReuseIdentifier = "VinciChallengeCollectionCellRI"
let kCellCollectionViewHeight: CGFloat = 180.0
let kCollectionCellMargin: CGFloat = 12.0

class VinciChallengeExtendedCell: VinciChallengeCompactCell {
    var collectionView: UICollectionView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.collectionView = UICollectionView(frame: .null, collectionViewLayout: UICollectionViewFlowLayout())
        self.collectionView.backgroundColor = .clear
        self.collectionView.showsHorizontalScrollIndicator = false
        let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .horizontal
        self.contentView.addSubview(self.collectionView)
        self.setupCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.compactCellViewBottomConstraint?.isActive = false
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.topAnchor.constraint(equalTo: self.compactCellView.bottomAnchor, constant: kCollectionCellMargin).isActive = true
        self.collectionView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: kCellMargin).isActive = true
        self.collectionView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -kCellMargin).isActive = true
        self.collectionView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -kCollectionCellMargin).isActive = true
        self.collectionView.heightAnchor.constraint(equalToConstant: kCellCollectionViewHeight).isActive = true
    }
    
    func setupCollectionView() {
        self.collectionView.register(VinciChallengeCollectionSmallCell.self, forCellWithReuseIdentifier: kVinciChallengeCollectionCellReuseIdentifier)
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
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: kVinciChallengeCollectionCellReuseIdentifier, for: indexPath)
        return cell
    }
}


extension VinciChallengeExtendedCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height: CGFloat = self.collectionView.bounds.height
        let width: CGFloat = height * 3.0 / 4.0
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4.0
    }
}
