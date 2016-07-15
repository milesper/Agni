//
//  ListCreatorViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/14/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class ListCreatorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    var defaults = NSUserDefaults.standardUserDefaults() //use to get app-wide data
    
    var userLists:[NSManagedObject] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        defaults.setObject(["Latin III"], forKey: "userCreatedLists")
        if defaults.objectForKey("userCreatedLists") == nil{
            let blankArray:[String] = []
            defaults.setObject(blankArray, forKey: "userCreatedLists")
            userLists = []
        }else{
            let listNames = defaults.objectForKey("userCreatedLists") as! [String]
            //get lists saved in persistant memory
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let fetchRequest = NSFetchRequest(entityName:"WordList") //get the list of lists
            let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            let predicate = NSPredicate(format: "title IN %@", listNames)
            fetchRequest.predicate = predicate

            var fetchedResults:[NSManagedObject]? = nil
            do{
                fetchedResults = try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            } catch _{
                NSLog("Something went wrong getting words")
            }
            if (fetchedResults != nil){
                for list in fetchedResults!{
                    self.userLists.append(list)
                }
            }

        }
    }
    
    //Collection View
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userLists.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("fileCell", forIndexPath: indexPath)
        let label = cell.viewWithTag(1) as! UILabel
        label.text = (userLists[indexPath.row].valueForKey("title") as! String)
        
        return cell
    }
    
    @IBAction func closeListCreator(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
