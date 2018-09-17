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
    var defaults = UserDefaults.standard
    var hintsRemaining:Int {
        get{
            return defaults.integer(forKey: "hints_remaining")
        }
        set(hints){
            defaults.set(hints, forKey: "hints_remaining")
        }
    }
    
    var transactionInProgress = false
    var delegate:HintIAPManagerDelegate?
    
    func buy(){
        SKPaymentQueue.default().add(self)
        
        let payment = SKMutablePayment()
        payment.productIdentifier = "agni_hints_50"
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
                if delegate != nil {delegate?.paymentEnded(successful: true)}
                addHints()
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
    
    private func addHints(){
        self.hintsRemaining += 50
    }
}
