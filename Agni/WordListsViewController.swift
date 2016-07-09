//
//  WordListsViewController.swift
//  
//
//  Created by Michael Ginn on 5/5/15.
//
//

import UIKit
import CoreData


class WordListsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var selectedTitles:[String] = []
    var lists:[NSManagedObject] = [] //lists from CoreData
    var defaults = NSUserDefaults.standardUserDefaults() //get app-wide data
    
    
    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 1.0)]
        
        //find all the lists and load em up
        self.lists = []
        
        //get lists saved in persistant memory
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"WordList") //get the list of lists
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
        } catch _{
            NSLog("Something went wrong getting words")
        }
        if (fetchedResults != nil){
            for list in fetchedResults!{
                self.lists.append(list)
            }
        }
        self.selectedTitles = self.defaults.objectForKey("selectedTitles") as! [String]
        self.tableView.reloadData() //will show which lists are selected

    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 2
        }else if section == 1{
            return self.lists.count
        }else{
            return 0
        }
        //return (self.lists.count + 2) //"+ 2" because of the two preinstalled word lists
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("listCell", forIndexPath: indexPath)
//        if indexPath.row == 0{ //Latin pack
//            cell.textLabel?.text = "Latin Starter Pack"
//            cell.detailTextLabel?.text = "Agni Dev"
//        } else if indexPath.row == 1{ //English pack
//            cell.textLabel?.text = "English Starter Pack"
//            cell.detailTextLabel?.text = "Agni Dev"
//        } else { //A downloaded pack
//            cell.textLabel?.text = (self.lists[indexPath.row - 2].valueForKey("title") as! String)
//            cell.detailTextLabel?.text = (self.lists[indexPath.row - 2].valueForKey("author") as! String)
//        }
        if indexPath.section == 0{
            if indexPath.row == 0{
                cell.textLabel?.text = "Latin Starter Pack"
                cell.detailTextLabel?.text = "Agni Dev"
            }else if indexPath.row == 1{
                cell.textLabel?.text = "English Starter Pack"
                cell.detailTextLabel?.text = "Agni Dev"
            }
        }else{
            cell.textLabel?.text = (self.lists[indexPath.row].valueForKey("title") as! String)
            cell.detailTextLabel?.text = (self.lists[indexPath.row ].valueForKey("author") as! String)

        }
        
        
        if selectedTitles.contains((cell.textLabel!.text!)){
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
        if self.selectedTitles.contains((cell.textLabel!.text!)) && self.selectedTitles.count >= 2{
            //cell is selected and not the only selected one
            self.selectedTitles.removeAtIndex(selectedTitles.indexOf((cell.textLabel!.text!))!)
            cell.accessoryType = UITableViewCellAccessoryType.None
        } else {
            //cell is not selected
            self.selectedTitles.append(cell.textLabel!.text!)
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        }
        self.defaults.setObject(selectedTitles, forKey: "selectedTitles")
        if !(defaults.objectForKey("needsUpdateSources") as! Bool){
            defaults.setObject(true, forKey: "needsUpdateSources") //Game screen will reload data sources
        }
        dispatch_async(dispatch_get_main_queue(), {
            //save in the background
            self.defaults.synchronize()
        })
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        //Space between starter and downloaded
        if section == 0{
            return 10
        }else{
            return 0
        }
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UITableViewHeaderFooterView()
        footerView.backgroundView = UIView()
        footerView.backgroundView?.backgroundColor = UIColor.whiteColor()
        return footerView
    }
}
