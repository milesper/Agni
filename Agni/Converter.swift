//
//  Converter.swift
//  Agni
//
//  Created by Michael Ginn on 6/5/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData
import Parse

class Converter: NSObject {
    //utility methods for interacting with files
    
    class func getWordsArray()->[String]{
        let defaults = NSUserDefaults.standardUserDefaults() //use to get app-wide data
        
        var fullList:[String] = [] //will concatenate all the other lists into this.
        //get lists from CoreData
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"WordList") //get the list of lists
        let selectedTitles = defaults.valueForKey("selectedTitles") as! [String]
        
        let predicate = NSPredicate(format: "title IN %@", selectedTitles)
        fetchRequest.predicate = predicate
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            for list in results{
                let currentList = NSKeyedUnarchiver.unarchiveObjectWithData(list.valueForKey("words") as! NSData) as! [String]
                fullList += currentList
            }
        } catch let error1 as NSError {
            NSLog("%@", error1)
            
        }
        
        if selectedTitles.contains("Latin Starter Pack"){
            let path = NSBundle.mainBundle().pathForResource("Latin1", ofType: "txt")
            let content = (try! NSString(contentsOfFile: path!, encoding:NSUTF8StringEncoding)) as String
            fullList += content.componentsSeparatedByString(", ")
        }
        if selectedTitles.contains("English Starter Pack"){
            let path = NSBundle.mainBundle().pathForResource("EnglishStarterPack", ofType: "txt")
            let content = (try! NSString(contentsOfFile: path!, encoding:NSUTF8StringEncoding)) as String
            fullList += content.componentsSeparatedByString(", ")
        }
        
        return fullList
    }
    
    class func saveToCoreData(data:NSData, listTitle: String, listAuthor: String){
        //convert Parse textfile to core data
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let entity =  NSEntityDescription.entityForName("WordList", inManagedObjectContext:managedContext)
        let listObject = NSManagedObject(entity: entity!, insertIntoManagedObjectContext:managedContext)
        
        let dataString = NSString(data: data, encoding: NSUTF8StringEncoding) //data from Parse
        let words:[String] = (dataString?.componentsSeparatedByString(", "))!
        let data = NSKeyedArchiver.archivedDataWithRootObject(words) //turn it into CoreData data
        
        listObject.setValue(data, forKey: "words")
        listObject.setValue(listTitle, forKey: "title")
        listObject.setValue(listAuthor, forKey: "author")
        
        do {
            try managedContext.save()
        } catch let error1 as NSError {
            NSLog("%@", error1)
        }
    }
    
    class func saveSkinToCoreData(skindata: NSData, name:String, type:String, date:NSDate){
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let entity =  NSEntityDescription.entityForName("Skin", inManagedObjectContext:managedContext)
        let downloadedSkin = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        
        downloadedSkin.setValue(skindata, forKey: "file")
        downloadedSkin.setValue(name, forKey: "name")
        downloadedSkin.setValue(type, forKey: "type")
        downloadedSkin.setValue(date, forKey: "date")
        
        do {
            try managedContext.save()
        } catch let error1 as NSError {
            NSLog("%@", error1)
        }
        
    }
    
    class func getCurrentSkinImage()->UIImage?{
        let defaults = NSUserDefaults.standardUserDefaults() //get app-wide data
        var skinImage:UIImage?
        if defaults.stringForKey("currentSkin")! == "Default"{
            skinImage = UIImage(named: "Sheep small.png")
        }else{
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let fetchRequest = NSFetchRequest(entityName:"Skin") //get the list of skins
            let predicate = NSPredicate(format: "name == %@", defaults.stringForKey("currentSkin")!)
            fetchRequest.predicate = predicate
            
            do {
                let results = try managedContext.executeFetchRequest(fetchRequest)
                let firstSkin = results[0] as! NSManagedObject
                skinImage = UIImage(data: firstSkin.valueForKey("file") as! NSData)
            } catch let error1 as NSError {
                NSLog("%@", error1)
            }
        }
        return skinImage
    }
}
