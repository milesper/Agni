//
//  AgniViewController.swift
//  
//
//  Created by Michael Ginn on 5/2/15.
//
//

import UIKit
import AVFoundation

class AgniViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIViewControllerTransitioningDelegate {
    //interface components
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var distanceFromPerson: NSLayoutConstraint!
    @IBOutlet weak var correctLabel: UILabel!
    @IBOutlet weak var sheepImage: UIImageView!
    @IBOutlet weak var swordImage: UIImageView!
    @IBOutlet weak var lettersCollectionView: UICollectionView!
    @IBOutlet weak var winsLabel: UILabel!
    @IBOutlet weak var volumeButton: UIButton!
    
    var chosenWord = ""
    var wordsArray:[String] = [] //will change depending on input
    var remaining:[Character] = [] //unguessed letters
    var stage = 0 //goes up to 7, which is death
    var swordLocs:[CGFloat] = [] //holds all possible positions for the sword
    var needsRefresh = false //will be true when a game is finished
    var wins = 0 //update after each win
    var defaults = NSUserDefaults.standardUserDefaults() //use to get app-wide data
    
    var soundPlayer = GameSounds()
    var musicOn = true
    var musicStarted = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if defaults.objectForKey("selectedTitles") != nil{ //this will be changed by the selected titles screen
            
            self.wordsArray = Converter.getWordsArray() // Get the data out of the text file
        }
        
        self.needsRefresh = true //will get a word, update interface components

        
    }
    
    override func viewDidAppear(animated: Bool) {
        if defaults.objectForKey("selectedTitles") == nil{ //this will be changed by the selected titles screen
            self.performSegueWithIdentifier("showWelcome", sender: self)
            
        }else{
            self.wordsArray = Converter.getWordsArray() //get the data since we skipped it at load
            self.setup()
        }
    }
    
    func setup(){
        if !musicStarted{
            if defaults.objectForKey("musicOn") == nil{
                defaults.setBool(true, forKey: "musicOn")
                defaults.synchronize()
            }
            if (defaults.objectForKey("musicOn") as! Bool){
                self.soundPlayer.toggleBGMusic()
            }else{
                self.volumeButton.setBackgroundImage(UIImage(named: "mute.png"), forState: .Normal)
                self.musicOn = false
            }
            musicStarted = true
        }
        
        //set up the stages for the sword
        let distance = (sheepImage.frame.origin.x - swordImage.frame.width) - swordImage.frame.origin.x
        let increment = distance / 6.0
        var distanceFromPerson = self.distanceFromPerson.constant
        
        for index in 1...6 { //six stages of location for the sword
            distanceFromPerson += increment //add to the location
            swordLocs.append(distanceFromPerson)
        }
        
        
        self.winsLabel.text = "Wins: \(self.wins)"
        
        if needsRefresh{ //reset all values, the game was finished
            self.restart()
        }
        if (defaults.valueForKey("needsUpdateSources") as! Bool){ //user has changed which lists are used
            self.wordsArray = Converter.getWordsArray()
            defaults.setObject(false, forKey: "needsUpdateSources")
            defaults.synchronize()
            self.restart()
        }

    }

    @IBAction func toggleMusic(sender: UIButton) {
        soundPlayer.toggleBGMusic()
        if self.musicOn{
            sender.setBackgroundImage(UIImage(named: "mute.png"), forState: .Normal)
        } else{
            sender.setBackgroundImage(UIImage(named: "sound.png"), forState: .Normal)
        }
        self.musicOn = !self.musicOn
    }
    @IBAction func refreshButton(sender: AnyObject) {
        self.restart()
    }
    func restart(){
        
        soundPlayer.playSound(.Start)
        let randomIndex = Int(arc4random_uniform(UInt32(self.wordsArray.count))) //choose a random word from the list
        self.chosenWord = self.wordsArray[randomIndex].uppercaseString
        NSLog("\(chosenWord)")
        
        self.remaining = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        self.refreshWord() //word should be blank
        
        self.distanceFromPerson.constant = -8 //put sword in first position
        stage = 0
        
        lettersCollectionView.reloadData()
        
        needsRefresh = false
    }
    

    func refreshWord(){
        var finalString:NSMutableAttributedString = NSMutableAttributedString(string: "") //will use to build string
        var finished = true
        for letter in self.chosenWord{
            if !contains(self.remaining, letter){
                //letter is guessed already
                finalString.appendAttributedString(NSAttributedString(string: "\(letter)", attributes: [NSUnderlineStyleAttributeName:NSUnderlineStyle.StyleSingle.rawValue]))
                finalString.appendAttributedString(NSAttributedString(string: "  "))
            } else{
                //letter is still unguessed
                finalString.appendAttributedString(NSAttributedString(string: "_  "))
                finished = false
            }
        }
        self.wordLabel.attributedText = finalString as NSAttributedString
        if finished{ //user has won
            soundPlayer.playSound(.Win)
            UIView.animateWithDuration(0.3, animations: {
                self.correctLabel.alpha = 1.0
                }, completion: {
                    finished in
                    UIView.animateWithDuration(0.5, delay: 1.0, options: nil, animations: {
                        self.correctLabel.alpha = 0.0
                        }, completion: {
                            finished in
                            self.needsRefresh = true //restart
                            self.wins++
                            self.viewDidAppear(true)
                    })
            })
            
        }
    }
    
    func wrongLetter(){
        stage++
        if stage <= 6{
        UIView.animateWithDuration(0.5, animations: {
            self.distanceFromPerson.constant = self.swordLocs[self.stage - 1] //move sword toward sheep
            self.view.layoutIfNeeded()
        })
        } else{
            soundPlayer.playSound(.Lose)
            self.performSegueWithIdentifier("loss", sender: self) //show lost screen
            self.needsRefresh = true
        }
        
    }
    
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.remaining.count //will always be 26, some may be space characters
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("letterCell", forIndexPath: indexPath) as! LetterCollectionViewCell
            cell.label.text = String(self.remaining[indexPath.row]) //show a letter or a blank space

        
        let backgroundView = UIView(frame: CGRectMake(0, 0, cell.contentView.frame.width, cell.contentView.frame.height))
        backgroundView.backgroundColor = UIColor(red: 114/255.0, green: 191/255.0, blue: 125/255.0, alpha: 1.0)

        cell.selectedBackgroundView = backgroundView
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        var cell = collectionView.dequeueReusableCellWithReuseIdentifier("letterCell", forIndexPath: indexPath) as! LetterCollectionViewCell
        let char = remaining[indexPath.row]
        remaining[indexPath.row] = " " //letter has been used, refresh it
        if contains(self.chosenWord,char){
            soundPlayer.playSound(.Correct)
            self.refreshWord()
        } else if char != " "{ //letter is not in word
            soundPlayer.playSound(.Incorrect)
            self.wrongLetter()
        }
        cell.userInteractionEnabled = false
        collectionView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "loss"{
            let toViewController = segue.destinationViewController as! FinishedViewController
            toViewController.transitioningDelegate = self
            toViewController.word = self.chosenWord //loss screen will tell the user the word
        }
    }
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ShakeTransition()
    }
    
}
