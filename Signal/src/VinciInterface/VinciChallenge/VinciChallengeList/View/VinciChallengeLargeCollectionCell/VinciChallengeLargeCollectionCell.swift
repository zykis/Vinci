//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

let kVinciChallengeLargeCollectionCellReuseIdentifier = "kVinciChallengeLargeCollectionCellRI"
let kLargeCollectionCellHeight: CGFloat = 128.0

class VinciChallengeLargeCollectionCell: UITableViewCell {
    var collectionView: UICollectionView! = UICollectionView(frame: CGRect(x: 0,
                                                                           y: 0,
                                                                           width: 500.0,
                                                                           height: kLargeCollectionCellHeight),
                                                             collectionViewLayout: UICollectionViewFlowLayout())
    
    private var elementSize: CGSize {
        get {
            return CGSize(width: self.collectionView.bounds.height * 2.0, height: self.collectionView.bounds.height)
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCollectionView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func setupCollectionView() {
        self.contentView.addSubview(self.collectionView)
        let flowLayout: UICollectionViewFlowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = .horizontal
        self.collectionView.backgroundColor = .clear
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.showsHorizontalScrollIndicator = false
        self.collectionView.register(VinciChallengeCollectionSmallCell.self, forCellWithReuseIdentifier: kVinciChallengeCollectionCellReuseIdentifier)
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: kCellMargin).isActive = true
        self.collectionView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -kCellMargin).isActive = true
        self.collectionView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: kCellMargin).isActive = true
        self.collectionView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -kCellMargin).isActive = true
    }
}


extension VinciChallengeListViewController: UICollectionViewDelegate {
    
}


extension VinciChallengeLargeCollectionCell: UICollectionViewDataSource {
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


extension VinciChallengeLargeCollectionCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.elementSize
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return kCollectionCellOffset
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let elementWidth: CGFloat = self.elementSize.width
        let ofs: CGFloat = kCollectionCellOffset
        let elementIndex: Int = Int(scrollView.contentOffset.x / (elementWidth + ofs))
        let elementPos: CGFloat = (scrollView.contentOffset.x / (elementWidth + ofs)) - CGFloat(elementIndex)
        let moreThenHalf: Bool = elementPos >= 0.5
        
        UIView.animate(withDuration: 0.2, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            let start: CGPoint = self.collectionView.contentOffset
            let end: CGPoint = CGPoint(x: CGFloat(moreThenHalf ? elementIndex + 1 : elementIndex) * (elementWidth + ofs), y: start.y)
            self.collectionView.contentOffset = end
            self.collectionView.layoutIfNeeded()
        }, completion: nil)
    }
}
