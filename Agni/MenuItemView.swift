//
//  MenuItemView.swift
//  Agni
//
//  Created by Michael Ginn on 7/10/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit

class MenuItemView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1.5
        self.layer.borderColor = self.backgroundColor?.CGColor
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let innerView = self.viewWithTag(1)
        UIView.animateWithDuration(0.2, animations: {
            innerView?.backgroundColor = self.backgroundColor
        })
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let innerView = self.viewWithTag(1)
        UIView.animateWithDuration(0.2, animations: {
            innerView?.backgroundColor = UIColor.whiteColor()
        })
    }
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        let innerView = self.viewWithTag(1)
        UIView.animateWithDuration(0.2, animations: {
            innerView?.backgroundColor = UIColor.whiteColor()
        })
    }
}