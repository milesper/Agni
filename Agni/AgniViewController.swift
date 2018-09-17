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


class AgniViewController: UIViewController, UIViewControllerTransitioningDelegate, HintIAPManagerDelegate {
    //interface components
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var distanceFromPerson: NSLayoutConstraint!
    @IBOutlet weak var correctLabel: UILabel!
    @IBOutlet weak var sheepImage: UIImageView!
    @IBOutlet weak var sheepImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var swordImage: UIImageView!
    @IBOutlet weak var winsButton: UIButton!
    @IBOutlet weak var volumeButton: UIButton!
    @IBOutlet var letterButtons: [UIButton]!
    @IBOutlet weak var hintButton: UIButton!
    
    var sceneView:SKView?
    var scene: AgniScene?
    
    
    var manager = GameplayManager()
    var achivementManager = Achievements()
    var hintManager = HintIAPManager()
    
    var firstTime = false;
    
    var stage = 0 //goes up to 7, which is death
    var swordLocs:[CGFloat] = [] //holds all possible positions for the sword
    var winStreak = 0 //update after each win
    var winning = false
    let defaults = UserDefaults.standard //use to get app-wide data
    var lastSegue:UIStoryboardSegue?
    let svinteractor = MenuItemInteractor()
    var hintUsed = false
    
    var soundPlayer = GameSounds()
    var musicOn = true
    var musicStarted = false
    
    //MARK: Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView = (view as! SKView)
        
        
        
        (UIApplication.shared.delegate as! AppDelegate).authenticateLocalPlayer()
        
        manager = GameplayManager()
        
        for button in letterButtons{
            button.addTarget(self, action: #selector(AgniViewController.guessLetter(_:)), for: UIControlEvents.touchUpInside)
        }
        hintButton.setTitle("", for: .normal)
        //TODO: Make the stupid big sheep work
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if defaults.object(forKey: "selectedTitle") == nil{ //this will be changed by the selected titles screen
            self.performSegue(withIdentifier: "showWelcome", sender: self)
            firstTime = true
        }else if defaults.string(forKey: "lastVersionShown") != Constants.CURRENT_VERSION && !firstTime{
            self.performSegue(withIdentifier: "showWhatsNew", sender: self)
        }else{
            //Normal boot
            manager.reload()
            self.setup()
            self.scene = AgniScene(size: CGSize(width: self.sceneView!.frame.size.width, height: self.sceneView!.frame.size.height))
            self.sceneView?.presentScene(self.scene)
        }
        
        self.sheepImage.image = Converter.getCurrentSkinImage()?.resizeToWidth(width: sheepImage.frame.size.width * 2, scale: UIScreen.main.scale)
    }
    
    
    
    
    /**
     Sets up the graphics and sound
     */
    func setup(){
        //Called only once for the word pack
        if !musicStarted{
            if defaults.object(forKey: "musicOn") == nil || defaults.bool(forKey: "musicOn") == true{
                defaults.set(true, forKey: "musicOn")
                self.soundPlayer.toggleBGMusic()
            }else{
                self.volumeButton.setBackgroundImage(UIImage(named: "mute.png"), for: UIControlState())
                self.musicOn = false
            }
            musicStarted = true
        }
        
        //set up the stages for the sword
        let distance = (sheepImage.frame.origin.x - swordImage.frame.width) - swordImage.frame.origin.x
        let increment = distance / 6.0
        var distanceFromPerson = self.distanceFromPerson.constant
        
        for _ in 1...6 { //six stages of location for the sword
            distanceFromPerson += increment //add to the location
            swordLocs.append(distanceFromPerson)
        }
        
        if (defaults.value(forKey: "needsUpdateSources") as! Bool){ //user has changed which lists are used
            manager.reload()
            defaults.set(false, forKey: "needsUpdateSources")
        }
        
        self.startNewWord()
    }
    
    @IBAction func toggleMusic(_ sender: UIButton) {
        soundPlayer.toggleBGMusic()
        sender.setBackgroundImage(UIImage(named: (musicOn ? "mute.png" : "sound.png")), for: UIControlState())
        self.musicOn = !self.musicOn
    }
    
    @IBAction func refreshButton(_ sender: AnyObject) {
        self.winStreak = 0
        self.startNewWord()
    }
    
    
    //MARK: Gameplay
    
    /**
     Called every time there's a new word
    */
    func startNewWord(){
        soundPlayer.playSound(.start)
        if manager.wordsArray.count <= 0{
            //Something is weird
            //Lets just say they finished the word pack
            self.performSegue(withIdentifier: "finished", sender: self)
            return
        }
        manager.startNewWord()
        //Animate hint label changing
        
        if manager.studyMode{
            //Show study mode hint
            UIView.transition(with: hintButton.titleLabel!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                let titleText = self.manager.chosenMeaning != "" ? "Meaning: " + self.manager.chosenMeaning : ""
                self.hintButton.setTitle(titleText, for: .normal)
                self.hintButton.setTitleColor(UIColor(red: 121/255.0, green: 121/255.0, blue: 121/255.0, alpha: 1.0), for: .normal)
                self.hintButton.isEnabled = false
            }, completion: nil)
        }else{
            self.hintUsed = false
            UIView.transition(with: hintButton.titleLabel!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                self.hintButton.setTitle("", for: .normal)
            }, completion: nil)
        }
        
        self.winsButton.setTitle("\(QTRomanNumerals.convertToRomanNum(decimalNum: self.winStreak))", for: UIControlState())
        if self.winStreak == 0 {self.winsButton.setTitle("0", for: UIControlState())}
        
        self.refreshWord() //word should be blank
        
        
        self.distanceFromPerson.constant = -8 //put sword in first position
        stage = 0
        
        for i in 0 ..< letterButtons.count {
            let button = letterButtons[i]
            let index = manager.remaining.index(manager.remaining.startIndex, offsetBy: i)
            button.setTitle(String(manager.remaining[index]), for: UIControlState())
        }
        
    }
    
    @objc func guessLetter(_ sender:UIButton){
        let letter = sender.titleLabel?.text
        tryLetter(letter: letter!)
        sender.setTitle(" ", for: UIControlState())
    }
    
    private func tryLetter(letter: String){
        if manager.guessLetter(letter: letter){
            soundPlayer.playSound(.correct)
            self.refreshWord()
        }else{
            soundPlayer.playSound(.incorrect)
            self.wrongLetter()
        }
    }
    
    func refreshWord(){
        let (word, finished) = manager.refreshWord()
        self.wordLabel.attributedText = word
        if finished{
            self.win()
        }
    }
    
    func wrongLetter(){
        stage += 1
        if stage <= 6{
            UIView.animate(withDuration: 0.5, animations: {
                self.distanceFromPerson.constant = self.swordLocs[self.stage - 1] //move sword toward sheep
                self.view.layoutIfNeeded()
                if self.stage >= 3 && !self.manager.studyMode && !self.hintUsed{
                    //Show hint button
                    UIView.transition(with: self.hintButton.titleLabel!, duration: 1.0, options: .transitionCrossDissolve, animations: {
                        self.hintButton.setTitle("Get hint?", for: .normal)
                        self.hintButton.setTitleColor(UIColor.AgniColors.Red, for: .normal)
                        self.hintButton.isEnabled = true
                    }, completion: nil)
                }
            })
        } else{
            //Game lost
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            soundPlayer.playSound(.lose)
            self.winning = false
            self.winStreak = 0
            
            self.performSegue(withIdentifier: "loss", sender: self) //show lost screen
            self.achivementManager.loss()
        }
        
    }
    
    func win(){
        soundPlayer.playSound(.win)
        if stage == 0{
            self.correctLabel.text = "PERFECT!!"
        }else{
            self.correctLabel.text = "CORRECT!"
        }
        UIView.animate(withDuration: 0.3, animations: {
            self.correctLabel.alpha = 1.0
            }, completion: {
                finished in
                UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: {
                    self.correctLabel.alpha = 0.0
                    }, completion: {
                        finished in
                        if self.manager.completedWord(){
                            self.performSegue(withIdentifier: "finished", sender: self)
                        }else{
                            //Otherwise, save what we have and start a new word
                            self.manager.saveRemaining()
                            self.startNewWord()
                        }
                        
                        //Streak stuff
                        if !self.defaults.bool(forKey: "customListUsed"){
                            //Update streak
                            if self.winning{
                                self.winStreak += 1
                            }else{
                                self.winStreak = 1
                            }
                            if self.winStreak > self.defaults.integer(forKey: "longest_streak"){
                                self.achivementManager.higherWinStreak(self.winStreak)
                            }
                            self.winning = true
                            
                            //stuff for achievements
                            self.achivementManager.win()
                            
                        }
                        
                })
        })
        
    }
    
    @IBAction func getHint(_ sender: Any) {
        let alert:UIAlertController
        let confirmAction:UIAlertAction
        if hintManager.hintsRemaining > 0{
            alert = UIAlertController(title: "Use one hint?", message: "You have \(hintManager.hintsRemaining) hint\(hintManager.hintsRemaining == 1 ? "" : "s").", preferredStyle: .alert)
            confirmAction = UIAlertAction(title: "Use hint", style: .default) { (_) in
                self.hintManager.hintsRemaining -= 1
                self.hintUsed = true
                self.hintButton.setTitle("", for: .normal)
                self.hintButton.isEnabled = false
                if self.manager.chosenMeaning == ""{
                    //Give a free letter
                    self.tryLetter(letter: self.manager.getRemainingLetter())
                }else{
                    //give the meaning
                    UIView.transition(with: self.hintButton, duration: 0.7, options: .transitionCrossDissolve, animations: {
                        self.hintButton.setTitle("Hint: \(self.manager.chosenMeaning)", for: .normal)
                        self.hintButton.setTitleColor(UIColor.AgniColors.Green, for: .normal)
                    }, completion: nil)
                    
                }
            }
        }else{
            alert = UIAlertController(title: "Use one hint?", message: "You're all out of hints!", preferredStyle: .alert)
            confirmAction = UIAlertAction(title: "Get more", style: .default, handler: { (_) in
                self.hintManager.buy()
            })
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func paymentBegun() {
        //show payment on screen
    }
    
    func paymentEnded(successful: Bool) {
        
    }
    
    //MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.lastSegue = segue
        if segue.identifier == "loss"{
            let toViewController = segue.destination as! LossViewController
            toViewController.transitioningDelegate = self
            toViewController.word = manager.chosenWord //loss screen will tell the user the word
        }else if segue.identifier == "finished"{
            let toViewController = segue.destination as! FinishedViewController
            toViewController.transitioningDelegate = self
        }else if segue.identifier == "stats"{
            let toViewController = segue.destination as! StatsViewController
            toViewController.transitioningDelegate = self
        }else if segue.identifier == "showMenu"{
            let toViewController = segue.destination as! MenuViewController
            toViewController.transitioningDelegate = self
            toViewController.interactor = svinteractor
        }
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 1.0)]
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
        case "showMenu":
            return MenuSwingTransition(button: menuButton)
        default:
            return nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let segue = self.lastSegue else{return nil}
        
        switch segue.identifier!{
        case "stats":
            return ReverseCircleTransition(button: winsButton)
        case "showMenu":
            return ReverseMenuSlideTransition()
        default:
            return nil
        }
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return svinteractor.hasStarted ? svinteractor : nil
    }
}
