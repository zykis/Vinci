class VinciChecker: UIView {
    
    var animationBlocked = false
    var isChecked:Bool = false
    var checkImage = UIImage(named: "vinciCheck")?.withRenderingMode(.alwaysTemplate)
    var deleteImage = UIImage(named: "delCheckerIcon")?.withRenderingMode(.alwaysOriginal)
    var checkImageView = UIImageView(frame: CGRect.zero)
    let borderView:UIView = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        notImplemented()
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        
        borderView.layer.borderColor = Theme.cellSeparatorColor.cgColor
        borderView.layer.borderWidth = 1
        borderView.layer.cornerRadius = 11
        
        addSubview(borderView)
        borderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0))
        
        checkImageView.image = checkImage
        checkImageView.tintColor = UIColor.vinciBrandBlue
        checkImageView.alpha = 0.0
        
        addSubview(checkImageView)
        checkImageView.autoPinEdgesToSuperviewEdges()
    }
    
    init(checked:Bool) {
        super.init(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        
        animationBlocked = false
        
        borderView.layer.borderColor = Theme.cellSeparatorColor.cgColor
        borderView.layer.borderWidth = 1
        borderView.layer.cornerRadius = 11
        addSubview(borderView)
        borderView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0))
        
        checkImageView.image = checkImage
        checkImageView.tintColor = UIColor.vinciBrandBlue
        addSubview(checkImageView)
        if ( !checked ) {
            let selfFrame = self.frame
            checkImageView.frame = CGRect(x: selfFrame.width/2, y: selfFrame.height/2, width: 0, height: 0)
            alpha = 0.0
        } else {
            isChecked = true
            checkImageView.autoPinEdgesToSuperviewEdges()
            alpha = 1.0
        }
    }
    
    public func setChecker(delImage: Bool) {
        if delImage {
            checkImageView.image = deleteImage
        } else {
            checkImageView.image = checkImage
        }
    }
    
    func setState(checked:Bool, animated:Bool) {
        
        if ( checked == isChecked ) {
            return
        }
        
        var newFrame:CGRect
        var alpha:CGFloat
        if ( !checked ) {
            let selfFrame = self.frame
            newFrame = CGRect(x: selfFrame.width/2, y: selfFrame.height/2, width: 0, height: 0)
            alpha = 0.0
        } else {
            newFrame = CGRect(x: 0, y: 0, width: 24, height: 24)
            self.checkImageView.alpha = 1.0
            alpha = 1.0
        }
        
        if ( animated && !animationBlocked ) {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
                self.checkImageView.frame = newFrame
                self.checkImageView.alpha = alpha
            }) { (finished) in
                self.isChecked = checked
            }
        } else {
            self.checkImageView.frame = newFrame
            self.checkImageView.alpha = alpha
            self.isChecked = checked
            
            animationBlocked = false
        }
    }
}
