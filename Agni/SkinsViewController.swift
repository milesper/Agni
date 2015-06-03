//
//  SkinsViewController.swift
//  Agni
//
//  Created by Michael Ginn on 6/1/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit
import StoreKit

class SkinsViewController: UIViewController {
    var defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }

    override func viewDidAppear(animated: Bool) {
        if !defaults.boolForKey("skinsUnlocked"){
            
            self.performSegueWithIdentifier("purchasePage", sender: self)
        }
    }

}
