//
//  AgniDefaults.swift
//  Agni
//
//  Created by Michael Ginn on 12/15/19.
//  Copyright © 2019 Michael Ginn. All rights reserved.
//

import Foundation

struct AgniDefaults {
    @UserDefault(key: "selectedTitle", defaultValue: "")
    static var selectedTitle: String
    
    @UserDefault(key: "skinsUnlocked", defaultValue: false)
    static var skinsUnlocked: Bool
    
    @UserDefault(key: "currentSkin", defaultValue: Constants.DEFAULT_SKIN_NAME)
    static var currentSkin: String
    
    @UserDefault(key: "needsUpdateSources", defaultValue: true)
    static var needsUpdateSources: Bool
    
    @UserDefault(key: "beatenWordLists", defaultValue: [])
    static var beatenWordLists: [String]
    
    @UserDefault(key: "lastVersionShown", defaultValue: "")
    static var lastVersionShown: String
    
    // stats
    @UserDefault(key: "win_total", defaultValue: 0)
    static var winTotal: Int
    
    @UserDefault(key: "win_streak", defaultValue: 0)
    static var winStreak: Int
    
    @UserDefault(key: "longest_streak", defaultValue: 0)
    static var longestStreak: Int
    
    @UserDefault(key: "loss_total", defaultValue: 0)
    static var lossTotal: Int
    
    @UserDefault(key: "days_played", defaultValue: 0)
    static var daysPlayed: Int
    
    // other stuff
    @UserDefault(key: "used_skins", defaultValue: [Constants.DEFAULT_SKIN_NAME])
    static var usedSkins: [String]
    
    @UserDefault(key: "hints_remaining", defaultValue: 0)
    static var hintsRemaining: Int
    
    @UserDefault(key: "displayed_popups", defaultValue: 0)
    static var displayedPopups: Int
    
    @UserDefault(key: "last_day_played", defaultValue: "")
    static var lastDayPlayed: String
    
    @UserDefault(key: "musicOn", defaultValue: false)
    static var musicOn: Bool
    
    @UserDefault(key: "customListUsed", defaultValue: false)
    static var customListUsed: Bool
    
    @UserDefault(key: "study_mode_on", defaultValue: false)
    static var studyModeOn: Bool
    
    @UserDefault(key: "latinSPRemaining", defaultValue: nil)
    static var latinStarterPackRemaining: [String]?
    
    @UserDefault(key: "englishSPRemaining", defaultValue: nil)
    static var englishStarterPackRemaining: [String]?
    
    @UserDefault(key: "userCreatedLists", defaultValue: [])
    static var userCreatedListTitles: [String]
}
