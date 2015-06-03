//
//  FinishedViewController.swift
//  Agni
//
//  Created by Michael Ginn on 5/4/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit

class FinishedViewController: UIViewController {
    //screen to be shown when user loses

    @IBOutlet weak var lossLabel: UILabel!
    @IBOutlet weak var exclamationLabel: UILabel! //contains only the word "Eheu!" ("Oh dear!")
    var word = ""
  
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.lossLabel.text = "You have lost.  The correct word was \(word.lowercaseString)."
        
    }
    
    @IBAction func resumePlay(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
