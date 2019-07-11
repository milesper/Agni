//
//  ConfettiTransition.swift
//  Agni
//
//  Created by Michael Ginn on 7/30/17.
//  Copyright © 2017 Michael Ginn. All rights reserved.
//

import UIKit

class ConfettiTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        let containerView = transitionContext.containerView
        
        toViewController.view.alpha = 0.0
        containerView.backgroundColor = UIColor.white
        containerView.addSubview(toViewController.view)
        containerView.sendSubviewToBack(toViewController.view)
        
        let cheerView = CheerView()
        cheerView.frame = containerView.frame
        containerView.addSubview(cheerView)
        cheerView.config.particle = .confetti
        cheerView.config.colors = [UIColor.AgniColors.Blue, UIColor.AgniColors.Green, UIColor.AgniColors.Purple, UIColor.AgniColors.Red, UIColor.AgniColors.Teal]
        
        cheerView.start()
        
        UIView.animate(withDuration: 1.0, animations: {
            fromViewController.view.alpha = 0.0
        }, completion: {
            finished in
            UIView.animate(withDuration: 1.0, animations: {
                toViewController.view.alpha = 1.0
            }, completion: {
                finished in
                cheerView.stop()
                transitionContext.completeTransition(true)
            })
        })
    }
}
