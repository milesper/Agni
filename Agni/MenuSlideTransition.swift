//
//  MenuSlideTransition.swift
//  Agni
//
//  Created by Michael Ginn on 7/9/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit
import QuartzCore

class MenuSlideTransition: NSObject, UIViewControllerAnimatedTransitioning {
    var originButton:UIButton?
    init(button:UIButton?){
        self.originButton = button
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 1.2
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)! as! AgniViewController
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)! as! MenuViewController
        let finalFrameForVC = transitionContext.finalFrameForViewController(toViewController)
        let containerView = transitionContext.containerView()
        let bounds = UIScreen.mainScreen().bounds
        
        guard let button = originButton else{print("transition failed");return}
        let buttonSnapshot = button.snapshotViewAfterScreenUpdates(true)
        buttonSnapshot.frame = button.frame
        let finalFrameForButton = fromViewController.volumeButton.frame
        button.alpha = 0.0
        
        toViewController.view.frame = CGRectOffset(finalFrameForVC, 0, bounds.size.height)
        toViewController.view.backgroundColor = UIColor.clearColor()
        let whiteView = UIView(frame: bounds)
        whiteView.backgroundColor = UIColor.whiteColor()
        
        containerView?.addSubview(whiteView)
        containerView?.addSubview(fromViewController.view)
        containerView?.addSubview(toViewController.view)
        containerView?.addSubview(buttonSnapshot)
        
        UIView.animateWithDuration(1.0, delay: 0.0, options: .CurveEaseInOut, animations: {
            toViewController.view.frame.origin.y = 0
            fromViewController.view.alpha = 0.0
            }, completion: {
                finished in
                toViewController.view.backgroundColor = UIColor.whiteColor()
                fromViewController.view.alpha = 1.0
        })
        
        UIView.animateWithDuration(1.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            buttonSnapshot.frame = finalFrameForButton
            buttonSnapshot.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
            }, completion: {
                finished in
                button.alpha = 1.0
                toViewController.menuButton.alpha = 1.0
                buttonSnapshot.removeFromSuperview()
                
                containerView?.addSubview(toViewController.view)
                transitionContext.completeTransition(true)
        })
    }
}
