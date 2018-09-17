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
    var defaults = UserDefaults.standard
    let productID = "agni_sheep_skins"
    
    var activityIndicator:UIActivityIndicatorView?
    @IBOutlet weak var wrapperView: UIVisualEffectView!
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    
    var transactionInProgress = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        SKPaymentQueue.default().add(self)
        
        wrapperView.layer.cornerRadius = 5.0
        wrapperView.layer.borderColor = self.view.tintColor.cgColor
        wrapperView.layer.borderWidth = 3.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        self.activityIndicator?.frame = self.buyButton.frame
        self.activityIndicator?.backgroundColor = UIColor.white
        self.buyButton.superview!.insertSubview(activityIndicator!, aboveSubview: buyButton)
    }
    
    @IBAction func buy(_ sender: UIButton) {
        //show spinning indicator
        self.activityIndicator?.startAnimating()
        
        let payment = SKMutablePayment()
        payment.productIdentifier = productID
        SKPaymentQueue.default().add(payment)
        transactionInProgress = true
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions{
            switch transaction.transactionState{
            case .purchased:
                print("Purchased successfully")
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                self.activityIndicator?.stopAnimating()
                upgradeBought()
            case .failed:
                print("Transaction failed")
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                self.activityIndicator?.stopAnimating()
            default:
                print(transaction.transactionState.rawValue)
                self.activityIndicator?.stopAnimating()
            }
        }
    }
    
    func upgradeBought(){
        self.defaults.set(true , forKey: "skinsUnlocked")
        self.defaults.synchronize()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func restore(_ sender: UIButton) {
        //show spinning indicator
        self.activityIndicator?.startAnimating()
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    @IBAction func dismiss(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
