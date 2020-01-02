//
//  MenuViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/9/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit
import GameKit

class MenuViewController: UIViewController, GKGameCenterControllerDelegate, UITableViewDelegate, UIViewControllerTransitioningDelegate, HintIAPManagerDelegate {
    
    @IBOutlet weak var sheepImageView: UIImageView!
    
    @IBOutlet weak var wordListLabel: UILabel!
    @IBOutlet weak var studyModeSwitch: UISwitch!
    @IBOutlet weak var hintsRemainingButton: UIButton!

    
    var hintManager = HintIAPManager()
    
    
    @IBOutlet weak var skinMenuItem: MenuItemView!
    var wordLists:[String] = []
    var w:CGFloat = 0.5
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.sheepImageView.image = Converter.getCurrentSkinImage()!
        wordListLabel.text = AgniDefaults.selectedTitle
        studyModeSwitch.setOn(AgniDefaults.studyModeOn, animated: true)
        
        hintsRemainingButton.setTitle("Hints remaining: \(AgniDefaults.hintsRemaining)", for: .normal)
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadSkin), name: .skinChosen, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: .sourceChanged, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.loadSkin()
        self.loadList()
    }
    
    @objc private func loadList(){
        wordListLabel.text = AgniDefaults.selectedTitle
    }
    
    @objc private func loadSkin(){
        self.sheepImageView.image = Converter.getCurrentSkinImage()!
        self.view.setNeedsLayout()
    }
    
    // MARK: Menu Items
    
    @IBAction func toggleStudyMode(_ sender: Any) {
        AgniDefaults.studyModeOn = studyModeSwitch.isOn
        NotificationCenter.default.post(Notification(name: .sourceChanged))
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
    
    @IBAction func showIconsLink(_ sender: Any) {
        if let link = URL(string: "https://icons8.com") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(link)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(link)
            } }
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
    
    // MARK: Hints
    
    @IBAction func getHints(_ sender: Any) {
        let alert = UIAlertController(title: "Get more hints?", message: "Add 50 hints", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { (action) in
            self.hintManager.buy()
            self.hintManager.delegate = self
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func paymentBegun() {
        //we might do something or not
    }
    
    func paymentEnded(successful: Bool) {
        hintsRemainingButton.setTitle("Hints remaining: \(AgniDefaults.hintsRemaining)", for: .normal)
    }
    
    
    
    //GKGameCenterVC delegate
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
  
    
}
