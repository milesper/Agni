 //
//  AppDelegate.swift
//  Agni
//
//  Created by Michael Ginn on 5/2/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData
import GameKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var gameCenterAuthenticated:Bool = false
    var leaderboardIdentifier:String = ""
    let scale = UIScreen.mainScreen().scale
    
    var downloadedSkins:[String:Int] = ["Default":1]
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        _ = OneSignal(launchOptions: launchOptions, appId: "b8ba5f66-c4b0-4f03-9f50-d7d40e7dc982", handleNotification: nil)
        
        OneSignal.defaultClient().enableInAppAlertNotification(true)
        
        
        // Override point for customization after application launch.
        self.window!.tintColor = UIColor(red: 114/255.0, green: 191/255.0, blue: 125/255.0, alpha: 1.0) //change tint color
        let defaults = NSUserDefaults.standardUserDefaults() //used to save app-wide data
        if defaults.objectForKey("skinsUnlocked") == nil{ //this will be changed by the selected titles screen
            defaults.setBool(false, forKey: "skinsUnlocked")
        }
        //simulator testing only
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            defaults.setBool(true, forKey: "skinsUnlocked")
        #endif
        
        if defaults.objectForKey("currentSkin") == nil{
            defaults.setValue("Default", forKey: "currentSkin")
        }
        
        defaults.setObject(true, forKey: "needsUpdateSources") //cause the game to refresh its input sources
        
        
        
        // Register for Push Notitications, if running iOS 8
        if application.respondsToSelector(#selector(UIApplication.registerUserNotificationSettings(_:))) {
            let types:UIUserNotificationType = ([.Alert, .Badge, .Sound])
            let settings:UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        
        let networkReachability = Reachability.reachabilityForInternetConnection()
        let networkStatus = networkReachability.currentReachabilityStatus()
        if networkStatus.rawValue == NotReachable.rawValue{
            print("No connection")
        }else{
            print("Connected to the Interwebs!")
            getNewWords()
            getNewSkins()
        }
        
        //gamecenter achievement setup
        func makeNonNil(key:String){
            if defaults.objectForKey(key) == nil{
                defaults.setInteger(0, forKey: key)
            }
        }
        makeNonNil("win_total")
        makeNonNil("win_streak")
        makeNonNil("longest_streak")
        makeNonNil("loss_total")
        makeNonNil("days_played")
        
        if defaults.objectForKey("used_skins") == nil || defaults.arrayForKey("used_skins")!.count == 0{
            defaults.setObject(["Default"], forKey: "used_skins")
        }
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        let comps = calendar?.components([.Year, .Month, .Day], fromDate: NSDate())
        let dateString = "\(comps!.day) \(comps!.month) \(comps!.year)"
        if defaults.stringForKey("last_day_played") != dateString{
            defaults.setObject(dateString, forKey: "last_day_played")
            
            let daysPlayed = defaults.integerForKey("days_played")
            defaults.setInteger(daysPlayed + 1, forKey: "days_played")
        }
        
        defaults.synchronize()
        return true
    }
    
    func getNewWords(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"WordList")
        var downloadedTitles:[String] = ["English Starter Pack"]
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
        } catch _{
            NSLog("Something went wrong")
        }
        
        if (fetchedResults != nil){
            for list in fetchedResults!{
                downloadedTitles.append(list.valueForKey("title") as! String)
            }
        }
        NSLog("Word lists already downloaded: %@", downloadedTitles)
        
        
        //download lists via CloudKit
        let predicate = NSPredicate(format: "NOT (%@ CONTAINS Name)", downloadedTitles)
        let query = CKQuery(recordType: "List", predicate: predicate)
        
        let queryOperation = CKQueryOperation(query: query)
        let operationQueue = NSOperationQueue()
        self.executeListQueryOperation(queryOperation, onOperationQueue: operationQueue)
    }
    
    func executeListQueryOperation(queryOperation: CKQueryOperation, onOperationQueue operationQueue: NSOperationQueue) {
        NSLog("Executing query operation")
        let container = CKContainer(identifier: "iCloud.quaritate.Agni")
        let publicDB = container.publicCloudDatabase
        
        queryOperation.database = publicDB
        
        queryOperation.recordFetchedBlock = {(record:CKRecord) in
            self.saveRecord(record)
        }
        
        queryOperation.queryCompletionBlock = {(cursor:CKQueryCursor?, error:NSError?)->Void in
            if error != nil{
                NSLog("Query error: \(error?.description)")
                return
            }
            if let queryCursor = cursor { //there are more operations to execute
                let queryCursorOperation = CKQueryOperation(cursor: queryCursor)
                self.executeListQueryOperation(queryCursorOperation, onOperationQueue: operationQueue)
            }
        }
        publicDB.addOperation(queryOperation)
    }
    
    func saveRecord(record:CKRecord){
        if record.objectForKey("Words") != nil{
            NSLog("Downloading via array")
            let wordsArray = record.objectForKey("Words") as! [String]
            Converter.saveListToCoreData(listItems: wordsArray, listTitle: record.objectForKey("Name") as! String, listAuthor: record.objectForKey("Author") as! String)
            
        }else if record.objectForKey("WordsTextFile") != nil{
            NSLog("Downloading via text file")
            let textfile = record.objectForKey("WordsTextFile") as! CKAsset
            let data = NSData(contentsOfURL: textfile.fileURL)
            Converter.saveListToCoreData(listData: data!, listTitle: record.objectForKey("Name") as! String, listAuthor: record.objectForKey("Author") as! String)
        }
    }
    
    //MARK - Skins code
    func getNewSkins(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"Skin")
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
        } catch _{
            NSLog("Something went wrong getting skins from data")
        }
        
        NSLog("Skins already downloaded: ")
        if (fetchedResults != nil){
            for skin in fetchedResults!{
                downloadedSkins[skin.valueForKey("name") as! String] = skin.valueForKey("version") as? Int
               
                var version: Int
                if skin.valueForKey("version") == nil{
                    version = -1
                } else {
                    version = skin.valueForKey("version") as! Int
                }
                let name = skin.valueForKey("name") as! String
                print("\(name) , v\(version)")
            }
        }
        
        //Let's download some skins!
        let truePredicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: "Skin", predicate: truePredicate)
        
        
        let queryOperation = CKQueryOperation(query: query)
        let operationQueue = NSOperationQueue()
        self.executeSkinQueryOperation(queryOperation, onOperationQueue: operationQueue)
    }
    
    func executeSkinQueryOperation(queryOperation: CKQueryOperation, onOperationQueue operationQueue: NSOperationQueue) {
        NSLog("Executing skin query operation")
        let container = CKContainer(identifier: "iCloud.quaritate.Agni")
        let publicDB = container.publicCloudDatabase
        
        queryOperation.database = publicDB
        
        queryOperation.recordFetchedBlock = {(record:CKRecord) in
            self.downloadSkin(record)
        }
        
        queryOperation.queryCompletionBlock = {(cursor:CKQueryCursor?, error:NSError?)->Void in
            if error != nil{
                NSLog("Query error: \(error?.description)")
                return
            }
            if let queryCursor = cursor { //there are more operations to execute
                let queryCursorOperation = CKQueryOperation(cursor: queryCursor)
                self.executeSkinQueryOperation(queryCursorOperation, onOperationQueue: operationQueue)
            }
        }
        publicDB.addOperation(queryOperation)
    }

    
    func downloadSkin(download:CKRecord){
        let downloadName = download.objectForKey("Name") as! String
        if !(downloadedSkins.keys.contains(downloadName) && downloadedSkins[downloadName]! == (download.objectForKey("Version") as? Int)){
            
            guard let imageFile = download.objectForKey("File") as? CKAsset
                else{return}
            
            let data = NSData(contentsOfURL: imageFile.fileURL)
            let image = UIImage(data: data!) //large image, used for carousel
            
            //Figure out the scaled size
            let ratio = image!.size.height / image!.size.width
            let size:CGSize
            switch scale{
            case 1.0:
                size = CGSizeMake(212.0, 212.0 * ratio)
            case 2.0:
                size = CGSizeMake(318.0, 318.0 * ratio)
            default:
                size = CGSizeMake(212.0, 212.0 * ratio)
            }
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            image?.drawInRect(CGRect(origin: CGPointZero, size: size))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let skinData = UIImagePNGRepresentation(scaledImage)
            Converter.saveSkinToCoreData(skinData!, name: download.objectForKey("Name") as! String, type: download.objectForKey("Type") as! String, date: download.objectForKey("creationDate") as! NSDate, version: download.objectForKey("Version") as! Int, largeImageData: data!)
        }
    }
    
    func authenticateLocalPlayer(){
        print("Start authentication")
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {
            (viewController, error) in
            if (viewController != nil){
                print("Not logged in")
                self.window?.rootViewController?.presentViewController(viewController!, animated: true, completion: nil)
            } else if localPlayer.authenticated{
                self.gameCenterAuthenticated = true
                localPlayer.loadDefaultLeaderboardIdentifierWithCompletionHandler({(leaderboardId, error) in
                    if error != nil{
                        NSLog("%@", error!.localizedDescription)
                    }else{
                        self.leaderboardIdentifier = leaderboardId!
                        NSLog("\(self.leaderboardIdentifier)")
                    }
                })
            }else{
                if error != nil{
                    NSLog("%@", error!.localizedDescription)
                    self.gameCenterAuthenticated = false
                }
            }
        }
    }
    
    //MARK: Push notifications
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        //NEED to add implementation
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        if let pushInfo = userInfo as? [String: NSObject] {
            let notification = CKNotification(fromRemoteNotificationDictionary: pushInfo)
            
            let ac = UIAlertController(title: "What's that Whistle?", message: notification.alertBody, preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            
            if let nc = window?.rootViewController as? UINavigationController {
                if let vc = nc.visibleViewController {
                    vc.presentViewController(ac, animated: true, completion: nil)
                }
            }
        }
        
    }

    // MARK: - Core Data stack 
    // Used to implement persistant data
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.xxxx.ProjectName" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Store", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        var options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Agni.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        } catch {
            fatalError()
        }
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    // Replace this implementation with code to handle the error appropriately.
                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    NSLog("Unresolved error \(error1), \(error1.userInfo)")
                    abort()
                }
            }
        }
    }


}

