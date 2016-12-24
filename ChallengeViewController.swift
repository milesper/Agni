//
//  ChallengeViewController.swift
//  Agni
//
//  Created by Michael Ginn on 11/8/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit

class ChallengeViewController: MenuItemViewController {
    var defaults = UserDefaults.standard //use to get app-wide data
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if defaults.string(forKey: "loggedInUsername") == nil{
            self.performSegue(withIdentifier: "showRegister", sender: self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
