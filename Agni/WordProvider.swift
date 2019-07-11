//
//  WordProvider.swift
//  Agni
//
//  Created by Michael Ginn on 12/18/18.
//  Copyright © 2018 Michael Ginn. All rights reserved.
//

import Foundation

protocol WordProvider {
    func getAllWordsAndMeanings()->[WordPair]
    func wordCompleted(word:String)
    func getNextWordAndMeaning()->WordPair
    func allWordsCompleted()->Bool
    func saveRemaining()
    func reload()
    var studyMode:Bool {get}
}

extension WordProvider{
    func saveRemaining(){
        
    }
}
