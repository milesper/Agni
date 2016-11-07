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
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)! as! AgniViewController
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)! as! MenuViewController
        let finalFrameForVC = transitionContext.finalFrame(for: toViewController)
        let containerView = transitionContext.containerView
        let bounds = UIScreen.main.bounds
        
        guard let button = originButton else{print("transition failed");return}
        let buttonSnapshot = button.snapshotView(afterScreenUpdates: true)
        buttonSnapshot?.frame = button.frame
        let finalFrameForButton = fromViewController.volumeButton.frame
        button.alpha = 0.0
        
        toViewController.view.frame = finalFrameForVC.offsetBy(dx: 0, dy: bounds.size.height)
        toViewController.view.backgroundColor = UIColor.clear
        let whiteView = UIView(frame: bounds)
        whiteView.backgroundColor = UIColor.white
        
        containerView.addSubview(whiteView)
        containerView.addSubview(fromViewController.view)
        containerView.addSubview(toViewController.view)
        containerView.addSubview(buttonSnapshot!)
        
        UIView.animate(withDuration: 0.8, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            toViewController.view.frame.origin.y = 0
            fromViewController.view.alpha = 0.0
            }, completion: {
                finished in
                toViewController.view.backgroundColor = UIColor.white
                fromViewController.view.alpha = 1.0
        })
        
        UIView.animate(withDuration: 1.0, delay: 0.0, options: UIViewAnimationOptions(), animations: {
            buttonSnapshot?.frame = finalFrameForButton
            buttonSnapshot?.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
            }, completion: {
                finished in
                button.alpha = 1.0
                toViewController.menuButton.alpha = 1.0
                buttonSnapshot?.removeFromSuperview()
                
                containerView.addSubview(toViewController.view)
                transitionContext.completeTransition(true)
        })
    }
}
