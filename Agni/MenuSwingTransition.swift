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
    var snapshot:UIView?
    
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
        
        
        
        containerView.addSubview(menuView)
        guard let snapshot = menuView.snapshotView(afterScreenUpdates: true) else{return}
        self.snapshot = snapshot
        containerView.addSubview(snapshot)
        menuView.removeFromSuperview()
    
        snapshot.transform = CGAffineTransform.identity.rotated(by: degreesToRadians(-90))
        snapshot.frame = CGRect(x: 0, y: -snapshot.frame.height, width: snapshot.frame.width, height: snapshot.frame.height)

        
        
        //Now do the actual animations
        animator = UIDynamicAnimator(referenceView: containerView)
        animator?.delegate = self
        
        var vectorDY = CGFloat((4/Double.pi) * Double(UIScreen.main.bounds.size.height) / transitionDuration) //How hard to push the view to the right
        if UIDevice.current.userInterfaceIdiom == .pad{
            vectorDY = CGFloat((8/Double.pi) * Double(UIScreen.main.bounds.size.height) / transitionDuration)
        }
        let rotationDirection = CGVector(dx: 0, dy: vectorDY)

        
        let fromX:CGFloat = -1.0
        let fromY = containerView.frame.height - 1.0
        let toX = fromX
        let toY = fromY + 1
        
        let anchorPoint = CGPoint(x: 0, y: 0)
        
        let viewOffset = UIOffset.init(horizontal: -snapshot.bounds.size.width / 2 + anchorPoint.x, vertical: -snapshot.bounds.size.height / 2 )
        let attachmentBehaviour = UIAttachmentBehavior(item: snapshot, offsetFromCenter: viewOffset, attachedToAnchor: anchorPoint)
        animator!.addBehavior(attachmentBehaviour)

        
        let collisionBehaviour = UICollisionBehavior()
        collisionBehaviour.addBoundary(withIdentifier: "collide" as NSCopying, from: CGPoint(x: fromX, y: fromY), to: CGPoint(x: toX, y: toY))
        collisionBehaviour.addItem(snapshot)
        animator!.addBehavior(collisionBehaviour)
        
        let itemBehaviour = UIDynamicItemBehavior(items: [snapshot])
        itemBehaviour.elasticity = 0.55
        itemBehaviour.density = 1.7
        animator!.addBehavior(itemBehaviour)
        
        let fallBehaviour = UIPushBehavior(items:[snapshot], mode: .continuous)
        fallBehaviour.pushDirection = rotationDirection
        animator!.addBehavior(fallBehaviour)

    }
    
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        let toController = context.viewController(forKey: UITransitionContextViewControllerKey.to)! as! MenuViewController
        context.containerView.addSubview(toController.view)
        self.snapshot?.removeFromSuperview()
        context.completeTransition(true)
    }

    
    fileprivate func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees / 180.0 * CGFloat(Double.pi)
    }
    
    fileprivate func radiansToDegrees(_ radians: CGFloat) -> CGFloat {
        return radians * 180.0 / CGFloat(Double.pi)
    }
}
