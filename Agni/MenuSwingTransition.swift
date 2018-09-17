//
//  MenuSwingTransition.swift
//  Agni
//
//  Created by Michael Ginn on 8/14/17.
//  Copyright © 2017 Michael Ginn. All rights reserved.
//

import UIKit

class MenuSwingTransition: NSObject, UIViewControllerAnimatedTransitioning, UIDynamicAnimatorDelegate {
    let transitionDuration = 0.5
    var animator:UIDynamicAnimator?
    var context: UIViewControllerContextTransitioning!
    
    var originButton:UIButton?
    
    init(button:UIButton?){
        self.originButton = button

    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        context = transitionContext
        
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)! as! AgniViewController
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)! as! MenuViewController
        let containerView = transitionContext.containerView

        guard let menuView = toViewController.view else{return}
        containerView.addSubview(fromViewController.view)
        
        
        menuView.transform = CGAffineTransform.identity.rotated(by: degreesToRadians(-90))
        menuView.frame = CGRect(x: 0, y: -menuView.frame.height, width: menuView.frame.width, height: menuView.frame.height)
        
        containerView.addSubview(menuView)
        
        //Now do the actual animations
        animator = UIDynamicAnimator(referenceView: containerView)
        animator?.delegate = self
        
        let vectorDY = CGFloat((4/Double.pi) * Double(UIScreen.main.bounds.size.height) / transitionDuration) //How hard to push the view to the right
        let rotationDirection = CGVector(dx: 0, dy: vectorDY)

        
        let fromX:CGFloat = -1.0
        let fromY = containerView.frame.height - 1.0
        let toX = fromX
        let toY = fromY + 1
        
        let anchorPoint = CGPoint(x: 0, y: 0)
        
        let viewOffset = UIOffsetMake(-menuView.bounds.size.width / 2 + anchorPoint.x, -menuView.bounds.size.height / 2 + anchorPoint.y)
        let attachmentBehaviour = UIAttachmentBehavior(item: menuView, offsetFromCenter: viewOffset, attachedToAnchor: anchorPoint)
        animator!.addBehavior(attachmentBehaviour)

        
        let collisionBehaviour = UICollisionBehavior()
        collisionBehaviour.addBoundary(withIdentifier: "collide" as NSCopying, from: CGPoint(x: fromX, y: fromY), to: CGPoint(x: toX, y: toY))
        collisionBehaviour.addItem(menuView)
        animator!.addBehavior(collisionBehaviour)
        
        let itemBehaviour = UIDynamicItemBehavior(items: [menuView])
        itemBehaviour.elasticity = 0.55
        itemBehaviour.density = 1.7
        animator!.addBehavior(itemBehaviour)
        
        let fallBehaviour = UIPushBehavior(items:[menuView], mode: .continuous)
        fallBehaviour.pushDirection = rotationDirection
        animator!.addBehavior(fallBehaviour)

    }
    
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        context.completeTransition(true)
    }

    
    fileprivate func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees / 180.0 * CGFloat(Double.pi)
    }
    
    fileprivate func radiansToDegrees(_ radians: CGFloat) -> CGFloat {
        return radians * 180.0 / CGFloat(Double.pi)
    }
}
