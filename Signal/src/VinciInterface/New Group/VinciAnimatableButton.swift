import UIKit


class VinciAnimatableButton: UIButton {
    var startTransform: CGAffineTransform?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        startTransform = transform
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.transform = self.startTransform!.scaledBy(x: 0.8, y: 0.8)
        })
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       usingSpringWithDamping: 0.25,
                       initialSpringVelocity: 6.0,
                       options: UIView.AnimationOptions.allowUserInteraction,
                       animations: { () -> Void in
                            self.transform = self.startTransform!
        }) { (Bool) -> Void in
            self.sendActions(for: .touchUpInside)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       usingSpringWithDamping: 0.25,
                       initialSpringVelocity: 6.0,
                       options: UIView.AnimationOptions.allowUserInteraction,
                       animations: { () -> Void in
                            self.transform = self.startTransform!
        }) { (Bool) -> Void in
            self.sendActions(for: .touchUpInside)
        }
    }
}
