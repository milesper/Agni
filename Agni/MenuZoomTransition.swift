//
//  MenuZoomTransition.swift
//  Agni
//
//  Created by Michael Ginn on 7/14/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit

class MenuZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {
    var originView:MenuItemView?
    init(view:MenuItemView){
        originView = view
    }
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)! as! AgniViewController
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)! as! MenuViewController
        let finalFrameForVC = transitionContext.finalFrameForViewController(toViewController)
        let containerView = transitionContext.containerView()
        let bounds = UIScreen.mainScreen().bounds
        
        guard let menuItemView = originView else{return}
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
            menuItemView.frame = finalFrameForVC
            }, completion: {
                finished in
                transitionContext.completeTransition(true)
        })
    }
}
