//
//  MenuItemViewController.swift
//  Agni
//
//  Created by Michael Ginn on 8/14/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit

class MenuItemViewController: UIViewController {
    var interactor:MenuItemInteractor? = nil
    @IBOutlet var panGesture:UIPanGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        panGesture?.addTarget(self, action: #selector(MenuItemViewController.handlePanGesture(_:)))
    }

    func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        let percentThreshold:CGFloat = 0.3
        
        // convert y-position to downward pull progress (percentage)
        let translation = sender.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        guard let interactor = interactor else { return }
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish
                ? interactor.finish()
                : interactor.cancel()
        default:
            break
        }
    }


}
