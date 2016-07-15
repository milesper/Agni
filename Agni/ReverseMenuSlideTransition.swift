//
//  ReverseMenuSlideTransition.swift
//  Agni
//
//  Created by Michael Ginn on 7/11/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit

class ReverseMenuSlideTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.8
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)! as! MenuViewController
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)! as! AgniViewController
        let finalFrameForVC = transitionContext.finalFrameForViewController(toViewController)
        let containerView = transitionContext.containerView()
        let bounds = UIScreen.mainScreen().bounds
        
        guard let button = fromViewController.menuButton else{print("transition failed");return}
        let buttonSnapshot = button.snapshotViewAfterScreenUpdates(true)
        buttonSnapshot.frame = button.frame
        
        button.alpha = 0.0
        toViewController.menuButton.alpha = 0.0
        toViewController.view.alpha = 0.0
        
        containerView?.addSubview(toViewController.view)
        containerView?.addSubview(fromViewController.view)
        containerView?.addSubview(buttonSnapshot)
        
        let finalFrameForButton = toViewController.menuButton.frame
        
        UIView.animateWithDuration(0.7, delay: 0.0, options: .CurveEaseInOut, animations: {
            fromViewController.view.frame = CGRectOffset(finalFrameForVC, 0, bounds.size.height)
            toViewController.view.alpha = 1.0
            }, completion: {
                finished in
        })
        
        UIView.animateWithDuration(0.8, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            buttonSnapshot.frame = finalFrameForButton
            buttonSnapshot.transform = CGAffineTransformMakeRotation(CGFloat(-1 * M_PI_2))
            }, completion: {
                finished in
                toViewController.menuButton.alpha = 1.0
                button.alpha = 1.0
                
                containerView?.addSubview(toViewController.view)
                transitionContext.completeTransition(true)
        })
    }
}
