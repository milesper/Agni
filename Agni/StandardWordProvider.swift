//
//  StandardWordProvider.swift
//  Agni
//
//  Created by Michael Ginn on 12/28/18.
//  Copyright © 2018 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class StandardWordProvider: NSObject, WordProvider {
    var wordPairs:[WordPair] = []
    
    override init(){
        studyMode = false
        super.init()
        reload()
    }
    
    func reload(){
        studyMode = AgniDefaults.studyModeOn
        if AgniDefaults.selectedTitle != ""{ //this will be changed by the selected titles screen
            let (wordsArray, meaningsArray) = Converter.getCurrentWordsArray() // Concats the lists
            for index in 0..<wordsArray.count{
                wordPairs.append(WordPair(word: wordsArray[index], meaning:meaningsArray[index]))
            }
        }
    }
    
    func getAllWordsAndMeanings() -> [WordPair] {
        return wordPairs
    }
    
    /**
     Removes word from array
     */
    func wordCompleted(word: String) {
        if let index = wordPairs.firstIndex(where: { (pair) -> Bool in
            return pair.word == word
        }){
            wordPairs.remove(at: index)
        }
    }
    
    /**
    Returns a random word and meaning
     */
    func getNextWordAndMeaning() -> WordPair {
        let randomIndex = Int(arc4random_uniform(UInt32(self.wordPairs.count))) //choose a random word from the list
        return self.wordPairs[randomIndex]
    }
    
    /**
     Returns true if there are no words remaining in the list
     */
    func allWordsCompleted() -> Bool {
        return wordPairs.count == 0
    }
    
    var studyMode: Bool
    
    func saveRemaining(){
        //Save the remaining words
        var wordsArray:[String] = []
        for pair in wordPairs{
            wordsArray.append(pair.word)
        }
        
        if AgniDefaults.selectedTitle == "Latin Starter Pack"{
            defaults.set(wordsArray, forKey: "latinSPRemaining")
        }else if AgniDefaults.selectedTitle == "English Starter Pack"{
            defaults.set(wordsArray, forKey: "englishSPRemaining")
        }else{
            //Find the core data entry
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList") //get the list of lists
            
            let predicate = NSPredicate(format: "title == %@", AgniDefaults.selectedTitle)
            fetchRequest.predicate = predicate
            do {
                let results = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
                guard let list = results.first else{return}
                let wordsData = NSKeyedArchiver.archivedData(withRootObject: wordsArray)
                list.setValue(wordsData, forKey: "remaining_words")
                try managedContext.save()
            }catch let error1 as NSError {
                print("%@", error1)
                
            }
        }
        print("Saved remaining")
    }
}
