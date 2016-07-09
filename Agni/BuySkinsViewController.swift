//
//  BuySkinsViewController.swift
//  Agni
//
//  Created by Michael Ginn on 6/1/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//  

import UIKit
import StoreKit


class BuySkinsViewController: UIViewController, SKPaymentTransactionObserver  {
    var defaults = NSUserDefaults.standardUserDefaults()
    let productID = "agni_sheep_skins"
    
    var activityIndicator:UIActivityIndicatorView?
    @IBOutlet weak var wrapperView: UIVisualEffectView!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    
    var transactionInProgress = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        
//        PFPurchase.addObserverForProduct("agni_sheep_skins") {
//            (transaction: SKPaymentTransaction?) -> Void in
//            // Will run once this product is purchased.
//            NSLog("Purchased")
//            self.defaults.setBool(true , forKey: "skinsUnlocked")
//            self.dismissViewControllerAnimated(true, completion: nil)
//            self.defaults.synchronize()
//        }
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
        
        let payment = SKMutablePayment()
        payment.productIdentifier = productID
        SKPaymentQueue.defaultQueue().addPayment(payment)
        transactionInProgress = true
    }
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions{
            switch transaction.transactionState{
            case .Purchased:
                print("Purchased successfully")
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                transactionInProgress = false
                self.activityIndicator?.stopAnimating()
                upgradeBought()
            case .Failed:
                print("Transaction failed")
                SKPaymentQueue.defaultQueue().finishTransaction(transaction)
                transactionInProgress = false
                self.activityIndicator?.stopAnimating()
            default:
                print(transaction.transactionState.rawValue)
                self.activityIndicator?.stopAnimating()
            }
        }
    }
    
    func upgradeBought(){
        self.defaults.setBool(true , forKey: "skinsUnlocked")
        self.defaults.synchronize()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func restore(sender: UIButton) {
        //show spinning indicator
        self.activityIndicator?.startAnimating()
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
        
    @IBAction func dismiss(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}