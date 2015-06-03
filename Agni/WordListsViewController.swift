//
//  WordListsViewController.swift
//  
//
//  Created by Michael Ginn on 5/5/15.
//
//

import UIKit
import CoreData
import Parse

class WordListsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var selectedTitles:[String] = []
    var lists:[NSManagedObject] = [] //lists from CoreData
    var defaults = NSUserDefaults.standardUserDefaults() //get app-wide data
    
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.presentTransparentNavigationBar()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 1.0)]
    }
    
    override func viewDidAppear(animated: Bool) {
        self.lists = []
    
        //get lists saved in persistant memory
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"WordList") //get the list of lists
        var error: NSError?
        
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject]
        if (fetchedResults != nil){
            for list in fetchedResults!{
                self.lists.append(list)
            }
        }
        self.selectedTitles = self.defaults.objectForKey("selectedTitles") as! [String]
        self.tableView.reloadData() //will show which lists are selected
        
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.lists.count + 2) //"+ 2" because of the two preinstalled word lists
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("listCell", forIndexPath: indexPath) as! UITableViewCell
        if indexPath.row == 0{ //Latin pack
            cell.textLabel?.text = "Latin Starter Pack"
            cell.detailTextLabel?.text = "Agni Dev"
        } else if indexPath.row == 1{ //English pack
            cell.textLabel?.text = "English Starter Pack"
            cell.detailTextLabel?.text = "Agni Dev"
        } else { //A downloaded pack
            cell.textLabel?.text = (self.lists[indexPath.row - 2].valueForKey("title") as! String)
            cell.detailTextLabel?.text = (self.lists[indexPath.row - 2].valueForKey("author") as! String)
        }
        
        if contains(selectedTitles, cell.textLabel!.text!){
            //list is selected
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        } else{
            //list is not selected
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if contains(self.selectedTitles, cell.textLabel!.text!) && self.selectedTitles.count >= 2{
            //cell is selected and not the only selected one
            self.selectedTitles.removeAtIndex(find(selectedTitles, cell.textLabel!.text!)!)
        } else {
            //cell is not selected
            self.selectedTitles.append(cell.textLabel!.text!)
        }
        self.defaults.setObject(selectedTitles, forKey: "selectedTitles")
        if !(defaults.objectForKey("needsUpdateSources") as! Bool){
            defaults.setObject(true, forKey: "needsUpdateSources") //Game screen will reload data sources
        }
        var time = dispatch_time(DISPATCH_TIME_NOW, 0)
        dispatch_after(time, dispatch_get_main_queue(), {
            //save in the background
            self.defaults.synchronize()
        })
        self.tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        var title = tableView.cellForRowAtIndexPath(indexPath)?.textLabel?.text
        let onlySelected = (selectedTitles.count == 1 && selectedTitles[0] == title)
        if editingStyle == UITableViewCellEditingStyle.Delete && indexPath.row > 1{
            //delete the list from saved memory
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            managedContext.deleteObject(lists[indexPath.row - 2])
            var error:NSError? = nil
            managedContext.save(&error)
            self.lists.removeAtIndex(indexPath.row - 2)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            
            
        }
        if contains(self.selectedTitles, title!){
            self.selectedTitles.removeAtIndex(find(selectedTitles, title!)!)
            self.defaults.setObject(selectedTitles, forKey: "selectedTitles")
            var time = dispatch_time(DISPATCH_TIME_NOW, 0)
            dispatch_after(time, dispatch_get_main_queue(), {
                //save in the background
                self.defaults.synchronize()
            })
        }
        if onlySelected{
            self.selectedTitles.append("Latin Starter Pack")
            self.defaults.setObject(selectedTitles, forKey: "selectedTitles")
            var time = dispatch_time(DISPATCH_TIME_NOW, 0)
            dispatch_after(time, dispatch_get_main_queue(), {
                //save in the background
                self.defaults.synchronize()
            })
            self.tableView.reloadData()
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row > 1 //only first two rows aren't editable
    }
}
