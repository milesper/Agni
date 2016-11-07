//
//  StatsViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/7/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit

class StatsViewController: UIViewController {
    let defaults = UserDefaults.standard //used to save app-wide data
    
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
        let totalWinNumber:String
        if (defaults.integer(forKey: "win_total") == 0) && defaults.object(forKey: "total_wins") != nil{
            totalWinNumber = QTRomanNumerals.convertToRomanNum(decimalNum: defaults.object(forKey: "total_wins") as! Int)
        }else{
            totalWinNumber = QTRomanNumerals.convertToRomanNum(decimalNum: defaults.object(forKey: "win_total") as! Int)
        }
        
        totalWins.text = "\(totalWinNumber)"
        
        //Best streak
        let bestStreakNumber:String
        if defaults.integer(forKey: "longest_streak") == 0{
            bestStreakNumber = "-"
        }else{
            bestStreakNumber = QTRomanNumerals.convertToRomanNum(decimalNum: defaults.object(forKey: "longest_streak") as! Int)
        }
        bestStreak.text = "\(bestStreakNumber)"
        
        //Percent wins
        let totalGames = defaults.integer(forKey: "win_total") + defaults.integer(forKey: "loss_total")
        let percentageValue = (defaults.object(forKey: "win_total") as! Float) / Float(totalGames)
        if !percentageValue.isNaN{
            percentage.text = String(format: "%.1f", percentageValue * 100) + "%"
        }else{
            percentage.text = "-"
        }
        
        //Skins used
        let numberOfSkinsUsed = defaults.array(forKey: "used_skins")?.count
        skinsUsed.text = QTRomanNumerals.convertToRomanNum(decimalNum: numberOfSkinsUsed!)
        
        //Days played
        let daysPlayedNumber = defaults.integer(forKey: "days_played")
        daysPlayed.text = QTRomanNumerals.convertToRomanNum(decimalNum: daysPlayedNumber)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func close(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
