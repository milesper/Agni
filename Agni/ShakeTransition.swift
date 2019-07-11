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
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2.0
    }
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        //let finalFrameForVC = transitionContext.finalFrameForViewController(toViewController)
        let containerView = transitionContext.containerView
        //let bounds = UIScreen.mainScreen().bounds
        
        toViewController.view.alpha = 0.0
        containerView.backgroundColor = UIColor.white
        containerView.addSubview(toViewController.view)
        containerView.sendSubviewToBack(toViewController.view)
        let shake = CAKeyframeAnimation(keyPath: "transform.translation.x")
        shake.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        shake.duration = 1.5
        shake.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
        fromViewController.view.layer.add(shake, forKey: "shake")
        
        UIView.animate(withDuration: 1.5, delay: 0.0, options: UIView.AnimationOptions(), animations: {
            fromViewController.view.alpha = 0.0
            toViewController.view.alpha = 1.0
            }, completion: {
                finished in
                transitionContext.completeTransition(true)
        })
        
    }

}
