//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
// 

import UIKit

class ExpandAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var duration = 0.15
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
        toView.layer.cornerRadius = cornerRadius
        
        // Setting up background image
        let imageView = UIImageView(frame: toView.bounds)
        imageView.image = originImage
        toView.addSubview(imageView)
//        toView.bringSubview(toFront: imageView)
        
        imageView.leftAnchor.constraint(equalTo: toView.leftAnchor)
        imageView.topAnchor.constraint(equalTo: toView.topAnchor)
        imageView.rightAnchor.constraint(equalTo: toView.rightAnchor)
        imageView.bottomAnchor.constraint(equalTo: toView.bottomAnchor)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        // Adding black overlay
        let overlayView = UIView(frame: toView.bounds)
        toView.addSubview(overlayView)
        toView.bringSubview(toFront: overlayView)
        overlayView.backgroundColor = .black
        overlayView.alpha = 0.0
        overlayView.leftAnchor.constraint(equalTo: toView.leftAnchor)
        overlayView.topAnchor.constraint(equalTo: toView.topAnchor)
        overlayView.rightAnchor.constraint(equalTo: toView.rightAnchor)
        overlayView.bottomAnchor.constraint(equalTo: toView.bottomAnchor)
        
        UIView.animate(withDuration: self.duration, delay: 0.0, options: .curveEaseInOut, animations: {
            let containerView = transitionContext.containerView
            containerView.addSubview(fromView)
            containerView.addSubview(toView)
            overlayView.alpha = 1.0
            toView.transform = CGAffineTransform.identity
            toView.center = fromView.center
            toView.layer.cornerRadius = 0.0 // FIXME: not working with UIView.animate (CABasicAnimation needed)
        }) { (_) in
            imageView.removeFromSuperview()
            overlayView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
}
