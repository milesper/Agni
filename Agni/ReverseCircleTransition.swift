//
//  ReverseCircleTransition.swift
//  Agni
//
//  Created by Michael Ginn on 7/7/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit

class ReverseCircleTransition: NSObject, UIViewControllerAnimatedTransitioning, CAAnimationDelegate {
    weak var transitionContext: UIViewControllerContextTransitioning?
    var originButton:UIButton?
    var titleLabel:UILabel?
    init(button:UIButton?){
        self.originButton = button
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        let containerView = transitionContext.containerView //container for transition
        
        guard let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else {return}
        guard let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)  else{return}
        
        containerView.addSubview(toViewController.view)
        containerView.sendSubview(toBack: toViewController.view)
        
        guard let button = originButton else {return}
        
        let circleMaskPathInitial = UIBezierPath(ovalIn: CGRect(x: ((containerView.frame.width) / 2.0) - 25,y: button.frame.minY,width: 50,height: 50))
        let extremePoint = CGPoint(x: button.center.x - 0, y: button.center.y - fromViewController.view.bounds.height)
        let radius = sqrt((extremePoint.x*extremePoint.x) + (extremePoint.y*extremePoint.y))
        let circleMaskPathFinal = UIBezierPath(ovalIn: button.frame.insetBy(dx: -radius, dy: -radius))
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = circleMaskPathInitial.cgPath
        fromViewController.view.layer.mask = maskLayer
        
        let maskLayerAnimation = CABasicAnimation(keyPath: "path")
        maskLayerAnimation.fromValue = circleMaskPathFinal.cgPath
        maskLayerAnimation.toValue = circleMaskPathInitial.cgPath
        maskLayerAnimation.duration = self.transitionDuration(using: transitionContext)
        maskLayerAnimation.delegate = self
        maskLayer.add(maskLayerAnimation, forKey: "path")
        
        self.titleLabel = (fromViewController as! StatsViewController).titleLabel
        let titleAnimation = CABasicAnimation(keyPath: "position.y")
        titleAnimation.toValue = 16
        titleAnimation.duration = self.transitionDuration(using: transitionContext)
        titleAnimation.delegate = self
        titleLabel?.layer.add(titleAnimation, forKey: "movement")
        
        let titleFadeAnimation = CABasicAnimation(keyPath: "opacity")
        titleFadeAnimation.toValue = 0.0
        titleFadeAnimation.isRemovedOnCompletion = false
        titleFadeAnimation.duration = self.transitionDuration(using: transitionContext)
        titleLabel?.layer.add(titleFadeAnimation, forKey: "fade")
        
        let statsView = (fromViewController as! StatsViewController).statsView
        let statsAnimation = CABasicAnimation(keyPath: "position.y")
        statsAnimation.toValue = containerView.frame.height
        statsAnimation.duration = self.transitionDuration(using: transitionContext)
        statsAnimation.delegate = self
        statsView?.layer.add(statsAnimation, forKey: "movement")
        
        let statsViewFadeAnimation = CABasicAnimation(keyPath: "opacity")
        statsViewFadeAnimation.fromValue = 1.0
        statsViewFadeAnimation.toValue = 0.0
        statsViewFadeAnimation.isRemovedOnCompletion = false
        statsViewFadeAnimation.duration = self.transitionDuration(using: transitionContext)
        statsView?.layer.add(statsViewFadeAnimation, forKey: "fade")
        
    }
    
     func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.transitionContext?.completeTransition(!self.transitionContext!.transitionWasCancelled)
        self.transitionContext?.viewController(forKey: UITransitionContextViewControllerKey.from)?.view.layer.mask = nil
    }
    
}
