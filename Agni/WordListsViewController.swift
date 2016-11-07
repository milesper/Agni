//
//  WordListsViewController.swift
//
//
//  Created by Michael Ginn on 5/5/15.
//
//

import UIKit
import CoreData


class WordListsViewController: MenuItemViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    var selectedTitles:[String] = []
    var lists:[NSManagedObject] = [] //lists from CoreData
    var customLists:[NSManagedObject] = []
    
    var defaults = UserDefaults.standard //get app-wide data
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 1.0)]
        
        //find all the lists and load em up
        self.lists = []
        
        //get lists saved in persistant memory
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName:"WordList") //get the list of lists
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
        } catch _{
            NSLog("Something went wrong getting words")
        }
        if (fetchedResults != nil){
            for list in fetchedResults!{
                if list.value(forKey: "Author") as! String == "Agni Dev"{
                    self.lists.append(list)
                }else{
                    self.customLists.append(list)
                }
            }
        }
        self.selectedTitles = self.defaults.object(forKey: "selectedTitles") as! [String]
        self.tableView.reloadData() //will show which lists are selected
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.tag == 1{
            return 2
        }else if tableView.tag == 2{
            return 1
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1{
            if section == 0{
                return 2
            }else if section == 1{
                return self.lists.count
            }else{
                return 0
            }
        }else if tableView.tag == 2{
            return self.customLists.count
        }else{
            return 0
        }
        //return (self.lists.count + 2) //"+ 2" because of the two preinstalled word lists
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listCell", for: indexPath)
        
        if tableView.tag == 1{
            if (indexPath as NSIndexPath).section == 0{
                if (indexPath as NSIndexPath).row == 0{
                    cell.textLabel?.text = "Latin Starter Pack"
                    cell.detailTextLabel?.text = "Agni Dev"
                }else if (indexPath as NSIndexPath).row == 1{
                    cell.textLabel?.text = "English Starter Pack"
                    cell.detailTextLabel?.text = "Agni Dev"
                }
            }else{
                cell.textLabel?.text = (self.lists[(indexPath as NSIndexPath).row].value(forKey: "title") as! String)
                cell.detailTextLabel?.text = (self.lists[(indexPath as NSIndexPath).row ].value(forKey: "author") as! String)
                
            }
        }else if tableView.tag == 2{
            cell.textLabel?.text = (self.customLists[(indexPath as NSIndexPath).row].value(forKey: "title") as! String)
            cell.detailTextLabel?.text = (self.customLists[(indexPath as NSIndexPath).row].value(forKey: "author") as! String)
        }
        if selectedTitles.contains((cell.textLabel!.text!)){
            //list is selected
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        } else{
            //list is not selected
            cell.accessoryType = UITableViewCellAccessoryType.none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        
        
        if self.selectedTitles.contains((cell.textLabel!.text!)){
            if self.selectedTitles.count < 2{
                tableView.deselectRow(at: indexPath, animated: true)
                return
            }
            
            //cell is selected and not the only selected one
            self.selectedTitles.remove(at: selectedTitles.index(of: (cell.textLabel!.text!))!)
            cell.accessoryType = UITableViewCellAccessoryType.none
        }else{
            //cell is not selected
            self.selectedTitles.append(cell.textLabel!.text!)
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
        }
        self.defaults.set(selectedTitles, forKey: "selectedTitles")
        if !(defaults.object(forKey: "needsUpdateSources") as! Bool){
            defaults.set(true, forKey: "needsUpdateSources") //Game screen will reload data sources
        }
        DispatchQueue.main.async(execute: {
            //save in the background
            self.defaults.synchronize()
        })
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        //Space between starter and downloaded
        if section == 0{
            return 10
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UITableViewHeaderFooterView()
        footerView.backgroundView = UIView()
        footerView.backgroundView?.backgroundColor = UIColor.white
        return footerView
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let page = Int(floor((scrollView.contentOffset.x - pageWidth / 2 ) / pageWidth) + 1)
        
        pageControl.currentPage = page;
    }
    
    @IBAction func closeWordLists(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
