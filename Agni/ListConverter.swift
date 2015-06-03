//
//  ListConverter.swift
//  
//
//  Created by Michael Ginn on 5/5/15.
//
//

import UIKit
import CoreData
import Parse

class ListConverter: NSObject {
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
}
