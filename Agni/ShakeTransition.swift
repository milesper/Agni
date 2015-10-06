//
//  ShakeTransition.swift
//  Agni
//
//  Created by Michael Ginn on 5/3/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit

class ShakeTransition: NSObject,UIViewControllerAnimatedTransitioning {
    //custom transition between screens 
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 2.0
    }
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        //let finalFrameForVC = transitionContext.finalFrameForViewController(toViewController)
        let containerView = transitionContext.containerView()
        //let bounds = UIScreen.mainScreen().bounds
        
        toViewController.view.alpha = 0.0
        containerView!.backgroundColor = UIColor.whiteColor()
        containerView!.addSubview(toViewController.view)
        containerView!.sendSubviewToBack(toViewController.view)
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        shake.duration = 1.5
        shake.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
        fromViewController.view.layer.addAnimation(shake, forKey: "shake")
        
        UIView.animateWithDuration(1.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            fromViewController.view.alpha = 0.0
            toViewController.view.alpha = 1.0
            }, completion: {
                finished in
                transitionContext.completeTransition(true)
        })
        
    }

}
