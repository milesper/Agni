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
    var defaults = UserDefaults.standard //get app-wide data
    
    @IBOutlet weak var sheepImageView: UIImageView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var wordListTableView: UITableView!
    
    let interactor = MenuItemInteractor()
    
    @IBOutlet weak var skinMenuItem: MenuItemView!
    var wordLists:[String] = []
    var w:CGFloat = 0.5
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.sheepImageView.image = Converter.getCurrentSkinImage()!
        
        wordLists = self.defaults.object(forKey: "selectedTitles") as! [String]
        wordLists.sort()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.sheepImageView.image = Converter.getCurrentSkinImage()!
        
        wordLists = self.defaults.object(forKey: "selectedTitles") as! [String]
        wordLists.sort()
        wordListTableView.reloadData()
        
        if self.wordListTableView.contentSize.height > self.wordListTableView.frame.height{
            timer = Timer.scheduledTimer(timeInterval: 0.025, target: self, selector: #selector(MenuViewController.scrollTableView), userInfo: nil, repeats: true)
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
    
    @IBAction func showGameCenter(_ sender: AnyObject) {
        if (UIApplication.shared.delegate as! AppDelegate).gameCenterAuthenticated{
            self.showLeaderboardAndAchievements(false)
        }else{
            (UIApplication.shared.delegate as! AppDelegate).authenticateLocalPlayer()
        }
    }
    
    func showLeaderboardAndAchievements(_ leaderboard:Bool){
        let gcViewController: GKGameCenterViewController = GKGameCenterViewController()
        gcViewController.gameCenterDelegate = self
        
        if leaderboard{
            gcViewController.viewState = GKGameCenterViewControllerState.leaderboards
            //add leaderboard id here
        }else{
            gcViewController.viewState = GKGameCenterViewControllerState.achievements
        }
        self.present(gcViewController, animated: true, completion: nil)
    }
    
    @IBAction func closeMenu(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareSheet(_ sender: AnyObject) {
        let sheepImage = UIImage(named: "Sheep")
        let activityItems:[AnyObject] = ["Check out Agni: Roman Hangman on the App Store!" as AnyObject, URL(string: "http://appsto.re/us/jPsr7")! as AnyObject, sheepImage!]
        
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if activityViewController.responds(to: #selector(getter: UIViewController.popoverPresentationController)){
            activityViewController.popoverPresentationController?.sourceView = sender as! UIButton
        }
        self.present(activityViewController, animated: true, completion: nil)

    }
    
    //Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? MenuItemViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = interactor
        }
        
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ReverseMenuItemTransition()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
    
    //GKGameCenterVC delegate
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
    
    //TableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wordLists.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell")!
        cell.backgroundColor = UIColor.clear
        let label = cell.viewWithTag(1) as! UILabel
        label.layer.cornerRadius = label.frame.height / 2.0
        
        label.text = wordLists[(indexPath as NSIndexPath).row]
        return cell
    }
    
    
}
