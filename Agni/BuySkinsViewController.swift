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
    let productID = "agni_sheep_skins"
    var activityIndicator:UIActivityIndicatorView?
    
    @IBOutlet weak var wrapperView: UIView!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        PFPurchase.addObserverForProduct("agni_sheep_skins") {
            (transaction: SKPaymentTransaction?) -> Void in
            // Will run once this product is purchased.
            NSLog("Purchased")
            self.defaults.setBool(true , forKey: "skinsUnlocked")
            self.navigationController?.popViewControllerAnimated(true)
            self.defaults.synchronize()
        }
        wrapperView.layer.cornerRadius = 5.0
        wrapperView.layer.borderColor = self.view.tintColor.CGColor
        wrapperView.layer.borderWidth = 3.0
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

            } else{
                NSLog("%@", error!.description)
            }
            self.activityIndicator?.stopAnimating()
        }
    }
    @IBAction func restore(sender: UIButton) {
        //show spinning indicator
        self.activityIndicator?.startAnimating()
        
        PFPurchase.restore()
    }
        
    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}