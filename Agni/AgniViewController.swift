//
//  AgniViewController.swift
//
//
//  Created by Michael Ginn on 5/2/15.
//
//

import UIKit
import AVFoundation
import GameKit
import CoreData
import SpriteKit


class AgniViewController: UIViewController, UIViewControllerTransitioningDelegate, GameplayDelegate {
    
    //interface components
    var gameplayVC: GameplayViewController?
    
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var winsButton: UIButton!
    @IBOutlet weak var volumeButton: UIButton!
    
    var firstTime = false
    
    var winStreak = 0 //update after each win
    var winning = false
    
    var lastSegue:UIStoryboardSegue?
    let svinteractor = MenuItemInteractor()
    
    var musicStarted = false
    
    //MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (UIApplication.shared.delegate as! AppDelegate).authenticateLocalPlayer()
        
        // Get Gameplay controller
        guard let gameplay = children.first as? GameplayViewController else{
            fatalError("Check storyboard, missing childGameplayVC")
        }
        gameplayVC = gameplay
        
        let manager = GameplayManager(provider: StandardWordProvider())
        gameplayVC?.manager = manager
        gameplayVC?.delegate = self
        gameplayVC?.load()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Load any needed transitions
        if AgniDefaults.selectedTitle == ""{ //this will be changed by the selected titles screen
            self.performSegue(withIdentifier: "showWelcome", sender: self)
            firstTime = true
        }else if AgniDefaults.lastVersionShown != Constants.CURRENT_VERSION && !firstTime{
            self.performSegue(withIdentifier: "showWhatsNew", sender: self)
        }else{
            //Normal boot
            self.setup()
        }
    }
    
    
    /**
     Sets up the graphics and sound
     */
    func setup(){
        //Called only once for the word pack
        if !musicStarted{
            if AgniDefaults.musicOn{
                GameSounds.standard.toggleBGMusic()
            }else{
                self.volumeButton.setBackgroundImage(UIImage(named: "mute.png"), for: UIControl.State())
            }
            musicStarted = true
        }
    }
    
    @IBAction func toggleMusic(_ sender: UIButton) {
        GameSounds.standard.toggleBGMusic()
        
        sender.setBackgroundImage(UIImage(named: (AgniDefaults.musicOn ? "mute.png" : "sound.png")), for: UIControl.State())
        AgniDefaults.musicOn.toggle()
    }
    
    //MARK: Delegate Methods
    func refreshed() {
        winStreak = 0
    }
    
    func allCompleted() {
        self.performSegue(withIdentifier: "finished", sender: self)
    }
    
    func gameWon() {
        //Streak stuff
        if !AgniDefaults.customListUsed{
            //Update streak
            if self.winning{
                self.winStreak += 1
            }else{
                self.winStreak = 1
            }
            if self.winStreak > AgniDefaults.longestStreak{
                Achievements.standard.higherWinStreak(self.winStreak)
            }
            self.winning = true
            
            //stuff for achievements
            Achievements.standard.win()
            
            //win some hints
            if self.winStreak % 5 == 0{
                HintIAPManager.addHints(2, withDisplay: true)
            }
        }
    }
    
    
    func gameLost() {
        self.winning = false
        self.winStreak = 0
        
        self.performSegue(withIdentifier: "loss", sender: self) //show lost screen
        Achievements.standard.loss()
    }
    
    func startNewWord() {
        self.winsButton.setTitle("\(QTRomanNumerals.convertToRomanNum(decimalNum: self.winStreak))", for: UIControl.State())
        if self.winStreak == 0 {self.winsButton.setTitle("0", for: UIControl.State())}
    }
    
    
    
    //MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.lastSegue = segue
        if segue.identifier == "loss"{
            let toViewController = segue.destination as! LossViewController
            toViewController.transitioningDelegate = self
            
            toViewController.word = gameplayVC?.manager.chosenWord ?? "Error getting word" //loss screen will tell the user the word
        }else if segue.identifier == "finished"{
            let toViewController = segue.destination as! FinishedViewController
            toViewController.transitioningDelegate = self
        }else if segue.identifier == "stats"{
            let toViewController = segue.destination as! StatsViewController
            //toViewController.transitioningDelegate = self
        }else if segue.identifier == "showMenu"{
//            let toViewController = segue.destination as! MenuViewController
//            toViewController.transitioningDelegate = self
//            toViewController.interactor = svinteractor
        }
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 1.0)]
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let segue = self.lastSegue else{return nil}

        switch segue.identifier!{
        case "loss":
            return ShakeTransition()
        case "finished":
            return ConfettiTransition()
        case "stats":
            return CircleTransition(button: winsButton)
//        case "showMenu":
//            return MenuSwingTransition(button: menuButton)
        default:
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let segue = self.lastSegue else{return nil}

        switch segue.identifier!{
        case "stats":
            return ReverseCircleTransition(button: winsButton)
//        case "showMenu":
//            return ReverseMenuSlideTransition()
        default:
            return nil
        }
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return svinteractor.hasStarted ? svinteractor : nil
    }
}
