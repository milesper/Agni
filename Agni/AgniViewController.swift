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

class AgniViewController: UIViewController, UIViewControllerTransitioningDelegate {
    //interface components
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var distanceFromPerson: NSLayoutConstraint!
    @IBOutlet weak var correctLabel: UILabel!
    @IBOutlet weak var sheepImage: UIImageView!
    @IBOutlet weak var swordImage: UIImageView!
    @IBOutlet weak var winsButton: UIButton!
    @IBOutlet weak var volumeButton: UIButton!
    @IBOutlet var letterButtons: [UIButton]!
    
    var chosenWord = ""
    var wordsArray:[String] = [] //will change depending on input
    
    var firstTime = false;
    
    var stage = 0 //goes up to 7, which is death
    var swordLocs:[CGFloat] = [] //holds all possible positions for the sword
    var remaining = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    var needsRefresh = false //will be true when a game is finished
    var winStreak = 0 //update after each win
    var winning = false
    var defaults = UserDefaults.standard //use to get app-wide data
    var lastSegue:UIStoryboardSegue?
    
    var soundPlayer = GameSounds()
    var musicOn = true
    var musicStarted = false
    
    var achivementManager = Achievements()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (UIApplication.shared.delegate as! AppDelegate).authenticateLocalPlayer()
        // Do any additional setup after loading the view.
        if defaults.object(forKey: "selectedTitles") != nil{ //this will be changed by the selected titles screen
            
            self.wordsArray = Converter.getCurrentWordsArray() // Get the data out of the text file
        }
        
        self.needsRefresh = true //will get a word, update interface components
        
        for button in letterButtons{
            button.addTarget(self, action: #selector(AgniViewController.guessLetter(_:)), for: UIControlEvents.touchUpInside)
        }
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if defaults.object(forKey: "selectedTitles") == nil{ //this will be changed by the selected titles screen
            self.performSegue(withIdentifier: "showWelcome", sender: self)
            firstTime = true
        }else if  defaults.string(forKey: "lastVersionShown") != "1.3.0" && !firstTime{
            self.performSegue(withIdentifier: "showWhatsNew", sender: self)
        }else{
            self.wordsArray = Converter.getCurrentWordsArray() //get the data since we skipped it at load
            self.setup()
        }
        
        self.sheepImage.image = Converter.getCurrentSkinImage()!
        
    }
    
    func setup(){
        if !musicStarted{
            if defaults.object(forKey: "musicOn") == nil{
                defaults.set(true, forKey: "musicOn")
                defaults.synchronize()
            }
            if (defaults.object(forKey: "musicOn") as! Bool){
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
        
        
        self.winsButton.setTitle("\(QTRomanNumerals.convertToRomanNum(decimalNum: self.winStreak))", for: UIControlState())
        if self.winStreak == 0 {self.winsButton.setTitle("0", for: UIControlState())}
        
        if needsRefresh{ //reset all values, the game was finished
            self.restart()
        }
        if (defaults.value(forKey: "needsUpdateSources") as! Bool){ //user has changed which lists are used
            self.wordsArray = Converter.getCurrentWordsArray()
            defaults.set(false, forKey: "needsUpdateSources")
            defaults.synchronize()
            self.restart()
        }
        
    }
    
    @IBAction func toggleMusic(_ sender: UIButton) {
        soundPlayer.toggleBGMusic()
        if self.musicOn{
            sender.setBackgroundImage(UIImage(named: "mute.png"), for: UIControlState())
        } else{
            sender.setBackgroundImage(UIImage(named: "sound.png"), for: UIControlState())
        }
        self.musicOn = !self.musicOn
    }
    
    @IBAction func refreshButton(_ sender: AnyObject) {
        self.restart()
    }
    
    //MARK: Gameplay
    
    func restart(){
        
        soundPlayer.playSound(.start)
        let randomIndex = Int(arc4random_uniform(UInt32(self.wordsArray.count))) //choose a random word from the list
        self.chosenWord = self.wordsArray[randomIndex]
        NSLog("\(chosenWord.uppercased())")
        
        self.remaining = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        self.refreshWord() //word should be blank
        
        self.distanceFromPerson.constant = -8 //put sword in first position
        stage = 0
        
        for i in 0 ..< letterButtons.count {
            let button = letterButtons[i]
            let index = remaining.characters.index(remaining.startIndex, offsetBy: i)
            button.setTitle(String(self.remaining[index]), for: UIControlState())
        }
        
        needsRefresh = false
    }
    
    func guessLetter(_ sender:UIButton){
        let letter = sender.titleLabel?.text
        if letter != " "{
            self.remaining = self.remaining.replacingOccurrences(of: letter!, with: " ", options: [], range: nil)
            if self.chosenWord.uppercased().range(of: letter!) != nil{
                soundPlayer.playSound(.correct)
                self.refreshWord()
            } else{ //letter is not in word
                soundPlayer.playSound(.incorrect)
                self.wrongLetter()
            }
            sender.setTitle(" ", for: UIControlState())
        }
    }
    
    func refreshWord(){
        let finalString:NSMutableAttributedString = NSMutableAttributedString(string: "") //will use to build string
        var finished = true
        for letter in self.chosenWord.uppercased().characters{
            if !("ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(String(letter))){
                finalString.append(NSAttributedString(string: "\(letter) "))
            }else if !self.remaining.characters.contains(letter){
                //letter is guessed already
                finalString.append(NSAttributedString(string: "\(letter)", attributes: [NSUnderlineStyleAttributeName:NSUnderlineStyle.styleSingle.rawValue]))
                finalString.append(NSAttributedString(string: "  "))
            }else{
                //letter is still unguessed
                finalString.append(NSAttributedString(string: "_  "))
                finished = false
            }
        }
        self.wordLabel.attributedText = finalString as NSAttributedString
        if finished{ //user has won
            self.win()
        }
    }
    
    func wrongLetter(){
        stage += 1
        if stage <= 6{
            UIView.animate(withDuration: 0.5, animations: {
                self.distanceFromPerson.constant = self.swordLocs[self.stage - 1] //move sword toward sheep
                self.view.layoutIfNeeded()
            })
        } else{
            soundPlayer.playSound(.lose)
            self.winning = false
            self.winStreak = 0
            
            self.performSegue(withIdentifier: "loss", sender: self) //show lost screen
            self.needsRefresh = true
            self.achivementManager.loss()
        }
        
    }
    
    func win(){
        soundPlayer.playSound(.win)
        UIView.animate(withDuration: 0.3, animations: {
            self.correctLabel.alpha = 1.0
            }, completion: {
                finished in
                UIView.animate(withDuration: 0.5, delay: 1.0, options: [], animations: {
                    self.correctLabel.alpha = 0.0
                    }, completion: {
                        finished in
                        self.needsRefresh = true //restart
                        
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
                        //show the views again
                        self.viewDidAppear(true)
                })
        })
        
    }
    
    //MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.lastSegue = segue
        if segue.identifier == "loss"{
            let toViewController = segue.destination as! FinishedViewController
            toViewController.transitioningDelegate = self
            toViewController.word = self.chosenWord //loss screen will tell the user the word
        }
        if segue.identifier == "stats"{
            let toViewController = segue.destination as! StatsViewController
            toViewController.transitioningDelegate = self
        }
        if segue.identifier == "showMenu"{
            let toViewController = segue.destination as! MenuViewController
            toViewController.transitioningDelegate = self
        }
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 1.0)]
    }
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let segue = self.lastSegue else{return nil}
        
        switch segue.identifier!{
        case "loss":
            return ShakeTransition()
        case "stats":
            return CircleTransition(button: winsButton)
        case "showMenu":
            return MenuSlideTransition(button: menuButton)
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
}
