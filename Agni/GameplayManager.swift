//
//  GameplayManager.swift
//  Agni
//
//  Created by Michael Ginn on 11/8/17.
//  Copyright © 2017 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class GameplayManager: NSObject {
    var chosenWord:String = ""
    var chosenMeaning:String = ""
    var wordsArray:[String] = [] //will change depending on input
    var meaningsArray:[String?] = [] //should be nil for any without meaning
    var remaining:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    
    
    var studyMode:Bool = false;
    var defaults = UserDefaults.standard
    
    /**
        Gets the current list of words, toggles study mode
     */
    override init() {
        super.init()
        self.reload()
    }
    
    func reload(){
        if defaults.object(forKey:"selectedTitle") != nil{ //this will be changed by the selected titles screen
            (wordsArray, meaningsArray) = Converter.getCurrentWordsArray() // Concats the lists
        }
        studyMode = defaults.bool(forKey: "study_mode_on")
    }
    
    func startNewWord(){
        let randomIndex = Int(arc4random_uniform(UInt32(self.wordsArray.count))) //choose a random word from the list
        self.chosenWord = self.wordsArray[randomIndex]
        print("\(chosenWord.uppercased())")
        
        if let meaning = self.meaningsArray[randomIndex]{
            chosenMeaning = meaning
        }else{
            chosenMeaning = ""
        }
        
        remaining = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
    }
    
    /**
     Guesses a letter and updates the word appropriately
     - Parameter letter: The letter guessed
     - Returns: A boolean indicating true if the letter was in the word
     */
    func guessLetter(letter:String?)->Bool{
        if letter != " "{
            self.remaining = self.remaining.replacingOccurrences(of: letter!, with: " ", options: [], range: nil)
            if self.chosenWord.uppercased().range(of: letter!) != nil{
                return true
            } else{ //letter is not in word
                return false
            }
        }else{
            return false
        }
    }
    
    /**
    Builds the word with whichever letters have or have not been guessed.
     - Returns: A tuple of (the new word, whether it is finished)
     */
    func refreshWord()->(word:NSAttributedString, finished:Bool){
        //Before finishing word
        let finalString:NSMutableAttributedString = NSMutableAttributedString(string: "") //will use to build string
        var finished = true
        for letter in self.chosenWord.uppercased(){
            if !("ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(String(letter))){
                //not a letter
                finalString.append(NSAttributedString(string: "\(letter) "))
            }else if !self.remaining.contains(letter){
                //letter is guessed already
                finalString.append(NSAttributedString(string: "\(letter)", attributes: [NSAttributedStringKey.underlineStyle:NSUnderlineStyle.styleSingle.rawValue]))
                finalString.append(NSAttributedString(string: "  "))
            }else{
                //letter is still unguessed
                finalString.append(NSAttributedString(string: "_  "))
                finished = false
            }
        }
        return (finalString as NSAttributedString, finished)
    }
    
    /**
    Returns a random letter in the word that has not currently been guessed
    */
    func getRemainingLetter()->String{
        var possibleLetters:[String] = []
        for letter in remaining{
            if self.chosenWord.uppercased().range(of: "\(letter)") != nil{
                possibleLetters.append("\(letter)")
            }
        }
        
        guard possibleLetters.count != 0 else{return ""}
        let randomIndex = Int(arc4random_uniform(UInt32(possibleLetters.count)))
        return possibleLetters[randomIndex]
    }
    
    /**
     Removes the word from the words array
     - Returns: A boolean indicating if the list is finished
     */
    func completedWord()->Bool{
        let index = self.wordsArray.index(of: self.chosenWord)!
        self.wordsArray.remove(at: index)
        self.meaningsArray.remove(at: index)
        
        return self.wordsArray.count == 0
    }
    
    func saveRemaining(){
        //Save the remaining words
        let selectedTitle = defaults.value(forKey: "selectedTitle") as! String
        if selectedTitle == "Latin Starter Pack"{
            defaults.set(wordsArray, forKey: "latinSPRemaining")
        }else if selectedTitle == "English Starter Pack"{
            defaults.set(wordsArray, forKey: "englishSPRemaining")
        }else{
            //Find the core data entry
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList") //get the list of lists
            
            let predicate = NSPredicate(format: "title == %@", selectedTitle)
            fetchRequest.predicate = predicate
            do {
                let results = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
                guard let list = results.first else{return}
                let wordsData = NSKeyedArchiver.archivedData(withRootObject: self.wordsArray)
                list.setValue(wordsData, forKey: "remaining_words")
                try managedContext.save()
            }catch let error1 as NSError {
                print("%@", error1)
                
            }
        }
        print("Saved remaining")
    }
}
