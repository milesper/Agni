//
//  ReverseCircleTransition.swift
//  Agni
//
//  Created by Michael Ginn on 7/7/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit

class ReverseCircleTransition: NSObject, UIViewControllerAnimatedTransitioning {
    weak var transitionContext: UIViewControllerContextTransitioning?
    var originButton:UIButton?
    var titleLabel:UILabel?
    init(button:UIButton?){
        self.originButton = button
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.5
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        let containerView = transitionContext.containerView() //container for transition
        
        guard let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) else {return}
        guard let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)  else{return}
        
        containerView!.addSubview(toViewController.view)
        containerView?.sendSubviewToBack(toViewController.view)
        
        guard let button = originButton else {return}
        
        let circleMaskPathInitial = UIBezierPath(ovalInRect: CGRect(x: ((containerView?.frame.width)! / 2.0) - 25,y: button.frame.minY,width: 50,height: 50))
        let extremePoint = CGPoint(x: button.center.x - 0, y: button.center.y - CGRectGetHeight(fromViewController.view.bounds))
        let radius = sqrt((extremePoint.x*extremePoint.x) + (extremePoint.y*extremePoint.y))
        let circleMaskPathFinal = UIBezierPath(ovalInRect: CGRectInset(button.frame, -radius, -radius))
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = circleMaskPathInitial.CGPath
        fromViewController.view.layer.mask = maskLayer
        
        let maskLayerAnimation = CABasicAnimation(keyPath: "path")
        maskLayerAnimation.fromValue = circleMaskPathFinal.CGPath
        maskLayerAnimation.toValue = circleMaskPathInitial.CGPath
        maskLayerAnimation.duration = self.transitionDuration(transitionContext)
        maskLayerAnimation.delegate = self
        maskLayer.addAnimation(maskLayerAnimation, forKey: "path")
        
        self.titleLabel = (fromViewController as! StatsViewController).titleLabel
        let titleAnimation = CABasicAnimation(keyPath: "position.y")
        titleAnimation.toValue = 16
        titleAnimation.duration = self.transitionDuration(transitionContext)
        titleAnimation.delegate = self
        titleLabel?.layer.addAnimation(titleAnimation, forKey: "movement")
        
        let titleFadeAnimation = CABasicAnimation(keyPath: "opacity")
        titleFadeAnimation.toValue = 0.0
        titleFadeAnimation.removedOnCompletion = false
        titleFadeAnimation.duration = self.transitionDuration(transitionContext)
        titleLabel?.layer.addAnimation(titleFadeAnimation, forKey: "fade")
        
        let statsView = (fromViewController as! StatsViewController).statsView
        let statsAnimation = CABasicAnimation(keyPath: "position.y")
        statsAnimation.toValue = containerView?.frame.height
        statsAnimation.duration = self.transitionDuration(transitionContext)
        statsAnimation.delegate = self
        statsView?.layer.addAnimation(statsAnimation, forKey: "movement")
        
        let statsViewFadeAnimation = CABasicAnimation(keyPath: "opacity")
        statsViewFadeAnimation.fromValue = 1.0
        statsViewFadeAnimation.toValue = 0.0
        statsViewFadeAnimation.removedOnCompletion = false
        statsViewFadeAnimation.duration = self.transitionDuration(transitionContext)
        statsView?.layer.addAnimation(statsViewFadeAnimation, forKey: "fade")

    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        self.transitionContext?.completeTransition(!self.transitionContext!.transitionWasCancelled())
        self.transitionContext?.viewControllerForKey(UITransitionContextFromViewControllerKey)?.view.layer.mask = nil
    }

}
