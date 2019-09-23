//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

class ExpandAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var duration = 0.4
    var originFrame: CGRect = .null
    var originImage: UIImage?
    var originCornerRadiusFactor: CGFloat = 8.0
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return self.duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromView = transitionContext.viewController(forKey: .from)!.view!
        let toView = transitionContext.viewController(forKey: .to)!.view!
        let cellFrame = self.originFrame
        let destFrame = fromView.frame
        
        let xScaleFactor = cellFrame.width / destFrame.width
        let yScaleFactor = cellFrame.height / destFrame.height
        
        toView.transform = CGAffineTransform(scaleX: xScaleFactor, y: yScaleFactor)
        toView.center = CGPoint(x: cellFrame.midX, y: cellFrame.midY)
        
        let cornerRadius: CGFloat = min(originFrame.width, originFrame.height) / originCornerRadiusFactor
        
        // Setting up background image
        let imageView = UIImageView(frame: toView.bounds)
        imageView.image = originImage
        toView.addSubview(imageView)
        toView.bringSubview(toFront: imageView)
        
        imageView.leftAnchor.constraint(equalTo: toView.leftAnchor)
        imageView.topAnchor.constraint(equalTo: toView.topAnchor)
        imageView.rightAnchor.constraint(equalTo: toView.rightAnchor)
        imageView.bottomAnchor.constraint(equalTo: toView.bottomAnchor)
        
        imageView.contentMode = .scaleAspectFill
        
        // Adding corner radius animation
        toView.layer.cornerRadius = cornerRadius
//        let animation = CABasicAnimation(keyPath:"cornerRadius")
//        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
//        animation.fromValue = cornerRadius
//        animation.toValue = 0.0
//        animation.duration = self.duration
//        toView.layer.add(animation, forKey: "cornerRadius")
        
        UIView.animate(withDuration: self.duration, animations: {
            let containerView = transitionContext.containerView
            containerView.addSubview(fromView)
            containerView.addSubview(toView)
            toView.transform = CGAffineTransform.identity
            toView.center = fromView.center
            toView.layer.cornerRadius = 16.0
        }) { (completed) in
            imageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
}
