//
//  Converter.swift
//  Agni
//
//  Created by Michael Ginn on 6/5/15.
//  Copyright (c) 2017 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class Converter: NSObject {
    //utility methods for interacting with files
    
    class func getCurrentWordsArray()->(words: [String], meanings: [String?]){
        // TODO: this shouldn't be a default probably idk
        AgniDefaults.customListUsed = false
        
        var finalList:[String] = [] //Should contain just the unguessed words of the list
        var meaningsList:[String?] = [] //For lists which have meanings
        
        if AgniDefaults.selectedTitle == Constants.LATIN_STARTER_PACK{
            //Get data out of textfile
            var latinSPOriginalWords:[String] = [] //Contains all the words
            var latinSPOriginalMeanings:[String] = []
            
            let path = Bundle.main.path(forResource: "Latin1", ofType: "txt")
            let content = (try! NSString(contentsOfFile: path!, encoding:String.Encoding.utf8.rawValue)) as String
            latinSPOriginalWords += content.components(separatedBy: ", ")
            
            let meaningPath = Bundle.main.path(forResource: "Latin1Meanings", ofType: "txt")
            let meaningContent = (try! NSString(contentsOfFile: meaningPath!, encoding: String.Encoding.utf8.rawValue)) as String
            latinSPOriginalMeanings += meaningContent.components(separatedBy: ", ") as [String]
            
            // Now figure out what to return
            if let latinRemaining = AgniDefaults.latinStarterPackRemaining{
                // Figure out which meanings should be added
                if(latinRemaining.count > latinSPOriginalWords.count){
                    // something is very wrong
                    finalList = latinSPOriginalWords
                }else{
                    finalList = latinRemaining
                }
                print("Loaded \(finalList.count) remaining words out of \(latinSPOriginalWords.count)")
                
                for i in 0..<latinSPOriginalWords.count{
                    //For each word, add the meaning if it is still remaining
                    if finalList.contains(latinSPOriginalWords[i]){
                        meaningsList.append(latinSPOriginalMeanings[i])
                    }
                }
            }else{
                //Remaining has not yet been created, so just use all of them
                finalList = latinSPOriginalWords
                meaningsList = latinSPOriginalMeanings
                
                AgniDefaults.latinStarterPackRemaining = finalList
            }
            
        }else if AgniDefaults.selectedTitle == Constants.ENGLISH_STARTER_PACK{
            let path = Bundle.main.path(forResource: "EnglishStarterPack", ofType: "txt")
            let content = (try! NSString(contentsOfFile: path!, encoding:String.Encoding.utf8.rawValue)) as String
            let engList = content.components(separatedBy: ", ")
            
            if let englishRemaining = AgniDefaults.englishStarterPackRemaining{
                if(englishRemaining.count > engList.count){
                    // something is very wrong
                    finalList = engList
                }else{
                    finalList = englishRemaining
                }
                meaningsList += [String?](repeating: nil, count: finalList.count)
                
                print("Loaded \(finalList.count) remaining words out of \(engList.count)")
            }else{
                //Remaining has not yet been created
                finalList = engList
                meaningsList += [String?](repeating: nil, count: engList.count)
                
                AgniDefaults.englishStarterPackRemaining = finalList
            }
        }else{
            //get lists from CoreData
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList") //get the list of lists
            
            let predicate = NSPredicate(format: "title == \"\(AgniDefaults.selectedTitle)\"")
            fetchRequest.predicate = predicate
            do {
                let results = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
                guard let list = results.first else{return ([], [])}
                let fullList = NSKeyedUnarchiver.unarchiveObject(with: list.value(forKey: "words") as! Data) as! [String]
                if list.value(forKey: "author") as! String != "Agni Dev"{
                    AgniDefaults.customListUsed = true
                }
                
                if list.value(forKey: "remaining_words") == nil{
                    let remainingWordsData = NSKeyedArchiver.archivedData(withRootObject: fullList)
                    list.setValue(remainingWordsData, forKey: "remaining_words")
                    do {
                        try managedContext.save()
                        print("Saved remaining words")
                    } catch let error1 as NSError {
                        print("%@", error1)
                    }
                    finalList = fullList
                }else{
                    //Load these as the list
                    let remainingList = NSKeyedUnarchiver.unarchiveObject(with: list.value(forKey: "remaining_words") as! Data) as! [String]
                    finalList = remainingList
                    
                    print("Loaded \(finalList.count) remaining words out of \(fullList.count)")
                }
                
                //Add meanings
                if list.value(forKey: "has_study_mode") as! Bool{
                    let meanings = NSKeyedUnarchiver.unarchiveObject(with: list.value(forKey: "word_meanings") as! Data) as! [String?]
                    for i in 0..<fullList.count{
                        if finalList.contains(fullList[i]){
                            meaningsList.append(meanings[i])
                        }
                    }
                }else{
                    meaningsList += [String?](repeating: nil, count: finalList.count)
                }
                
            } catch let error1 as NSError {
                print("%@", error1)
                
            }

        }

        return (finalList, meaningsList)
    }
    
    class func saveListToCoreData(listData:Data, listMeaningData:Data?=nil, listTitle: String, listAuthor: String){
        //Used to download from webserver
        DispatchQueue.main.async { //Otherwise we're saving on a bg thread, NO GOOD
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            let entity =  NSEntityDescription.entity(forEntityName: "WordList", in:managedContext)
            let listObject = NSManagedObject(entity: entity!, insertInto:managedContext)
            
            let dataString = NSString(data: listData, encoding: String.Encoding.utf8.rawValue) //data from textfile
            let words:[String] = (dataString?.components(separatedBy: ", "))!
            let data = NSKeyedArchiver.archivedData(withRootObject: words) //turn it into CoreData data
            
            listObject.setValue(data, forKey: "words")
            listObject.setValue(data, forKey: "remaining_words")
            listObject.setValue(words.count, forKey: "word_count")
            listObject.setValue(listTitle, forKey: "title")
            listObject.setValue(listAuthor, forKey: "author")
            
            if listMeaningData != nil{
                let meaningDataString = NSString(data: listMeaningData!, encoding: String.Encoding.utf8.rawValue)
                let meanings:[String] = (meaningDataString?.components(separatedBy: ", "))!
                let meaningData = NSKeyedArchiver.archivedData(withRootObject: meanings)
                listObject.setValue(meaningData, forKey: "word_meanings")
                listObject.setValue(true, forKey: "has_study_mode")
            }else{
                listObject.setValue(false, forKey: "has_study_mode")
            }
            
            do {
                try managedContext.save()
                print("Saved \(listTitle)")
            } catch let error1 as NSError {
                print("%@", error1)
            }
        }
    }
    
    class func saveListToCoreData(listItems:[String], listItemMeanings:[String]?=nil, listTitle:String, listAuthor:String){
        //Used when creating a custom word list
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let entity =  NSEntityDescription.entity(forEntityName: "WordList", in:managedContext)
        let listObject = NSManagedObject(entity: entity!, insertInto:managedContext)
        
        let data = NSKeyedArchiver.archivedData(withRootObject: listItems) //turn it into CoreData data
        
        listObject.setValue(data, forKey: "words")
        listObject.setValue(data, forKey: "remaining_words")
        listObject.setValue(listItems.count, forKey: "word_count")
        listObject.setValue(listTitle, forKey: "title")
        listObject.setValue(listAuthor, forKey: "author")
        if listItemMeanings != nil {
            let meaningData = NSKeyedArchiver.archivedData(withRootObject: listItemMeanings!)
            listObject.setValue(meaningData, forKey: "word_meanings")
            listObject.setValue(true, forKey: "has_study_mode")
        }else{
            listObject.setValue(false, forKey: "has_study_mode")
        }
        
        
        do {
            try managedContext.save()
            print("Saved \(listTitle)")
        } catch let error1 as NSError {
            print("%@", error1)
        }
        
    }
    
    /**
     Saves a list to core data. Should be used for a custom list that was imported by sharing.
     
        - Parameters:
            - components: An array of 3 or 4 objects: Title, Author, Words, and Meanings
     
     */
    class func saveListToCoreData(_ components:[String]){
        //For custom list imported by sharing
        //Should have 3 or 4 comps: title, author, words, [meanings]
        print("saving \(components[0])")
        
        if components.count != 3 && components.count != 4{
            print("Something went wrong with custom word list")
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let entity =  NSEntityDescription.entity(forEntityName: "WordList", in:managedContext)
        let listObject = NSManagedObject(entity: entity!, insertInto:managedContext)
        
        let words = components[2].components(separatedBy: ", ")
        let data = NSKeyedArchiver.archivedData(withRootObject: words) //turn it into CoreData data
        
        listObject.setValue(components[0], forKey: "title")
        listObject.setValue(components[1], forKey: "author")
        listObject.setValue(data, forKey: "words")
        listObject.setValue(data, forKey: "remaining_words")
        listObject.setValue(words.count, forKey: "word_count")
        
        if components.count == 4{  //Study mode on
            let wordMeanings = components[3].components(separatedBy: ", ")
            let meaningData = NSKeyedArchiver.archivedData(withRootObject: wordMeanings) //turn it into CoreData data
            listObject.setValue(meaningData, forKey: "word_meanings")
            listObject.setValue(true, forKey: "has_study_mode")
        }
        
        do {
            try managedContext.save()
            print("Saved \(components[0])")
        } catch let error1 as NSError {
            print("%@", error1)
        }
        
    }
    
    /**
     Saves a skin to core data
     
     - Parameters:
        - skindata: Serialized data of the image for the skin, at the size it will be displayed
        - name: The name of the skin, never displayed
        - date: Creation date of the skin, not sure why I have this
        - version: Integer representing which version of the skin this is
        - largeImageData: Serialized data of a larger version of the skin, used in the carousel picker
        - forList: (Optional) For skins which are rewards for a list, otherwise leave blank
     */
    class func saveSkinToCoreData(_ skindata: Data, name:String, date:Date, version:Int, largeImageData:Data, forList:String?=nil){
        DispatchQueue.main.async {
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            let entity =  NSEntityDescription.entity(forEntityName: "Skin", in:managedContext)
            
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Skin")
            fetchRequest.predicate = NSPredicate(format: "name==%@", name) //find older versions of the skin
            
            var fetchedResults:[NSManagedObject]? = nil
            do{
                fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
            } catch _{
                print("Something went wrong getting skins")
            }
            
            let downloadedSkin:NSManagedObject
            if fetchedResults?.count != 0{
                downloadedSkin = (fetchedResults?.first)!
            } else{
                downloadedSkin = NSManagedObject(entity: entity!, insertInto: managedContext)
            }
            downloadedSkin.setValue(skindata, forKey: "file")
            downloadedSkin.setValue(name, forKey: "name")
            downloadedSkin.setValue(date, forKey: "date")
            downloadedSkin.setValue(version, forKey: "version")
            downloadedSkin.setValue(largeImageData, forKey: "largefile")
            
            if forList == nil{
                // the skin has no req, so it is unlocked
                downloadedSkin.setValue("", forKey: "forList")
                downloadedSkin.setValue(true, forKey: "unlocked")
                
            }else if AgniDefaults.beatenWordLists.contains(forList!){
                // we have beaten the list to unlock the skin
                
                downloadedSkin.setValue(forList, forKey: "forList")
                downloadedSkin.setValue(true, forKey: "unlocked")
            }else{
                // it's still locked
                downloadedSkin.setValue(forList, forKey: "forList")
                downloadedSkin.setValue(false, forKey: "unlocked")
            }
            
            do {
                try managedContext.save()
            } catch let error1 as NSError {
                print("%@", error1)
            }
        }
    }
    
    class func getCurrentSkinImage()->UIImage?{
        var skinImage:UIImage?
        if AgniDefaults.currentSkin == Constants.DEFAULT_SKIN_NAME{
            skinImage = UIImage(named: "Sheep")
        }else{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Skin") //get the list of skins
            let predicate = NSPredicate(format: "name == \"\(AgniDefaults.currentSkin)\"")
            print(AgniDefaults.currentSkin)
            fetchRequest.predicate = predicate
            
            do {
                let results = try managedContext.fetch(fetchRequest)
                if results.count == 0{
                    // the skin disappeared somehow
                    print("Could not find skin \(AgniDefaults.currentSkin)")
                    AgniDefaults.currentSkin = "Default"
                    return UIImage(named: "Sheep")
                }
                let firstSkin = results[0] as! NSManagedObject
                skinImage = UIImage(data: firstSkin.value(forKey: "file") as! Data)
            } catch let error1 as NSError {
                print("%@", error1)
                return UIImage(named: "Sheep")
            }
        }
        return skinImage
    }
}
