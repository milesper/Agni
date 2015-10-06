//
//  FinishedViewController.swift
//  Agni
//
//  Created by Michael Ginn on 9/17/15.
//  Copyright © 2015 Michael Ginn. All rights reserved.
//

import UIKit

class FinishedViewController: UIViewController {

    @IBOutlet weak var lossLabel: UILabel!
    @IBOutlet weak var exclamationLabel: UILabel! //contains only the word "Eheu!" ("Oh dear!")
    @IBOutlet weak var sheepImageView: UIImageView!
    var word = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.lossLabel.text = "You have lost.  The correct word was \(word.lowercaseString)."
        
        sheepImageView.image = Converter.getCurrentSkinImage()!
    }
    
    @IBAction func resumePlay(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
