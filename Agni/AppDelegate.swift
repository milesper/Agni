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
    let scale = UIScreen.main.scale
    
    var downloadedSkins:[String:Int] = ["Default":1]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        _ = OneSignal(launchOptions: launchOptions, appId: "b8ba5f66-c4b0-4f03-9f50-d7d40e7dc982", handleNotification: nil)
        
        OneSignal.defaultClient().enable(inAppAlertNotification: true)
        
        
        // Override point for customization after application launch.
        self.window!.tintColor = UIColor(red: 114/255.0, green: 191/255.0, blue: 125/255.0, alpha: 1.0) //change tint color
        let defaults = UserDefaults.standard //used to save app-wide data
        if defaults.object(forKey: "skinsUnlocked") == nil{ //this will be changed by the selected titles screen
            defaults.set(false, forKey: "skinsUnlocked")
        }
        //simulator testing only
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            defaults.set(true, forKey: "skinsUnlocked")
        #endif
        
        if defaults.object(forKey: "currentSkin") == nil{
            defaults.setValue("Default", forKey: "currentSkin")
        }
        
        defaults.set(true, forKey: "needsUpdateSources") //cause the game to refresh its input sources
        
        
        
        // Register for Push Notitications, if running iOS 8
        if application.responds(to: #selector(UIApplication.registerUserNotificationSettings(_:))) {
            let types:UIUserNotificationType = ([.alert, .badge, .sound])
            let settings:UIUserNotificationSettings = UIUserNotificationSettings(types: types, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        
        let networkReachability = Reachability.forInternetConnection()
        let networkStatus = networkReachability?.currentReachabilityStatus()
        if networkStatus?.rawValue == NotReachable.rawValue{
            print("No connection")
        }else{
            print("Connected to the Interwebs!")
            getNewWords()
            getNewSkins()
        }
        
        //gamecenter achievement setup
        func makeNonNil(_ key:String){
            if defaults.object(forKey: key) == nil{
                defaults.set(0, forKey: key)
            }
        }
        makeNonNil("win_total")
        makeNonNil("win_streak")
        makeNonNil("longest_streak")
        makeNonNil("loss_total")
        makeNonNil("days_played")
        
        if defaults.object(forKey: "used_skins") == nil || defaults.array(forKey: "used_skins")!.count == 0{
            defaults.set(["Default"], forKey: "used_skins")
        }
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let comps = (calendar as NSCalendar?)?.components([.year, .month, .day], from: Date())
        let dateString = "\(comps!.day) \(comps!.month) \(comps!.year)"
        if defaults.string(forKey: "last_day_played") != dateString{
            defaults.set(dateString, forKey: "last_day_played")
            
            let daysPlayed = defaults.integer(forKey: "days_played")
            defaults.set(daysPlayed + 1, forKey: "days_played")
        }
        
        defaults.synchronize()
        return true
    }
    
    func getNewWords(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList")
        var downloadedTitles:[String] = ["English Starter Pack"]
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
        } catch _{
            NSLog("Something went wrong")
        }
        
        if (fetchedResults != nil){
            for list in fetchedResults!{
                downloadedTitles.append(list.value(forKey: "title") as! String)
            }
        }
        NSLog("Word lists already downloaded: %@", downloadedTitles)
        
        
        //download lists via CloudKit
        let predicate = NSPredicate(format: "NOT (%@ CONTAINS Name)", downloadedTitles)
        let query = CKQuery(recordType: "List", predicate: predicate)
        
        let queryOperation = CKQueryOperation(query: query)
        let operationQueue = OperationQueue()
        self.executeListQueryOperation(queryOperation, onOperationQueue: operationQueue)
    }
    
    func executeListQueryOperation(_ queryOperation: CKQueryOperation, onOperationQueue operationQueue: OperationQueue) {
        NSLog("Executing query operation")
        let container = CKContainer(identifier: "iCloud.quaritate.Agni")
        let publicDB = container.publicCloudDatabase
        
        queryOperation.database = publicDB
        
        queryOperation.recordFetchedBlock = {(record:CKRecord) in
            self.saveRecord(record)
        }
        
        queryOperation.queryCompletionBlock = {(cursor:CKQueryCursor?, error:Error?)->Void in
            if error != nil{
                NSLog("Query error: \(error.debugDescription)")
                return
            }
            if let queryCursor = cursor { //there are more operations to execute
                let queryCursorOperation = CKQueryOperation(cursor: queryCursor)
                self.executeListQueryOperation(queryCursorOperation, onOperationQueue: operationQueue)
            }
        }
        publicDB.add(queryOperation)
    }
    
    func saveRecord(_ record:CKRecord){
        if record.object(forKey: "Words") != nil{
            NSLog("Downloading via array")
            let wordsArray = record.object(forKey: "Words") as! [String]
            Converter.saveListToCoreData(listItems: wordsArray, listTitle: record.object(forKey: "Name") as! String, listAuthor: record.object(forKey: "Author") as! String)
            
        }else if record.object(forKey: "WordsTextFile") != nil{
            NSLog("Downloading via text file")
            let textfile = record.object(forKey: "WordsTextFile") as! CKAsset
            let data = try? Data(contentsOf: textfile.fileURL)
            Converter.saveListToCoreData(listData: data!, listTitle: record.object(forKey: "Name") as! String, listAuthor: record.object(forKey: "Author") as! String)
        }
    }
    
    //MARK - Skins code
    func getNewSkins(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Skin")
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
        } catch _{
            NSLog("Something went wrong getting skins from data")
        }
        
        NSLog("Skins already downloaded: ")
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
        
        //Let's download some skins!
        let truePredicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: "Skin", predicate: truePredicate)
        
        
        let queryOperation = CKQueryOperation(query: query)
        let operationQueue = OperationQueue()
        self.executeSkinQueryOperation(queryOperation, onOperationQueue: operationQueue)
    }
    
    func executeSkinQueryOperation(_ queryOperation: CKQueryOperation, onOperationQueue operationQueue: OperationQueue) {
        NSLog("Executing skin query operation")
        let container = CKContainer(identifier: "iCloud.quaritate.Agni")
        let publicDB = container.publicCloudDatabase
        
        queryOperation.database = publicDB
        
        queryOperation.recordFetchedBlock = {(record:CKRecord) in
            self.downloadSkin(record)
        }
        
        queryOperation.queryCompletionBlock = {(cursor:CKQueryCursor?, error:Error?)->Void in
            if error != nil{
                NSLog("Query error: \(error.debugDescription)")
                return
            }
            if let queryCursor = cursor { //there are more operations to execute
                let queryCursorOperation = CKQueryOperation(cursor: queryCursor)
                self.executeSkinQueryOperation(queryCursorOperation, onOperationQueue: operationQueue)
            }
        }
        publicDB.add(queryOperation)
    }
    
    
    func downloadSkin(_ download:CKRecord){
        let downloadName = download.object(forKey: "Name") as! String
        if !(downloadedSkins.keys.contains(downloadName) && downloadedSkins[downloadName]! == (download.object(forKey: "Version") as? Int)){
            
            guard let imageFile = download.object(forKey: "File") as? CKAsset
                else{return}
            
            let data = try? Data(contentsOf: imageFile.fileURL)
            let image = UIImage(data: data!) //large image, used for carousel
            
            //Figure out the scaled size
            let ratio = image!.size.height / image!.size.width
            let size:CGSize
            switch scale{
            case 1.0:
                size = CGSize(width: 212.0, height: 212.0 * ratio)
            case 2.0:
                size = CGSize(width: 318.0, height: 318.0 * ratio)
            default:
                size = CGSize(width: 212.0, height: 212.0 * ratio)
            }
            UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
            image?.draw(in: CGRect(origin: CGPoint.zero, size: size))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let skinData = UIImagePNGRepresentation(scaledImage!)
            Converter.saveSkinToCoreData(skinData!, name: download.object(forKey: "Name") as! String, type: download.object(forKey: "Type") as! String, date: download.object(forKey: "creationDate") as! Date, version: download.object(forKey: "Version") as! Int, largeImageData: data!)
        }
    }
    
    func authenticateLocalPlayer(){
        print("Start authentication")
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {
            (viewController, error) in
            if (viewController != nil){
                print("Not logged in")
                var currentVC = self.window?.rootViewController
                while let presentedViewController = currentVC!.presentedViewController {
                    currentVC = presentedViewController
                }
                currentVC!.present(viewController!, animated: true, completion: nil)
            } else if localPlayer.isAuthenticated{
                self.gameCenterAuthenticated = true
                localPlayer.loadDefaultLeaderboardIdentifier(completionHandler: {(leaderboardId, error) in
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
    
    //MARK: Sharing files
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        do{
            let str = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue)
            let components = str.components(separatedBy: "\n")
            NSLog("File opened contains: \(components)")
            
            let alert = UIAlertController(title: "Save List", message: "Would you like to save '\(components[0])'?", preferredStyle: .alert)
            let actionNo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let actionYes = UIAlertAction(title: "Save", style: .default, handler: {
                action in
                self.saveListAction(components)
            })
            alert.addAction(actionNo)
            alert.addAction(actionYes)
            
            var currentVC = self.window?.rootViewController
            while let presentedViewController = currentVC!.presentedViewController {
                currentVC = presentedViewController
            }
            currentVC!.present(alert, animated: true, completion: nil)
            
        }catch _{print("Cannot convert URL")}
        
        let fileManager = FileManager.default
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)
        let path = documentsDirectory.first! + "/Inbox"
        do{
            let directoryContents = try fileManager.contentsOfDirectory(atPath: path)
            for file in directoryContents{
                print(file)
                try fileManager.removeItem(atPath: path + "/" + file)
            }
        }catch {
            print((error as NSError).description)
        }
        
        return true
    }
    
    func saveListAction( _ components:[String]){
        var comps = components
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList") //get the list of lists
        
        let predicate = NSPredicate(format: "title == %@", components[0])
        fetchRequest.predicate = predicate
        do {
            let results = try managedContext.fetch(fetchRequest)
            if results.count == 0 && components[0] != "English Starter Pack" && components[0] != "Latin Starter Pack"{
                Converter.saveListToCoreData(components)
            }else{
                let alert = UIAlertController(title: "List name already taken", message: "Choose a different name:", preferredStyle: .alert)
                let actionNo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let actionYes = UIAlertAction(title: "Save", style: .default, handler: {
                    action in
                    comps[0] = (alert.textFields?.first?.text)!
                    self.saveListAction(comps)
                })
                actionYes.isEnabled = false
                alert.addAction(actionNo)
                alert.addAction(actionYes)
                alert.addTextField(configurationHandler: {textfield in
                    textfield.placeholder = "New name"
                    textfield.addTarget(self, action: #selector(AppDelegate.alertTextFieldDidChange), for: .editingChanged)
                })
                
                var currentVC = self.window?.rootViewController
                while let presentedViewController = currentVC!.presentedViewController {
                    currentVC = presentedViewController
                }
                currentVC!.present(alert, animated: true, completion: nil)
            }
        } catch let error1 as NSError {
            NSLog("%@", error1)
            
        }
    }
    
    func alertTextFieldDidChange(){
        var currentVC = self.window?.rootViewController
        while let presentedViewController = currentVC!.presentedViewController {
            currentVC = presentedViewController
        }
        if let alert = currentVC as? UIAlertController{
            let textfield = alert.textFields?.first
            let saveAction = alert.actions.last
            if textfield!.text!.characters.count > 0{
                saveAction?.isEnabled = true
            }
        }
    }
    
    //MARK: Push notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //NEED to add implementation
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if error._code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        if let pushInfo = userInfo as? [String: NSObject] {
            let notification = CKNotification(fromRemoteNotificationDictionary: pushInfo)
            
            let ac = UIAlertController(title: "What's that Whistle?", message: notification.alertBody, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            if let nc = window?.rootViewController as? UINavigationController {
                if let vc = nc.visibleViewController {
                    vc.present(ac, animated: true, completion: nil)
                }
            }
        }
        
    }
    
    // MARK: - Core Data stack
    // Used to implement persistant data
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.xxxx.ProjectName" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Store", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        var options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        let url = self.applicationDocumentsDirectory.appendingPathComponent("Agni.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch var error1 as NSError {
            error = error1
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
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
 
