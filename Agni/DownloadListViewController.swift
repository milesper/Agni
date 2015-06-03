//
//  DownloadListViewController.swift
//  Agni
//
//  Created by Michael Ginn on 5/5/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import CoreData

class DownloadListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    //screen to download extra word packs
    var downloadedTitles:[String] = []
    var downloads:[PFObject] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        //get already downloaded lists
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"WordList")
        var error: NSError?
        self.downloadedTitles = []
        
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [NSManagedObject]
        if (fetchedResults != nil){
            for list in fetchedResults!{
                self.downloadedTitles.append(list.valueForKey("title") as! String)
            }
        }
        
        //get the downloadable lists from the online database that aren't already downloaded
        var query = PFQuery(className: "WordList")
        query.whereKey("Title", notContainedIn: self.downloadedTitles)
        query.findObjectsInBackgroundWithBlock({
            (data,error) in
            self.downloads = data as! [PFObject]
            self.tableView.reloadData()
        })
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.downloads.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //views in the cell
        var cell = tableView.dequeueReusableCellWithIdentifier("listCell") as! UITableViewCell
        var imageView = cell.viewWithTag(1) as! PFImageView
        var titleLabel = cell.viewWithTag(2) as! UILabel
        var authorLabel = cell.viewWithTag(3) as! UILabel
        var downloadButton = cell.viewWithTag(4) as! UIButton
    
        //fill the cell with data about the word list
        var download = self.downloads[indexPath.row]
        titleLabel.text = (download.valueForKey("Title") as! String)
        authorLabel.text = (download.valueForKey("Author") as! String)
        imageView.file = (download.valueForKey("Image") as! PFFile)
        imageView.loadInBackground()
        
        //show download button
        downloadButton.enabled = true
        downloadButton.setBackgroundImage(UIImage(named: "Download Colored.png"), forState: .Normal)
        downloadButton.addTarget(self, action: "downloadButtonPressed:", forControlEvents: .TouchUpInside )//download the file
        
        return cell
    }
    
    func downloadButtonPressed(sender: AnyObject){
        //download the corresponding file
        var buttonPosition = sender.convertPoint(CGPointZero, toView: self.tableView)
        var indexPath = self.tableView.indexPathForRowAtPoint(buttonPosition)
        var cell = tableView.cellForRowAtIndexPath(indexPath!)
        var button = cell?.viewWithTag(4) as! UIButton
        
        var download = self.downloads[indexPath!.row] //get the current download object
        var textfile = download.objectForKey("Textfile") as! PFFile
        
        
        //change the button image
        UIView.transitionWithView(button, duration: 0.2, options: UIViewAnimationOptions.TransitionCrossDissolve, animations: {
            button.setBackgroundImage(UIImage(named: "Active State Filled-100.png"), forState: .Normal)
        }, completion: nil) //change the buttons image to show downloading
        
        button.adjustsImageWhenDisabled = false
        button.enabled = false

        textfile.getDataInBackgroundWithBlock({
            (data,error) in
            if error == nil{
                ListConverter.saveToCoreData(data!, listTitle: download.valueForKey("Title") as! String, listAuthor: download.valueForKey("Author") as! String)

                UIView.transitionWithView(button, duration: 0.2, options: .TransitionCrossDissolve, animations: {
                    button.setBackgroundImage(UIImage(named: "Ok Filled-100.png"), forState: .Normal)
                    }, completion: nil)
            }
        })
        
    }
}
