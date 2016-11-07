//
//  Achievements.swift
//  Agni
//
//  Created by Michael Ginn on 12/26/15.
//  Copyright © 2015 Michael Ginn. All rights reserved.
//

import UIKit
import GameKit

class Achievements: NSObject {
    var defaults = UserDefaults.standard //use to get app-wide data
    var streak = 0
    var totalWins = 0
    var totalLosses = 0
    
    override init(){
        totalWins = self.defaults.integer(forKey: "win_total")
        totalLosses = self.defaults.integer(forKey: "loss_total")
    }
    
    func win(){
        //incremement wins and save to defaults
        totalWins += 1
        self.defaults.set(totalWins, forKey: "win_total")
        DispatchQueue.main.async(execute: {
            //save in the background
            self.defaults.synchronize()
            self.checkWinsAchievements()
        })
        
        //Report to leaderboard
        let score = GKScore(leaderboardIdentifier: "total_wins")
        score.value = Int64(totalWins)
        GKScore.report([score], withCompletionHandler: {
            error in
            if error != nil{
                NSLog(error!.localizedDescription)
            }
        })
    }
    
    
    func loss(){
        totalLosses += 1
        self.defaults.set(totalLosses, forKey: "loss_total")
        DispatchQueue.main.async(execute: {
            //save in the background
            self.defaults.synchronize()
            self.checkLossesAchievements()
        })
    }
    
    func higherWinStreak(_ streak:Int){
        self.defaults.set(streak, forKey: "longest_streak")
    }
    
    func checkWinsAchievements(){
        totalWins = self.defaults.integer(forKey: "win_total")
        
        var achievements:[GKAchievement] = []
        
        if totalWins == 1{
            let firstWinAchievement = GKAchievement(identifier: "first_win")
            firstWinAchievement.percentComplete = 100.0
            firstWinAchievement.showsCompletionBanner = true
            achievements.append(firstWinAchievement)
        }
        if totalWins <= 5{
            let fiveWinsAchievement = GKAchievement(identifier: "five_wins")
            fiveWinsAchievement.percentComplete = (Double(totalWins) / 5.0) * 100
            fiveWinsAchievement.showsCompletionBanner = true
            achievements.append(fiveWinsAchievement)
        }
        if totalWins <= 10{
            let tenWinsAchievement = GKAchievement(identifier: "ten_wins")
            tenWinsAchievement.percentComplete = (Double(totalWins) / 10.0) * 100
            tenWinsAchievement.showsCompletionBanner = true
            achievements.append(tenWinsAchievement)
        }
        if totalWins <= 50{
            let fiftyWinsAchievement = GKAchievement(identifier: "fifty_wins")
            fiftyWinsAchievement.percentComplete = (Double(totalWins) / 50.0) * 100
            fiftyWinsAchievement.showsCompletionBanner = true
            achievements.append(fiftyWinsAchievement)
        }
        if totalWins <= 100{
            let onehundredWinsAchievement = GKAchievement(identifier: "one_hundred_wins")
            onehundredWinsAchievement.percentComplete = (Double(totalWins) / 100.0) * 100
            onehundredWinsAchievement.showsCompletionBanner = true
            achievements.append(onehundredWinsAchievement)
        }
        if totalWins <= 500{
            let fivehundredWinsAchievement = GKAchievement(identifier: "five_hundred_wins")
            fivehundredWinsAchievement.percentComplete = (Double(totalWins) / 500.0) * 100
            fivehundredWinsAchievement.showsCompletionBanner = true
            achievements.append(fivehundredWinsAchievement)
        }
        if totalWins <= 1000{
            let thousandWinsAchievement = GKAchievement(identifier: "one_thousand_wins")
            thousandWinsAchievement.percentComplete = (Double(totalWins) / 1000.0) * 100
            thousandWinsAchievement.showsCompletionBanner = true
            achievements.append(thousandWinsAchievement)
        }
        GKAchievement.report(achievements, withCompletionHandler: {error in
            if error != nil{
                NSLog("%@", (error?.localizedDescription)!)
            }
        })
    }
    func checkLossesAchievements(){
        totalLosses = self.defaults.integer(forKey: "loss_total")
        var achievements:[GKAchievement] = []
        
        if totalLosses == 1{
            let firstLossAchievment = GKAchievement(identifier: "first_loss")
            firstLossAchievment.percentComplete = 100.0
            firstLossAchievment.showsCompletionBanner = true
            achievements.append(firstLossAchievment)
        }
        if totalLosses <= 10{
            let tenLossesAchievement = GKAchievement(identifier: "ten_losses")
            tenLossesAchievement.percentComplete = (Double(totalLosses) / 10.0) * 100
            tenLossesAchievement.showsCompletionBanner = true
            achievements.append(tenLossesAchievement)
        }
        if totalLosses <= 100{
            let onehundredLossesAchievement = GKAchievement(identifier: "one_hundred_losses")
            onehundredLossesAchievement.percentComplete = (Double(totalLosses) / 100.0) * 100
            onehundredLossesAchievement.showsCompletionBanner = true
            achievements.append(onehundredLossesAchievement)
        }
        GKAchievement.report(achievements, withCompletionHandler: {error in
            if error != nil{
                NSLog("%@", (error?.localizedDescription)!)
            }
        })
    }
    
    func checkSkinsAchievements(_ numberOfSkins:Int){
        var achievements:[GKAchievement] = []
        
        if numberOfSkins <= 2{
            let firstSkinAchievement = GKAchievement(identifier: "first_skin")
            firstSkinAchievement.percentComplete = (Double(numberOfSkins - 1) / 1) * 100
            firstSkinAchievement.showsCompletionBanner = true
            achievements.append(firstSkinAchievement)
        }
        if numberOfSkins <= 11{
            let tenSkinsAchievement = GKAchievement(identifier: "ten_skins")
            tenSkinsAchievement.percentComplete = (Double(numberOfSkins - 1) / 10) * 100
            tenSkinsAchievement.showsCompletionBanner = true
            achievements.append(tenSkinsAchievement)
        }
        GKAchievement.report(achievements, withCompletionHandler: {error in
            if error != nil{
                NSLog("%@", (error?.localizedDescription)!)
            }
        })
    }
}
