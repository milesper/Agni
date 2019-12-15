//
//  DownloadManager.swift
//  Agni
//
//  Created by Michael Ginn on 8/29/18.
//  Copyright © 2018 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData
import Firebase

// TODO: Make singleton

class DownloadManager: NSObject {
    var firestore: Firestore? = nil
    var firebaseStorage: Storage? = nil
    
    var downloadedSkins:[String:Int] = ["Default":1]
    var ongoingDownloads = 0
    let defaults = UserDefaults.standard //used to save app-wide data
    let scale = UIScreen.main.scale
    
    //MARK: Get lists
    func getNewWords(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList")
        var downloadedTitles:[String] = ["English Starter Pack", "Latin Starter Pack"]
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
        } catch _{
            print("Something went wrong")
        }
        
        if (fetchedResults != nil){
            for list in fetchedResults!{
                downloadedTitles.append(list.value(forKey: "title") as! String)
            }
        }
        print("Word lists already downloaded: %@", downloadedTitles)
        

        //download lists via Firebase? hopefully
        if let store = firestore{
            store.collection("wordlists").getDocuments { (querySnapshot, err) in
                if let err = err{
                    print("Error getting documents: \(err)")
                }else{
                    for document in querySnapshot!.documents {
                        if !(downloadedTitles.contains(document.get("name") as! String)){
                            self.saveRecord(document)
                        }
                    }
                }
            }
        }
    }
    
    func saveRecord(_ record:QueryDocumentSnapshot){
        if let wordsString:String = record.get("words") as? String {
            let title = record.get("name") as? String ?? ""
            print("Downloading raw words from \(title)")
            let author = record.get("author") as? String ?? ""
            let words = wordsString.components(separatedBy: ", ")
            if let meaningsString:String = record.get("meanings") as? String{
                let meanings = meaningsString.components(separatedBy: ", ")
                Converter.saveListToCoreData(listItems: words, listItemMeanings: meanings, listTitle: title, listAuthor: author)
            }else{
                Converter.saveListToCoreData(listItems: words, listTitle: title, listAuthor: author)
            }
        }
    }
    
    func deleteAllWords(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "WordList")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
            print("Words deleted")
        } catch let error as NSError {
            print("Couldn't delete words, \(error.description)")
        }
        
        defaults.setValue("English Starter Pack", forKey: "selectedTitle")
    }
    
    //MARK: - Skins code
    func getNewSkins(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Skin")
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
        } catch _{
            print("Something went wrong getting skins from data")
        }
        
        print("Skins already downloaded: ")
        if (fetchedResults != nil){
            for skin in fetchedResults!{
                downloadedSkins[skin.value(forKey: "name") as! String] = skin.value(forKey: "version") as? Int
                
                var version: Int
                if skin.value(forKey: "version") == nil{
                    version = -1
                } else {
                    version = skin.value(forKey: "version") as! Int
                }
                let name = skin.value(forKey: "name") as! String
                print("\(name) , v\(version)")
            }
        }
        
        //Download using firebase
        if let store = firestore{
            store.collection("skins").getDocuments { (querySnapshot, err) in
                if let err = err{
                    print("Error getting documents: \(err)")
                }else{
                    for document in querySnapshot!.documents {
                        self.beginSkinDownload(document)
                    }
                }
            }
        }
    }
    
    
    func beginSkinDownload(_ download:QueryDocumentSnapshot){
        let downloadName = download.get("name") as! String
        if !(downloadedSkins.keys.contains(downloadName) && downloadedSkins[downloadName]! == (download.get("version") as? Int)){

            guard let filename = download.get("filename") as? String
                else{return}
            let storageRef = firebaseStorage?.reference()
            let imageRef = storageRef?.child("skins/\(filename)")

            ongoingDownloads += 1
            imageRef?.getData(maxSize: 4 * 1024 * 1024, completion: { (data, error) in
                if let error = error{
                    print(error.localizedDescription)
                }else{
                    self.downloadSkin(largedata: data!, download: download)
                    self.ongoingDownloads -= 1
                    if self.ongoingDownloads == 0{
                        let nc = NotificationCenter()
                        nc.post(Notification(name: Notification.Name("skins-refreshed")))
                    }
                }
            })
        }
    }
    
    private func downloadSkin(largedata:Data, download:QueryDocumentSnapshot){
        guard let image = UIImage(data: largedata) else{return}
        let downloadName = download.get("name") as! String
        
        let scaledImage:UIImage?
        if downloadName == "huge"{
            scaledImage = image.resizeToWidth(width: 424.0, scale: scale)
        }else{
            scaledImage = image.resizeToWidth(width: 212.0, scale: scale)
        }
        
        let skinData = scaledImage!.pngData()
        
        if download.get("forlist") == nil{
            
            Converter.saveSkinToCoreData(skinData!, name: downloadName, date: (download.get("dateCreated") as! Timestamp).dateValue(), version: download.get("version") as! Int, largeImageData: largedata)
        }else{
            Converter.saveSkinToCoreData(skinData!, name: downloadName, date: (download.get("dateCreated") as! Timestamp).dateValue(), version: download.get("version") as! Int, largeImageData: largedata, forList: (download.get("forlist") as! String))
        }
    }
    
    func deleteAllSkins(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Skin")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try managedContext.execute(deleteRequest)
            try managedContext.save()
            print("Skins deleted")
        } catch let error as NSError {
            print("Couldn't delete skins, \(error.description)")
        }
        defaults.set("Default", forKey: "currentSkin")
    }
}
