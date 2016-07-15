//
//  MenuViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/9/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit
import GameKit

class MenuViewController: UIViewController, GKGameCenterControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate {
    var defaults = NSUserDefaults.standardUserDefaults() //get app-wide data
    
    @IBOutlet weak var sheepImageView: UIImageView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var wordListTableView: UITableView!
    
    @IBOutlet weak var skinMenuItem: MenuItemView!
    var wordLists:[String] = []
    var w:CGFloat = 0.5
    var timer:NSTimer?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.sheepImageView.image = Converter.getCurrentSkinImage()!
        
        wordLists = self.defaults.objectForKey("selectedTitles") as! [String]
        wordLists.sortInPlace()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.sheepImageView.image = Converter.getCurrentSkinImage()!
        
        wordLists = self.defaults.objectForKey("selectedTitles") as! [String]
        wordLists.sortInPlace()
        wordListTableView.reloadData()
        
        if self.wordListTableView.contentSize.height > self.wordListTableView.frame.height{
        timer = NSTimer.scheduledTimerWithTimeInterval(0.025, target: self, selector: #selector(MenuViewController.scrollTableView), userInfo: nil, repeats: true)
        w = 0.5
        }
    }
    
    func scrollTableView(){
        var scrollPoint = self.wordListTableView.contentOffset
        scrollPoint.y = scrollPoint.y + w
        if scrollPoint.y >= self.wordListTableView.contentSize.height - self.wordListTableView.frame.height + 20{
            w *= -1
        }
        if scrollPoint.y < 0{
            w = 0
        }
        self.wordListTableView.setContentOffset(scrollPoint, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showGameCenter(sender: AnyObject) {
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
    
    @IBAction func closeMenu(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    
    //GKGameCenterVC delegate
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //TableView 
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wordLists.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ListCell")!
        cell.backgroundColor = UIColor.clearColor()
        let label = cell.viewWithTag(1) as! UILabel
        label.layer.cornerRadius = label.frame.height / 2.0
        
        label.text = wordLists[indexPath.row]
        return cell
    }
    
    //Transitions
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return MenuZoomTransition(view: skinMenuItem)
    }
}
