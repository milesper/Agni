//
//  GameSounds.swift
//  Agni
//
//  Created by Michael Ginn on 5/27/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//
//  Use this to play sounds from other classes

import UIKit
import AVFoundation

// TODO: Make singleton

class GameSounds: NSObject {
    var defaults = UserDefaults.standard //use to get app-wide data
    
    enum gameSound{
        case correct
        case incorrect
        case start
        case win
        case lose
    }
    enum bgMusicToggle{
        case on
        case off
    }

    var correctSound =  URL(fileURLWithPath: Bundle.main.path(forResource: "correctSound", ofType: "wav")!)
    var incorrectSound =  URL(fileURLWithPath: Bundle.main.path(forResource: "incorrectSound", ofType: "wav")!)
    var startSound =  URL(fileURLWithPath: Bundle.main.path(forResource: "lightgong", ofType: "aif")!)
    var loseSound = URL(fileURLWithPath: Bundle.main.path(forResource: "loss", ofType: "wav")!)
    var winSound = URL(fileURLWithPath: Bundle.main.path(forResource: "win", ofType: "wav")!)
    
    var backgroundMusic = URL(fileURLWithPath: Bundle.main.path(forResource: "BackgroundMusic", ofType: "m4a")!)

    
    var startAudioPlayer = AVAudioPlayer()
    var correctAudioPlayer = AVAudioPlayer()
    var incorrectAudioPlayer = AVAudioPlayer()
    var lossAudioPlayer = AVAudioPlayer()
    var winAudioPlayer = AVAudioPlayer()
    
    var backgroundMusicPlayer = AVAudioPlayer()
    
    override init(){
        do{
        startAudioPlayer = try AVAudioPlayer(contentsOf: startSound)
        }catch _{
            print("\nError occurred with sounds")
        }
        startAudioPlayer.prepareToPlay()
        
        do{
        correctAudioPlayer = try AVAudioPlayer(contentsOf: correctSound)
        }catch _{
            print("\nError occurred with sounds")
        }
        correctAudioPlayer.prepareToPlay()
        
        do{
        incorrectAudioPlayer = try AVAudioPlayer(contentsOf: incorrectSound)
        }catch _{
            print("\nError occurred with sounds")
        }
        incorrectAudioPlayer.prepareToPlay()
        
        do{
        lossAudioPlayer = try AVAudioPlayer(contentsOf: loseSound)
        }catch _{
            print("\nError occurred with sounds")
        }
        lossAudioPlayer.prepareToPlay()
        
        do{
        winAudioPlayer = try AVAudioPlayer(contentsOf: winSound)
        }catch _{
            print("\nError occurred with sounds")
        }
        winAudioPlayer.prepareToPlay()
        
        do{
        backgroundMusicPlayer = try AVAudioPlayer(contentsOf: backgroundMusic)
        }catch _{
            print("\nError occurred with sounds")
        }
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.volume = 0.1
        backgroundMusicPlayer.prepareToPlay()
    }

    func playSound(_ sound:gameSound){
        switch sound{
        case .correct:
            correctAudioPlayer.stop()
            correctAudioPlayer.volume = 1.0
            correctAudioPlayer.play()
        case .incorrect:
            incorrectAudioPlayer.stop()
            incorrectAudioPlayer.volume = 1.0
            incorrectAudioPlayer.play()
        case .start:
            startAudioPlayer.volume = 1.0
            startAudioPlayer.play()
        case .lose:
            lossAudioPlayer.volume = 1.0
            lossAudioPlayer.play()
        case .win:
            winAudioPlayer.volume = 1.0
            winAudioPlayer.play()
        }
    }
    
    func toggleBGMusic(){
        if backgroundMusicPlayer.isPlaying{
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.ambient)))
            } catch _ {
            }
            backgroundMusicPlayer.pause()
            self.defaults.set(false, forKey: "musicOn")
        } else{
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: convertFromAVAudioSessionCategory(AVAudioSession.Category.soloAmbient)))
            } catch _ {
            }
            backgroundMusicPlayer.play()
            self.defaults.set(true, forKey: "musicOn")
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
