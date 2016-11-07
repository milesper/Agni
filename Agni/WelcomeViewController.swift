//
//  WelcomeViewController.swift
//  Agni
//
//  Created by Michael Ginn on 6/1/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    var defaults = UserDefaults.standard //use to get app-wide data
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func latin(_ sender: AnyObject) {
        defaults.set(["Latin Starter Pack"], forKey: "selectedTitles")
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func english(_ sender: AnyObject) {
        defaults.set(["English Starter Pack"], forKey: "selectedTitles")
        self.dismiss(animated: true, completion: nil)
    }
    
    
}
