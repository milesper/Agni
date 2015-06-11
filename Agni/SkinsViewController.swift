//
//  SkinsViewController.swift
//  Agni
//
//  Created by Michael Ginn on 6/1/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit
import StoreKit
import CoreData
import Parse
import ParseUI

class SkinsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var defaults = NSUserDefaults.standardUserDefaults()
    var savedSkins:[NSManagedObject] = []
    var savedTitles:[String] = []
    var parseSkins:[PFObject] = []
    
    @IBOutlet weak var tableView: UITableView!


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }

    override func viewDidAppear(animated: Bool) {
        if !defaults.boolForKey("skinsUnlocked"){
            self.performSegueWithIdentifier("purchasePage", sender: self)
        }
        
        self.loadSources()
    }
    
    func loadSources(){
        //get CoreData skins
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"Skin")
        var error: NSError?
        
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject]
        if (fetchedResults != nil){
            self.savedSkins = fetchedResults!
            for skin in self.savedSkins{
                NSLog("%@", skin.valueForKey("title") as! String)
                self.savedTitles.append(skin.valueForKey("title") as! String)
            }
        }
        
        var query = PFQuery(className: "Skin")
        query.whereKey("Title", notContainedIn: self.savedTitles)
        query.findObjectsInBackgroundWithBlock({
            (data,error) in
            self.parseSkins = data as! [PFObject]
            self.tableView.reloadData()
        })

    }

    //  TableView methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return 1
        case 1:
            return self.savedSkins.count
        case 2:
            return self.parseSkins.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section{
        case 0:
            return "Preinstalled"
        case 1:
            return "Downloaded"
        case 2:
            return "Web"
        default:
            return "Error"
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //get views
        var cell = tableView.dequeueReusableCellWithIdentifier("skinCell") as! UITableViewCell
        var personImageView = cell.viewWithTag(1) as! PFImageView
        var swordImageView = cell.viewWithTag(2) as! PFImageView
        var sheepImageView = cell.viewWithTag(3) as! PFImageView
        var useButton = cell.viewWithTag(4) as! UIButton
        
        if indexPath.section == 0{
            if (defaults.valueForKey("currentSkin") as! String) == "Default"{
                checkButton(useButton)
            } else{
                uncheckButton(useButton)
            }
            personImageView.image = UIImage(named: "stickfigure small.png")
            swordImageView.image = UIImage(named: "sword small.png")
            sheepImageView.image = UIImage(named: "Sheep small.png")
        }else if indexPath.section == 1{
            //CoreData
            var skin = self.savedSkins[indexPath.row]
            if (defaults.valueForKey("currentSkin") as! String) == skin.valueForKey("title") as! String{
                checkButton(useButton)
            } else{
                uncheckButton(useButton)
            }
            personImageView.image = UIImage(data: skin.valueForKey("personImage") as! NSData)
            swordImageView.image = UIImage(data: skin.valueForKey("swordImage") as! NSData)
            sheepImageView.image = UIImage(data: skin.valueForKey("sheepImage") as! NSData)
        }else if indexPath.section == 2{
            //on parse
            var skin = self.parseSkins[indexPath.row]
            if let personFile = (skin.objectForKey("Person") as? PFFile){
                personImageView.file = personFile
                personImageView.loadInBackground()
            }
            if let swordFile = (skin.objectForKey("Sword") as? PFFile){
                swordImageView.file = swordFile
                swordImageView.loadInBackground()
            }
            if let sheepFile = (skin.objectForKey("Sheep") as? PFFile){
                sheepImageView.file = sheepFile
                sheepImageView.loadInBackground()
            }
        }
        useButton.addTarget(self, action: "useButtonPressed:", forControlEvents: .TouchUpInside )//download the file
        return cell
    }
    
    func checkButton(button: UIButton){
        button.setTitle("", forState: .Normal)
        button.imageView?.contentMode = .ScaleAspectFit
        button.setImage(UIImage(named: "Checkmark-32.png"), forState: .Normal)
        button.adjustsImageWhenDisabled = false
        button.enabled = false
    }
    
    func uncheckButton(button:UIButton){
        button.setTitle("Use", forState: .Normal)
        button.setImage(nil, forState: .Normal)
        button.enabled = true
    }
    
    func useButtonPressed(sender: AnyObject){
        var buttonPosition = sender.convertPoint(CGPointZero, toView: self.tableView)
        var indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition)
        var cell = tableView.cellForRowAtIndexPath(indexPath!)
        var button = cell?.viewWithTag(4) as! UIButton

        if indexPath?.section == 0{
            defaults.setValue("Default", forKey: "currentSkin")
            dispatch_async(dispatch_get_main_queue(), {
                self.defaults.synchronize()
                self.tableView.reloadData()
            })
        }else if indexPath?.section == 1{
            let title = self.savedSkins[indexPath!.row].valueForKey("title") as! String
            defaults.setValue(title, forKey: "currentSkin")
            dispatch_async(dispatch_get_main_queue(), {
                self.defaults.synchronize()
                self.tableView.reloadData()
            })
        }else if indexPath?.section == 2{
            let skin = self.parseSkins[indexPath!.row]
            Converter.saveSkinInBackground(skin, completion: {
                finished in
                self.loadSources()
                dispatch_async(dispatch_get_main_queue(), {
                    UIView.transitionWithView(self.tableView, duration: 0.3, options: .TransitionCrossDissolve, animations: {
                        self.tableView.reloadData()
                    }, completion: nil)
                })
            })
            
            
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.defaults.synchronize()
        })
    }
    
}
