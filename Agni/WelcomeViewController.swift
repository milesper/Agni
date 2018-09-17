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
    @IBOutlet weak var latinButton: UIButton!
    @IBOutlet weak var englishButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        defaults.set("English Starter Pack", forKey: "selectedTitle")
        defaults.set(Constants.CURRENT_VERSION, forKey: "lastVersionShown")
    }
    
    @IBAction func latin(_ sender: UIButton) {
        defaults.set("Latin Starter Pack", forKey: "selectedTitle")
        latinButton.backgroundColor = UIColor(red: 75/255.0, green: 127/255.0, blue: 132/255.0, alpha: 0.65)
        englishButton.backgroundColor = UIColor(white: 0.83, alpha: 1.0)
    }
    
    @IBAction func english(_ sender: UIButton) {
        defaults.set("English Starter Pack", forKey: "selectedTitle")
        englishButton.backgroundColor = UIColor(red: 75/255.0, green: 127/255.0, blue: 132/255.0, alpha: 0.65)
        latinButton.backgroundColor = UIColor(white: 0.83, alpha: 1.0)
    }
    
    @IBAction func playWithTutorial(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func skipTutorial(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
