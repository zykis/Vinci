import UIKit


class VinciAnimatableButton: UIButton {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        })
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: UIView.AnimationOptions.allowUserInteraction,
                       animations: { () -> Void in
                        self.transform = CGAffineTransform.identity
        }) { (Bool) -> Void in
            self.sendActions(for: .touchUpInside)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: UIView.AnimationOptions.allowUserInteraction,
                       animations: { () -> Void in
                        self.transform = CGAffineTransform.identity
        }) { (Bool) -> Void in
            self.sendActions(for: .touchUpInside)
        }
    }
}
