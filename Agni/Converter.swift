//
//  Converter.swift
//  Agni
//
//  Created by Michael Ginn on 6/5/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class Converter: NSObject {
    //utility methods for interacting with files
    
    class func getCurrentWordsArray()->[String]{
        let defaults = UserDefaults.standard //use to get app-wide data
        defaults.set(false, forKey: "customListUsed")
        
        var fullList:[String] = [] //will concatenate all the other lists into this.
        //get lists from CoreData
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList") //get the list of lists
        let selectedTitles = defaults.value(forKey: "selectedTitles") as! [String]
        
        let predicate = NSPredicate(format: "title IN %@", selectedTitles)
        fetchRequest.predicate = predicate
        do {
            let results = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            for list in results{
                let currentList = NSKeyedUnarchiver.unarchiveObject(with: list.value(forKey: "words") as! Data) as! [String]
                if list.value(forKey: "author") as! String != "Agni Dev"{
                    defaults.set(true, forKey: "customListUsed")
                }
                fullList += currentList
            }
        } catch let error1 as NSError {
            NSLog("%@", error1)
            
        }
        
        if selectedTitles.contains("Latin Starter Pack"){
            let path = Bundle.main.path(forResource: "Latin1", ofType: "txt")
            let content = (try! NSString(contentsOfFile: path!, encoding:String.Encoding.utf8.rawValue)) as String
            fullList += content.components(separatedBy: ", ")
        }
        if selectedTitles.contains("English Starter Pack"){
            let path = Bundle.main.path(forResource: "EnglishStarterPack", ofType: "txt")
            let content = (try! NSString(contentsOfFile: path!, encoding:String.Encoding.utf8.rawValue)) as String
            fullList += content.components(separatedBy: ", ")
        }
        
        return fullList
    }
    
    class func saveListToCoreData(listData:Data, listTitle: String, listAuthor: String){
        //convert textfile to core data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let entity =  NSEntityDescription.entity(forEntityName: "WordList", in:managedContext)
        let listObject = NSManagedObject(entity: entity!, insertInto:managedContext)
        
        let dataString = NSString(data: listData, encoding: String.Encoding.utf8.rawValue) //data from textfile
        let words:[String] = (dataString?.components(separatedBy: ", "))!
        let data = NSKeyedArchiver.archivedData(withRootObject: words) //turn it into CoreData data
        
        listObject.setValue(data, forKey: "words")
        listObject.setValue(listTitle, forKey: "title")
        listObject.setValue(listAuthor, forKey: "author")
        
        do {
            try managedContext.save()
            NSLog("Saved \(listTitle)")
        } catch let error1 as NSError {
            NSLog("%@", error1)
        }
    }
    
    class func saveListToCoreData(listItems:[String], listTitle:String, listAuthor:String){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let entity =  NSEntityDescription.entity(forEntityName: "WordList", in:managedContext)
        let listObject = NSManagedObject(entity: entity!, insertInto:managedContext)
        
        let data = NSKeyedArchiver.archivedData(withRootObject: listItems) //turn it into CoreData data
        
        listObject.setValue(data, forKey: "words")
        listObject.setValue(listTitle, forKey: "title")
        listObject.setValue(listAuthor, forKey: "author")
        
        do {
            try managedContext.save()
            NSLog("Saved \(listTitle)")
        } catch let error1 as NSError {
            NSLog("%@", error1)
        }
        
    }
    
    class func saveListToCoreData(_ components:[String]){
        //For custom list
        print("saving \(components[0])")
        
        if components.count != 3{
            print("Something went wrong with custom word list")
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let entity =  NSEntityDescription.entity(forEntityName: "WordList", in:managedContext)
        let listObject = NSManagedObject(entity: entity!, insertInto:managedContext)
        
        let words = components[2].components(separatedBy: ", ")
        let data = NSKeyedArchiver.archivedData(withRootObject: words) //turn it into CoreData data
        
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
    
    
    class func saveSkinToCoreData(_ skindata: Data, name:String, type:String, date:Date, version:Int, largeImageData:Data){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let entity =  NSEntityDescription.entity(forEntityName: "Skin", in:managedContext)
        
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Skin")
        fetchRequest.predicate = NSPredicate(format: "name==%@", name) //find older versions of the skin
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
        } catch _{
            NSLog("Something went wrong getting skins")
        }
        
        let downloadedSkin:NSManagedObject
        if fetchedResults?.count != 0{
            downloadedSkin = (fetchedResults?.first)!
        } else{
            downloadedSkin = NSManagedObject(entity: entity!, insertInto: managedContext)
        }
        downloadedSkin.setValue(skindata, forKey: "file")
        downloadedSkin.setValue(name, forKey: "name")
        downloadedSkin.setValue(type, forKey: "type")
        downloadedSkin.setValue(date, forKey: "date")
        downloadedSkin.setValue(version, forKey: "version")
        downloadedSkin.setValue(largeImageData, forKey: "largefile")
        
        do {
            try managedContext.save()
        } catch let error1 as NSError {
            NSLog("%@", error1)
        }
        
    }
    
    class func getCurrentSkinImage()->UIImage?{
        let defaults = UserDefaults.standard //get app-wide data
        var skinImage:UIImage?
        if defaults.string(forKey: "currentSkin")! == "Default"{
            skinImage = UIImage(named: "Sheep")
        }else{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Skin") //get the list of skins
            let predicate = NSPredicate(format: "name == %@", defaults.string(forKey: "currentSkin")!)
            fetchRequest.predicate = predicate
            
            do {
                let results = try managedContext.fetch(fetchRequest)
                let firstSkin = results[0] as! NSManagedObject
                skinImage = UIImage(data: firstSkin.value(forKey: "file") as! Data)
            } catch let error1 as NSError {
                NSLog("%@", error1)
            }
        }
        return skinImage
    }
}
