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
    var chosenMeaning:String? = nil
//    var wordsArray:[String] = [] //will change depending on input
//    var meaningsArray:[String?] = [] //should be nil for any without meaning
    var remaining:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    var wordProvider:WordProvider
    
    var studyMode:Bool = false;
    var defaults = UserDefaults.standard
    
    /**
        Gets the current list of words, toggles study mode
     */
    init(provider:WordProvider) {
        wordProvider = provider
        super.init()
        self.reload()
    }
    
    /**
     Loads the current word list, should be called when word list changes
     */
    func reload(){
        wordProvider.reload()
        //let pairs = wordProvider.getAllWordsAndMeanings()
        studyMode = wordProvider.studyMode
    }
    
    /**
     Begins a new word from the current word list.
     */
    func startNewWord(){
        let nextPair = wordProvider.getNextWordAndMeaning()
        self.chosenWord = nextPair.word
        self.chosenMeaning = nextPair.meaning
        print("\(chosenWord.uppercased())")
        
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
                finalString.append(NSAttributedString(string: "\(letter)", attributes: [NSAttributedString.Key.underlineStyle:NSUnderlineStyle.single.rawValue]))
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
//        let index = self.wordsArray.index(of: self.chosenWord)!
//        self.wordsArray.remove(at: index)
//        self.meaningsArray.remove(at: index)
        wordProvider.wordCompleted(word: chosenWord)
        return allWordsCompleted()
    }
    
    /**
     Returns true if all words have been completed.
     */
    func allWordsCompleted()->Bool{
        return wordProvider.allWordsCompleted()
    }
    
    func saveRemaining(){
        wordProvider.saveRemaining()
    }
    
}
