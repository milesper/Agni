//
//  SettingsViewController.swift
//  Agni
//
//  Created by Michael Ginn on 12/23/15.
//  Copyright © 2015 Michael Ginn. All rights reserved.
//

import UIKit
import GameKit

class SettingsViewController: UIViewController, GKGameCenterControllerDelegate{

    var defaults = NSUserDefaults.standardUserDefaults() //get app-wide data
    @IBOutlet weak var wordListLabel: UILabel!
    @IBOutlet weak var skinImage: UIImageView!
    var embededTableVC:SettingsTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.presentTransparentNavigationBar()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 1.0)]
    }
    func loadData(){
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
    @IBAction func showAchievements(sender: AnyObject) {
        if (UIApplication.sharedApplication().delegate as! AppDelegate).gameCenterAuthenticated{
            self.showLeaderboardAndAchievements(false)
        }else{
            (UIApplication.sharedApplication().delegate as! AppDelegate).authenticateLocalPlayer()
        }
    }
    
    func showLeaderboardAndAchievements(leaderboard:Bool){
        let gcViewController: GKGameCenterViewController = GKGameCenterViewController()
        gcViewController.gameCenterDelegate = self
        
        if leaderboard{
            gcViewController.viewState = GKGameCenterViewControllerState.Leaderboards
            //add leaderboard id here
        }else{
            gcViewController.viewState = GKGameCenterViewControllerState.Achievements
        }
        self.presentViewController(gcViewController, animated: true, completion: nil)
    }
    
    
    //GKGameCenterVC delegate
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //segue stuff
    @IBAction func doneButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "embedTableView"{
            let embeddedTableVC = segue.destinationViewController as! SettingsTableViewController
            if #available(iOS 9.0, *) {
                embeddedTableVC.loadViewIfNeeded()
            } else {
                // Fallback on earlier versions
                embeddedTableVC.loadView()
            }
            self.wordListLabel = embeddedTableVC.getWordListLabel()
            self.skinImage = embeddedTableVC.getSkinImageView()
            loadData()
        }
    }
}
