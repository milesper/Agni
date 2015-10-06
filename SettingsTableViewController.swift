//
//  SettingsTableViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/7/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class SettingsTableViewController: UITableViewController {
    var defaults = NSUserDefaults.standardUserDefaults() //get app-wide data
    @IBOutlet weak var wordListLabel: UILabel!
    @IBOutlet weak var skinImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.presentTransparentNavigationBar()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 1.0)]
    }

    override func viewDidAppear(animated: Bool) {
        var wordlists = self.defaults.objectForKey("selectedTitles") as! [String]
        var selectedListsString = ""
        for list in wordlists{
            if wordlists[0] == list{
                selectedListsString += list
            } else{
                selectedListsString += ", \(list)"
            }
        }
        self.wordListLabel.text = selectedListsString
        
        self.skinImage.image = Converter.getCurrentSkinImage()!
    }
    
    @IBAction func doneButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
