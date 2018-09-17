//
//  DismissAnimator.swift
//  Agni
//
//  Created by Michael Ginn on 9/21/17.
//  Copyright © 2017 Michael Ginn. All rights reserved.
//

import UIKit

/**
 Dismissal transition for a simple sliding down animation
 */
class DismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) ->TimeInterval{
        return 0.6
    }
    
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey:.from),
            let toVC = transitionContext.viewController(forKey: .to)
            else {
                return
        }
        let containerView = transitionContext.containerView
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        let screenBounds = UIScreen.main.bounds
        let bottomLeftCorner = CGPoint(x: 0, y: screenBounds.height)
        let finalFrame = CGRect(origin: bottomLeftCorner, size: screenBounds.size)
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                fromVC.view.frame = finalFrame
        },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        )
    }
}
