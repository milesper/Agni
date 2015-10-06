//
//  WhatsNewViewController.swift
//  Agni
//
//  Created by Michael Ginn on 9/5/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit

class WhatsNewViewController: UIViewController {
    @IBOutlet weak var newLabel: UILabel!
    @IBOutlet weak var firstImage: UIImageView!
    @IBOutlet weak var firstDescription: UILabel!
    @IBOutlet weak var secondImage: UIImageView!
    @IBOutlet weak var secondDescription: UILabel!
    @IBOutlet weak var thirdImage: UIImageView!
    @IBOutlet weak var thirdDescription: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    var defaults = NSUserDefaults.standardUserDefaults() //use to get app-wide data
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        for eachView in [firstImage, firstDescription, secondImage, secondDescription, thirdImage, thirdDescription]{
            eachView.alpha = 0.0
        }
    }

    override func viewDidAppear(animated: Bool) {
        UIView.animateWithDuration(0.3, animations: {
            self.firstImage.alpha = 1.0; self.firstDescription.alpha = 1.0
            }, completion: {
                finished in
                UIView.animateWithDuration(0.3, animations: {
                    self.secondImage.alpha = 1.0; self.secondDescription.alpha = 1.0
                }, completion: { (finished) -> Void in
                    UIView.animateWithDuration(0.3, animations: {
                        self.thirdImage.alpha = 1.0; self.thirdDescription.alpha = 1.0
                    })
                })
        })
    }
    
    
    @IBAction func continueButtonPressed(sender: AnyObject) {
        defaults.setValue("1.2.0", forKey: "lastVersionShown")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
