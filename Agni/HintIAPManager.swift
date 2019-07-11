//
//  HintIAPManager.swift
//  Agni
//
//  Created by Michael Ginn on 8/27/18.
//  Copyright © 2018 Michael Ginn. All rights reserved.
//

import UIKit
import StoreKit

protocol HintIAPManagerDelegate{
    func paymentBegun()
    func paymentEnded(successful:Bool)
}

class HintIAPManager: NSObject, SKPaymentTransactionObserver {
    class var hintsRemaining:Int {
        get{
            return UserDefaults.standard.integer(forKey: "hints_remaining")
        }
        set(hints){
            UserDefaults.standard.set(hints, forKey: "hints_remaining")
        }
    }
    
    var transactionInProgress = false
    var delegate:HintIAPManagerDelegate?
    
    func buy(){
        SKPaymentQueue.default().add(self)
        
        let payment = SKMutablePayment()
        payment.productIdentifier = "morehints_50"
        SKPaymentQueue.default().add(payment)
        transactionInProgress = true
        if delegate != nil{
            delegate?.paymentBegun()
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions{
            switch transaction.transactionState{
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                HintIAPManager.addHints(50)
                if delegate != nil {delegate?.paymentEnded(successful: true)}
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                if delegate != nil {delegate?.paymentEnded(successful: false)}
            default:
                print(transaction.transactionState.rawValue)
                if delegate != nil {delegate?.paymentEnded(successful: false)}
            }
            transactionInProgress = false
        }
    }
    
    class func addHints(_ number:Int){
        self.hintsRemaining += number
    }
    
    class func addHints(_ number:Int, withDisplay:Bool){
        addHints(number)
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.messageController.addMessage("You got \(number) hints!")
    }
}
