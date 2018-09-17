//
//  LossViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/30/17.
//  Copyright © 2017 Michael Ginn. All rights reserved.
//

import UIKit

class LossViewController: UIViewController {
    
    @IBOutlet weak var lossLabel: UILabel!
    @IBOutlet weak var exclamationLabel: UILabel! //contains only the word "Eheu!" ("Oh dear!")
    @IBOutlet weak var sheepImageView: UIImageView!
    @IBOutlet weak var correctWordLabel: UILabel!
    var word = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.lossLabel.text = "You have lost.  The correct word was "
        self.correctWordLabel.text = word
        sheepImageView.image = Converter.getCurrentSkinImage()!
        sheepImageView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
    }
    
    @IBAction func resumePlay(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

}
