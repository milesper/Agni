//
//  StatsViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/7/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit

class StatsViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statsView: UIView!
    
    @IBOutlet weak var totalWins: UILabel!
    @IBOutlet weak var bestStreak: UILabel!
    @IBOutlet weak var percentage: UILabel!
    @IBOutlet weak var daysPlayed: UILabel!
    @IBOutlet weak var skinsUsed: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpStats()
    }
    
    func setUpStats(){
        // Do any additional setup after loading the view.
        
        // just a check in case you have the old thing for some reason
        if UserDefaults.standard.object(forKey: "total_wins") != nil{
            AgniDefaults.winTotal = UserDefaults.standard.integer(forKey: "total_wins")
        }
        
        let totalWinNumber = QTRomanNumerals.convertToRomanNum(decimalNum: AgniDefaults.winTotal)
        
        totalWins.text = "\(totalWinNumber)"
        
        //Best streak
        let bestStreakNumber:String
        if AgniDefaults.longestStreak == 0{
            bestStreakNumber = "-"
        }else{
            bestStreakNumber = QTRomanNumerals.convertToRomanNum(decimalNum: AgniDefaults.longestStreak)
        }
        bestStreak.text = "\(bestStreakNumber)"
        
        //Percent wins
        let totalGames = AgniDefaults.winTotal + AgniDefaults.lossTotal
        let percentageValue = Float(AgniDefaults.winTotal) / Float(totalGames)
        if !percentageValue.isNaN{
            percentage.text = String(format: "%.1f", percentageValue * 100) + "%"
        }else{
            percentage.text = "-"
        }
        
        //Skins used
        let numberOfSkinsUsed = AgniDefaults.usedSkins.count
        skinsUsed.text = QTRomanNumerals.convertToRomanNum(decimalNum: numberOfSkinsUsed)
        
        //Days played
        let daysPlayedNumber = AgniDefaults.daysPlayed
        daysPlayed.text = QTRomanNumerals.convertToRomanNum(decimalNum: daysPlayedNumber)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func close(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    
}
