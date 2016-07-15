//
//  CustomListManager.swift
//  Agni
//
//  Created by Michael Ginn on 7/13/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class CustomListManager: NSObject, UIAlertViewDelegate {
    class func saveListToCoreData(components:[String]){
        print("saving \(components[0])")
        
        if components.count != 3{
            print("Somethng went wrong with custom word list")
            return
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let entity =  NSEntityDescription.entityForName("WordList", inManagedObjectContext:managedContext)
        let listObject = NSManagedObject(entity: entity!, insertIntoManagedObjectContext:managedContext)
        
        let words = components[2].componentsSeparatedByString(", ")
        let data = NSKeyedArchiver.archivedDataWithRootObject(words) //turn it into CoreData data
        
        listObject.setValue(data, forKey: "words")
        listObject.setValue(components[0], forKey: "title")
        listObject.setValue(components[1], forKey: "author")
        
        do {
            try managedContext.save()
            NSLog("Saved \(components[0])")
        } catch let error1 as NSError {
            NSLog("%@", error1)
        }

    }
}
