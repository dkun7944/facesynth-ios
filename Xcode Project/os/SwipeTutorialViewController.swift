//
//  SwipeTutorialViewController.swift
//  Pitch
//
//  Created by Daniel Kuntz on 3/18/17.
//  Copyright © 2017 Plutonium Apps. All rights reserved.
//

import UIKit

class SwipeTutorialViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var hand: UIImageView!
    @IBOutlet weak var swipeLabel: UILabel!
    @IBOutlet weak var handTopConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    
    var handMinDistanceFromEdge: CGFloat = 80
    var movingDown: Bool = true
    
    // MARK: - Setup Views

    override func viewDidLoad() {
        super.viewDidLoad()
        prepareForAnimation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        moveDown()
    }
    
    // MARK: - Animation
    
    func prepareForAnimation() {
        hand.alpha = 0.0
        handTopConstraint.constant = handMinDistanceFromEdge
    }
    
    func moveDown() {
        handTopConstraint.constant = constraintForBottom()
        animate()
    }
    
    func moveUp() {
        handTopConstraint.constant = handMinDistanceFromEdge
        animate()
    }
    
    func animate() {
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.hand.alpha = 1.0
        }, completion: { finished in
            UIView.animate(withDuration: 0.3, delay: 1.3, options: [.curveEaseInOut], animations: {
                self.hand.alpha = 0.0
            }, completion: { finished in
                self.hand.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    self.switchDirection()
                })
            })
        })
        
        UIView.animate(withDuration: 0.3, delay: 0.5, options: [.curveEaseInOut], animations: {
            self.hand.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }, completion: nil)
        
        UIView.animate(withDuration: 1.2, delay: 1.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.4, options: [.curveEaseInOut], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func switchDirection() {
        DispatchQueue.main.async {
            self.movingDown ? self.moveUp() : self.moveDown()
            self.movingDown = !self.movingDown
        }
    }
    
    func constraintForBottom() -> CGFloat {
        let distanceFromLabel = view.frame.height - swipeLabel.frame.origin.y
        return view.frame.height - hand.frame.height - handMinDistanceFromEdge - distanceFromLabel
    }
    
    // MARK: - Actions
    
    @IBAction func gotItPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Status Bar Style
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
