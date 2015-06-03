//
//  WelcomeViewController.swift
//  Agni
//
//  Created by Michael Ginn on 6/1/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    var defaults = NSUserDefaults.standardUserDefaults() //use to get app-wide data

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func latin(sender: AnyObject) {
        defaults.setObject(["Latin Starter Pack"], forKey: "selectedTitles")
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func english(sender: AnyObject) {
        defaults.setObject(["English Starter Pack"], forKey: "selectedTitles")
        self.dismissViewControllerAnimated(true, completion: nil)
    }


}
