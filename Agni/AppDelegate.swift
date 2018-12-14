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
 import Firebase
 
 struct Constants{
    static let CURRENT_VERSION = "1.7.0"
 }
 
 @UIApplicationMain
 class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var gameCenterAuthenticated:Bool = false
    var leaderboardIdentifier:String = ""
    
    let defaults = UserDefaults.standard //used to save app-wide data
    let messageController = MessagesController()
    
    /**
     Contains a dictionary of skins already downloaded
     
          [Skin name : Most recent version]
     
     */
    
    
    var downloadManager:DownloadManager = DownloadManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //One Signal
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "b8ba5f66-c4b0-4f03-9f50-d7d40e7dc982",
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.notification;
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
        })
        
        //Firebase
        FirebaseApp.configure()
        downloadManager.firestore = Firestore.firestore()
        downloadManager.firebaseStorage = Storage.storage()
        
        // Override point for customization after application launch.
        self.window!.tintColor = UIColor(red: 114/255.0, green: 191/255.0, blue: 125/255.0, alpha: 1.0)//change tint color
        
        
        if defaults.object(forKey: "skinsUnlocked") == nil{ //this will be changed by the selected titles screen
            defaults.set(false, forKey: "skinsUnlocked")
        }
        print("Skins unlocked: \(defaults.bool(forKey: "skinsUnlocked"))")
        
        //simulator testing only
        #if targetEnvironment(simulator)
            defaults.set(true, forKey: "skinsUnlocked")
            print("Unlocking skins for simulator testing")
        #endif
        
        if defaults.object(forKey: "currentSkin") == nil{
            defaults.setValue("Default", forKey: "currentSkin")
        }
        
        defaults.set(true, forKey: "needsUpdateSources") //cause the game to refresh its input sources
        
        if defaults.value(forKey: "beatenWordLists") == nil{
            defaults.set([], forKey: "beatenWordLists")
        }
        
        if defaults.string(forKey: "lastVersionShown") != nil && defaults.string(forKey: "lastVersionShown") != Constants.CURRENT_VERSION{
            downloadManager.deleteAllWords()
            downloadManager.deleteAllSkins()
        }
        
        let networkReachability = Reachability()!
        networkReachability.whenReachable = {reachability in
            print("Connected to the interwebs via \(reachability.connection.description)")
            self.downloadManager.getNewWords()
            self.downloadManager.getNewSkins()
        }
        networkReachability.whenUnreachable = {_ in
            print("No connection :(")
        }
        
        do {
            try networkReachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
        
        func makeNonNil(_ key:String){
            if defaults.object(forKey: key) == nil{
                defaults.set(0, forKey: key)
            }
        }
        
        //gamecenter achievement setup
        
        makeNonNil("win_total")
        makeNonNil("win_streak")
        makeNonNil("longest_streak")
        makeNonNil("loss_total")
        makeNonNil("days_played")
        
        if defaults.object(forKey: "used_skins") == nil || defaults.array(forKey: "used_skins")!.count == 0{
            defaults.set(["Default"], forKey: "used_skins")
        }
        
        if defaults.object(forKey: "hints_remaining") == nil{
            defaults.set(20, forKey: "hints_remaining")
        }
        
        if defaults.object(forKey: "used_codes") == nil{
            defaults.set([], forKey:"used_codes")
        }
        
        defaults.set(0, forKey: "displayed_popups")
        
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let comps = (calendar as NSCalendar?)?.components([.year, .month, .day], from: Date())
        let dateString = "\(comps!.day!) \(comps!.month!) \(comps!.year!)"
        if defaults.string(forKey: "last_day_played") != dateString{
            defaults.set(dateString, forKey: "last_day_played")
            
            let daysPlayed = defaults.integer(forKey: "days_played")
            defaults.set(daysPlayed + 1, forKey: "days_played")
        }
        
        defaults.synchronize()
        return true
    }

    
    
    //MARK: Game center
    
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
                        print("%@", error!.localizedDescription)
                    }else{
                        self.leaderboardIdentifier = leaderboardId!
                        print("\(self.leaderboardIdentifier)")
                    }
                })
            }else{
                if error != nil{
                    print("%@", error!.localizedDescription)
                    self.gameCenterAuthenticated = false
                }
            }
        }
    }
    
    //MARK: Sharing files
    //Opening file shared to app
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        do{
            let str = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue)
            let components = str.components(separatedBy: "\n")
            print("File opened contains: \(components)") //Should be 3 or 4 comps
            //Title, author, words, [meanings]
            
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
    
    func saveListAction( _ components:[String]){ //Triggered by opening custom file, saves to coredata
        var comps = components
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList") //get the list of lists
        
        let predicate = NSPredicate(format: "title == %@", components[0]) //Make sure title is not taken
        fetchRequest.predicate = predicate
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            if results.count == 0 && components[0] != "English Starter Pack" && components[0] != "Latin Starter Pack"{
                //Title not taken, go ahead saving
                Converter.saveListToCoreData(components)
            }else{
                //Title is taken, try again with a new title
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
            print("%@", error1)
            
        }
    }
    
    @objc func alertTextFieldDidChange(){
        var currentVC = self.window?.rootViewController
        while let presentedViewController = currentVC!.presentedViewController {
            currentVC = presentedViewController
        }
        if let alert = currentVC as? UIAlertController{
            let textfield = alert.textFields?.first
            let saveAction = alert.actions.last
            if textfield!.text!.count > 0{
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
            print("Unresolved error \(error!), \(error!.userInfo)")
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
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
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
                    print("Unresolved error \(error1), \(error1.userInfo)")
                    abort()
                }
            }
        }
    }
    
    
 }
 
