//
//  GameplayViewController.swift
//  Agni
//
//  Created by Michael Ginn on 1/9/19.
//  Copyright © 2019 Michael Ginn. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

protocol GameplayDelegate{
    func gameWon()
    func gameLost()
    func refreshed()
    func allCompleted()
    func startNewWord()
}

extension GameplayDelegate{
    func refreshed(){}
    func allCompleted(){}
    func startNewWord(){}
}

class GameplayViewController: UIViewController, HintIAPManagerDelegate {
    
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var distanceFromPerson: NSLayoutConstraint!
    @IBOutlet weak var correctLabel: UILabel!
    @IBOutlet weak var sheepImage: UIImageView!
    @IBOutlet weak var sheepImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var swordImage: UIImageView!
    @IBOutlet var letterButtons: [UIButton]!
    @IBOutlet weak var hintButton: UIButton!
    
    private var sceneView:SKView?
    private var scene: AgniScene?
    
    var manager:GameplayManager!
    private var hintManager = HintIAPManager()
    private var hintUsed = false
    private var stage = 0 //goes up to 7, which is death
    private var swordLocs:[CGFloat] = [] //holds all possible positions for the sword
    
    var delegate:GameplayDelegate?
    
    //MARK: Setup methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        sceneView = (view as! SKView)
        
        // setup the letter buttons
        for button in letterButtons{
            button.addTarget(self, action: #selector(GameplayViewController.guessLetter(_:)), for: UIControl.Event.touchUpInside)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadSkin), name: .skinChosen, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadManager), name: .sourceChanged, object: nil)
    }
    
    func load(){
        hintButton.setTitle("", for: .normal)
        manager.reload()
    }
    
    // called in response to something changing and sending a notification
    
    @objc private func loadSkin(){
         self.sheepImage.image = Converter.getCurrentSkinImage()?.resizeToWidth(width: sheepImage.frame.size.width * 2, scale: UIScreen.main.scale)
    }
    
    @objc private func reloadManager(){
        manager.reload()
        startNewWord()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.scene = AgniScene(size: CGSize(width: self.sceneView!.frame.size.width, height: self.sceneView!.frame.size.height))
        self.sceneView?.presentScene(self.scene)
        
        setup()
        startNewWord()
    }
    
    private func setup(){
        //set up the stages for the sword
        let distance = (sheepImage.frame.origin.x - swordImage.frame.width) - swordImage.frame.origin.x
        let increment = distance / 6.0
        var distanceFromPerson = self.distanceFromPerson.constant
        
        for _ in 1...6 { //six stages of location for the sword
            distanceFromPerson += increment //add to the location
            swordLocs.append(distanceFromPerson)
        }
    }
    
    //MARK: Gameplay Methods
    
    private func startNewWord(){
        GameSounds.standard.playSound(.start)
        delegate?.startNewWord()
        
        if manager.allWordsCompleted(){
            delegate?.allCompleted()
            return
        }
        
        manager.startNewWord()
        if manager.studyMode{
            //Show study mode hint
            UIView.transition(with: hintButton.titleLabel!, duration: 0.5, options: .transitionCrossDissolve, animations: {
                let titleText = self.manager.chosenMeaning != nil && self.manager.chosenMeaning != "" ? "Meaning: " + self.manager.chosenMeaning! : ""
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
        
        refreshWord()
        self.distanceFromPerson.constant = -8 //put sword in first position
        stage = 0
        
        for i in 0 ..< letterButtons.count {
            let button = letterButtons[i]
            let index = manager.remaining.index(manager.remaining.startIndex, offsetBy: i)
            button.setTitle(String(manager.remaining[index]), for: UIControl.State())
        }
    }
    
    private func tryLetter(letter: String){
        if manager.guessLetter(letter: letter){
            GameSounds.standard.playSound(.correct)
            self.refreshWord()
        }else{
            GameSounds.standard.playSound(.incorrect)
            self.wrongLetter()
        }
    }
    
    /**
     Rebuilds the word considering the guessed letters
     */
    private func refreshWord(){
        let (word, finished) = manager.refreshWord()
        self.wordLabel.attributedText = word
        if finished{
            self.win()
        }
    }
    
    func win(){
       GameSounds.standard.playSound(.win)
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
                
                self.delegate?.gameWon()
                
                if !self.manager.completedWord(){
                    self.manager.saveRemaining()
                }
                self.startNewWord() //will also show finished if all words done
            })
        })
    }
    
    func wrongLetter(){
        stage += 1
        if stage <= 6{
            UIView.animate(withDuration: 0.5, animations: {
                self.distanceFromPerson.constant = self.swordLocs[self.stage - 1] //move sword toward sheep
                self.view.layoutIfNeeded()
                if self.stage >= 4 && !self.manager.studyMode && !self.hintUsed{
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
            GameSounds.standard.playSound(.lose)
            
            delegate?.gameLost()
        }
        
    }
    
    //MARK: Interface Methods
    
    @IBAction func refreshButton(_ sender: AnyObject) {
        delegate?.refreshed()
        self.startNewWord()
    }
    
    @objc func guessLetter(_ sender:UIButton){
        let letter = sender.titleLabel?.text
        tryLetter(letter: letter!)
        sender.setTitle(" ", for: UIControl.State())
    }
    
    @IBAction func getHint(_ sender: Any) {
        let alert:UIAlertController
        let confirmAction:UIAlertAction
        if AgniDefaults.hintsRemaining > 0{
            alert = UIAlertController(title: "Use one hint?", message: "You have \(AgniDefaults.hintsRemaining) hint\(AgniDefaults.hintsRemaining == 1 ? "" : "s").", preferredStyle: .alert)
            confirmAction = UIAlertAction(title: "Use hint", style: .default) { (_) in
                AgniDefaults.hintsRemaining -= 1
                self.hintUsed = true
                self.hintButton.setTitle("", for: .normal)
                self.hintButton.isEnabled = false
                if self.manager.chosenMeaning == ""{
                    //Give a free letter
                    let letter = self.manager.getRemainingLetter()
                    self.tryLetter(letter: letter)
                    for button in self.letterButtons{
                        if button.title(for: .normal) == letter {button.setTitle(" ", for: .normal)}
                    }
                }else{
                    //give the meaning
                    UIView.transition(with: self.hintButton, duration: 0.7, options: .transitionCrossDissolve, animations: {
                        self.hintButton.setTitle("Hint: \(self.manager.chosenMeaning ?? "")", for: .normal)
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
        
    }
    
    func paymentEnded(successful: Bool) {
        
    }
}
