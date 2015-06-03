//
//  BuySkinsViewController.swift
//  Agni
//
//  Created by Michael Ginn on 6/1/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//  

import UIKit
import StoreKit
import Parse

class BuySkinsViewController: UIViewController  {
    var defaults = NSUserDefaults.standardUserDefaults()
    var activityIndicator:UIActivityIndicatorView?
    let productID = "agni_sheep_skins"
    @IBOutlet weak var buyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        PFPurchase.addObserverForProduct("agni_sheep_skins") {
            (transaction: SKPaymentTransaction?) -> Void in
            // Will run once this product is purchased.
            self.defaults.setBool(true , forKey: "skinsUnlocked")
            self.navigationController?.popViewControllerAnimated(true)
            self.defaults.synchronize()
        }
    }

    override func viewDidAppear(animated: Bool) {
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        self.activityIndicator?.frame = self.buyButton.frame
        self.activityIndicator?.backgroundColor = UIColor.whiteColor()
        self.buyButton.superview!.insertSubview(activityIndicator!, aboveSubview: buyButton)
    }
    
    @IBAction func buy(sender: UIButton) {
        //show spinning indicator
        self.activityIndicator?.startAnimating()
        
        PFPurchase.buyProduct("agni_sheep_skins") {
            (error: NSError?) -> Void in
            if error == nil {
                self.activityIndicator?.stopAnimating()
            }
        }
    }
        
}