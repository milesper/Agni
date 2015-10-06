 //
//  AppDelegate.swift
//  Agni
//
//  Created by Michael Ginn on 5/2/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData
import Parse
import Bolts

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Parse.setApplicationId("exQOpxOX7X8V8njPBHInr0zaexL9mQxzcZvkdNBT",
            clientKey: "xWF9BAovkiwsJMaSrhJ5SpC3UgxHCBe7ER2PPTnM") //connect to online database
        
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
        defaults.synchronize()
        
        
        // Register for Push Notitications, if running iOS 8
        if application.respondsToSelector("registerUserNotificationSettings:") {
            
            if #available(iOS 8.0, *) {
                let types:UIUserNotificationType = ([.Alert, .Badge, .Sound])
                let settings:UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
                application.registerUserNotificationSettings(settings)
                application.registerForRemoteNotifications()
            } else {
                // Fallback on earlier versions
            }
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
        
        
        return true
    }
    
    func getNewWords(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"WordList")
        var downloadedTitles:[String] = []
        
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
        //Let's download some word lists!
        let query = PFQuery(className: "WordList")
        query.whereKey("Title", notContainedIn: downloadedTitles)
        query.findObjectsInBackgroundWithBlock({
            (data,error) in
            let downloads = data as! [PFObject]
            for download in downloads{
                let textfile = download.objectForKey("Textfile") as! PFFile
                textfile.getDataInBackgroundWithBlock({
                    (data,error) in
                    if error == nil{
                        Converter.saveToCoreData(data!, listTitle: download.valueForKey("Title") as! String, listAuthor: download.valueForKey("Author") as! String)
                    }
                })
            }
        })
    }
    
    func getNewSkins(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"Skin")
        var downloadedNames:[String] = []
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
        } catch _{
            NSLog("Something went wrong getting skins")
        }
        if (fetchedResults != nil){
            for list in fetchedResults!{
                downloadedNames.append(list.valueForKey("name") as! String)
            }
        }
        NSLog("Skins already downloaded: %@", downloadedNames)
        //Let's download some skins!
        let query = PFQuery(className: "Skin")
        query.whereKey("Name", notContainedIn: downloadedNames)
        query.findObjectsInBackgroundWithBlock({
            (data,error) in
            let downloads = data as! [PFObject]
            for download in downloads{
                let imagefile = download.objectForKey("File") as! PFFile
                imagefile.getDataInBackgroundWithBlock({
                    (data,error) in
                    if error == nil{
                        Converter.saveSkinToCoreData(data!, name: download.valueForKey("Name") as! String, type: download.valueForKey("Type") as! String, date: download.valueForKey("createdAt") as! NSDate)
                    }
                })
            }
        })
    }
    
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackground()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
        if application.applicationState == UIApplicationState.Inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayload(userInfo)
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

