import UIKit
import UIKit.UIGestureRecognizerSubclass

public extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

public class ImmediatePanGestureRecognizer: UIPanGestureRecognizer {
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        state = .began
    }
}

//Without this import line, you'll get compiler errors when implementing your touch methods since they aren't part of the UIGestureRecognizer superclass
import UIKit.UIGestureRecognizerSubclass

//Since 3D Touch isn't available before iOS 9, we can use the availability APIs to ensure no one uses this class for earlier versions of the OS.
@available(iOS 9.0, *)
public class ForceTouchGestureRecognizer: UIGestureRecognizer {
    //Because we don't know what the maximum force will always be for a UITouch, the force property here will be normalized to a value between 0.0 and 1.0.
    public private(set) var force: CGFloat = 0.5
    public var maximumForce: CGFloat = 10.0
    
    convenience init() {
        self.init(target: nil, action: nil)
    }
    
    //We override the initializer because UIGestureRecognizer's cancelsTouchesInView property is true by default. If you were to, say, add this recognizer to a tableView's cell, it would prevent didSelectRowAtIndexPath from getting called. Thanks for finding this bug, Jordan Hipwell!
    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        normalizeForceAndFireEvent(.began, touches: touches)
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        normalizeForceAndFireEvent(.changed, touches: touches)
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        normalizeForceAndFireEvent(.ended, touches: touches)
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        normalizeForceAndFireEvent(.cancelled, touches: touches)
    }
    
    private func normalizeForceAndFireEvent(_ state: UIGestureRecognizerState, touches: Set<UITouch>) {
        //Putting a guard statement here to make sure we don't fire off our target's selector event if a touch doesn't exist to begin with.
        guard let firstTouch = touches.first else { return }
        
        //Just in case the developer set a maximumForce that is higher than the touch's maximumPossibleForce, I'm setting the maximumForce to the lower of the two values.
        maximumForce = min(firstTouch.maximumPossibleForce, maximumForce)
        
        //Now that I have a proper maximumForce, I'm going to use that and normalize it so the developer can use a value between 0.0 and 1.0.
        force = firstTouch.force / maximumForce
        
        //Our properties are now ready for inspection by the developer. By setting the UIGestureRecognizer's state property, the system will automatically send the target the selector message that this recognizer was initialized with.
        self.state = state
    }
    
    //This function is called automatically by UIGestureRecognizer when our state is set to .Ended. We want to use this function to reset our internal state.
    public override func reset() {
        super.reset()
        force = 0.5
    }
}

public extension UIColor {
    @nonobjc static let pastelBlue: UIColor = UIColor(red: 88/255.0, green: 212/255.0, blue: 254/255.0, alpha: 1.0)
    @nonobjc static let pastelRed: UIColor = UIColor(red: 255/255.0, green: 113/255.0, blue: 84/255.0, alpha: 1.0)
    
    static func blend(color1: UIColor, intensity1: CGFloat = 0.5, color2: UIColor, intensity2: CGFloat = 0.5) -> UIColor {
        let total = intensity1 + intensity2
        let l1 = intensity1/total
        let l2 = intensity2/total
        guard l1 > 0 else { return color2 }
        guard l2 > 0 else { return color1 }
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor(red: l1*r1 + l2*r2, green: l1*g1 + l2*g2, blue: l1*b1 + l2*b2, alpha: l1*a1 + l2*a2)
    }
}
