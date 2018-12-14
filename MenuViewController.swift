//
//  MenuViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/9/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit
import GameKit

class MenuViewController: MenuItemViewController, GKGameCenterControllerDelegate, UITableViewDelegate, UIViewControllerTransitioningDelegate, HintIAPManagerDelegate {
    
    var defaults = UserDefaults.standard //get app-wide data
    
    @IBOutlet weak var sheepImageView: UIImageView!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var wordListLabel: UILabel!
    @IBOutlet weak var studyModeSwitch: UISwitch!
    @IBOutlet weak var hintsRemainingButton: UIButton!

    
    var hintManager = HintIAPManager()
    
    let svinteractor = MenuItemInteractor()
    
    @IBOutlet weak var skinMenuItem: MenuItemView!
    var wordLists:[String] = []
    var w:CGFloat = 0.5
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.sheepImageView.image = Converter.getCurrentSkinImage()!
        wordListLabel.text = (self.defaults.object(forKey: "selectedTitle") as! String)
        studyModeSwitch.setOn(defaults.bool(forKey: "study_mode_on"), animated: true)
        
        hintsRemainingButton.setTitle("Hints remaining: \(HintIAPManager.hintsRemaining)", for: .normal)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.sheepImageView.image = Converter.getCurrentSkinImage()!
        self.view.setNeedsLayout()
        
        wordListLabel.text = (self.defaults.object(forKey: "selectedTitle") as! String)
    }
    
    // MARK: Menu Items
    
    @IBAction func toggleStudyMode(_ sender: Any) {
        defaults.set(studyModeSwitch.isOn, forKey: "study_mode_on")
        defaults.set(true, forKey: "needsUpdateSources")
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
        hintsRemainingButton.setTitle("Hints remaining: \(HintIAPManager.hintsRemaining)", for: .normal)
    }
    
    
    // MARK: Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationViewController = segue.destination as? MenuItemViewController {
            destinationViewController.transitioningDelegate = self
            destinationViewController.interactor = svinteractor
        }
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return svinteractor.hasStarted ? svinteractor : nil
    }
    
    //GKGameCenterVC delegate
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }
  
    
}
