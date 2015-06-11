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
        var defaults = NSUserDefaults.standardUserDefaults() //use to get app-wide data
        
        var fullList:[String] = [] //will concatenate all the other lists into this.
        //get lists from CoreData
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"WordList") //get the list of lists
        var error: NSError?
        let selectedTitles = defaults.valueForKey("selectedTitles") as! [String]
        
        var predicate = NSPredicate(format: "title IN %@", selectedTitles)
        fetchRequest.predicate = predicate
        if let results = managedContext.executeFetchRequest(fetchRequest, error: &error){
            for list in results{
                var currentList = NSKeyedUnarchiver.unarchiveObjectWithData(list.valueForKey("words") as! NSData) as! [String]
                fullList += currentList
            }
        }
        
        if contains(selectedTitles, "Latin Starter Pack"){
            var path = NSBundle.mainBundle().pathForResource("Latin1", ofType: "txt")
            var content = NSString(contentsOfFile: path!, encoding:NSUTF8StringEncoding, error: nil) as! String
            fullList += content.componentsSeparatedByString(", ")
        }
        if contains(selectedTitles, "English Starter Pack"){
            var path = NSBundle.mainBundle().pathForResource("EnglishStarterPack", ofType: "txt")
            var content = NSString(contentsOfFile: path!, encoding:NSUTF8StringEncoding, error: nil) as! String
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
        
        var dataString = NSString(data: data, encoding: NSUTF8StringEncoding) //data from Parse
        var words:[String] = dataString?.componentsSeparatedByString(", ") as! [String]
        var data = NSKeyedArchiver.archivedDataWithRootObject(words) //turn it into CoreData data
        
        listObject.setValue(data, forKey: "words")
        listObject.setValue(listTitle, forKey: "title")
        listObject.setValue(listAuthor, forKey: "author")
        
        var error: NSError?
        managedContext.save(&error)
    }
    
    class func saveSkinInBackground(skin: PFObject, completion: (completed: Bool) -> Void){
        var defaults = NSUserDefaults.standardUserDefaults() //use to get app-wide data
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            let entity =  NSEntityDescription.entityForName("Skin", inManagedObjectContext:managedContext)

            let downloadedSkin = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            if let personFile = skin.objectForKey("Person") as? PFFile{
                var personData = personFile.getData()
                downloadedSkin.setValue(personData, forKey: "personImage")
            } else{
                let personImageData = UIImagePNGRepresentation(UIImage(named: "stickfigure small"))
                downloadedSkin.setValue(personImageData, forKey: "personImage")
            }
            
            if let swordFile = skin.objectForKey("Sword") as? PFFile{
                var swordData = swordFile.getData()
                downloadedSkin.setValue(swordData, forKey: "swordImage")
            } else{
                let swordImageData = UIImagePNGRepresentation(UIImage(named: "sword small"))
                downloadedSkin.setValue(swordImageData, forKey: "swordImage")
            }
            
            if let sheepFile = skin.objectForKey("Sheep") as? PFFile{
                var sheepData = sheepFile.getData()
                downloadedSkin.setValue(sheepData, forKey: "sheepImage")
            } else{
                let sheepImageData = UIImagePNGRepresentation(UIImage(named: "Sheep small"))
                downloadedSkin.setValue(sheepImageData, forKey: "sheepImage")
            }
            let title = skin.valueForKey("Title") as! String
            downloadedSkin.setValue(title, forKey: "title")
            defaults.setObject(title, forKey: "currentSkin")
            defaults.synchronize()
            var error: NSError?
            managedContext.save(&error)
            completion(completed: true)
        })
    }

}
