//
//  ReverseMenuSlideTransition.swift
//  Agni
//
//  Created by Michael Ginn on 7/11/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit

class ReverseMenuSlideTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.8
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)! as! MenuViewController
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)! as! AgniViewController
        let finalFrameForVC = transitionContext.finalFrame(for: toViewController)
        let containerView = transitionContext.containerView
        let bounds = UIScreen.main.bounds
        
        guard let button = fromViewController.menuButton else{print("transition failed");return}
        let buttonSnapshot = button.snapshotView(afterScreenUpdates: true)
        buttonSnapshot?.frame = button.frame
        
        button.alpha = 0.0
        toViewController.menuButton.alpha = 0.0
        toViewController.view.alpha = 0.0
        
        containerView.addSubview(toViewController.view)
        containerView.addSubview(fromViewController.view)
        containerView.addSubview(buttonSnapshot!)
        
        let finalFrameForButton = toViewController.menuButton.frame
        
        UIView.animate(withDuration: 0.7, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            fromViewController.view.frame = finalFrameForVC.offsetBy(dx: 0, dy: bounds.size.height)
            toViewController.view.alpha = 1.0
            }, completion: {
                finished in
        })
        
        UIView.animate(withDuration: 0.8, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            buttonSnapshot?.frame = finalFrameForButton
            buttonSnapshot?.transform = CGAffineTransform(rotationAngle: CGFloat(-1 * M_PI_2))
            }, completion: {
                finished in
                toViewController.menuButton.alpha = 1.0
                button.alpha = 1.0
                
                containerView.addSubview(toViewController.view)
                transitionContext.completeTransition(true)
        })
    }
}
