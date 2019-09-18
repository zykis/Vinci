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
    var collectionHeightConstraint: NSLayoutConstraint?
    weak var challenge: Challenge?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addCollectionView()
        self.setupCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func addCollectionView() {
        self.collectionView = UICollectionView(frame: .null, collectionViewLayout: UICollectionViewFlowLayout())
        self.collectionView.backgroundColor = .clear
        self.collectionView.showsHorizontalScrollIndicator = false
        let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .horizontal
        self.contentView.addSubview(self.collectionView)
        
        self.compactCellViewBottomConstraint!.isActive = false
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.topAnchor.constraint(equalTo: self.compactCellView.bottomAnchor, constant: kCollectionCellMargin).isActive = true
        self.collectionView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: kCellMargin).isActive = true
        self.collectionView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -kCellMargin).isActive = true
        self.collectionView.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.bottomAnchor, constant: -kCollectionCellMargin).isActive = true
        self.collectionHeightConstraint = self.collectionView.heightAnchor.constraint(equalToConstant: 0)
        self.collectionHeightConstraint?.isActive = true
    }
    
    func setupCollectionView() {
        self.collectionView.register(VinciChallengeCollectionSmallCell.self, forCellWithReuseIdentifier: kVinciChallengeCollectionCellReuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    override func setup(with challenge: Challenge) {
        super.setup(with: challenge)
        self.challenge = challenge
        
        if challenge.medias.count > 0 {
            self.collectionHeightConstraint?.constant = kCellCollectionViewHeight
        } else {
            self.collectionHeightConstraint?.constant = 0
        }
        self.collectionView.reloadData()
//        for media in challenge.medias {
//            if let url = URL(string: media.url) {
//                self.imageView?.downloadAndSetupImage(with: url, completion: nil)
//            }
//        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.challenge = nil
    }
}


extension VinciChallengeExtendedCell: UICollectionViewDelegate {
    
}


extension VinciChallengeExtendedCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.challenge?.medias.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: VinciChallengeCollectionSmallCell = self.collectionView.dequeueReusableCell(withReuseIdentifier: kVinciChallengeCollectionCellReuseIdentifier, for: indexPath) as! VinciChallengeCollectionSmallCell
        
        cell.imageView.image = nil
        guard let count = self.challenge?.medias.count, count >= indexPath.row + 1
            else { return cell }
        if let urlString = self.challenge?.medias[indexPath.row].url, let mediaUrl = URL(string: urlString) {
            guard cell.imageView.image == nil
                else { return cell }
            cell.imageView.downloadAndSetupImage(with: mediaUrl, completion: nil)
        }
        
        return cell
    }
}


extension VinciChallengeExtendedCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height: CGFloat = self.collectionHeightConstraint?.constant ?? 0
        let width: CGFloat = height * 3.0 / 4.0
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 4.0
    }
}
