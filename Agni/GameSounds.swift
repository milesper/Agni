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

class GameSounds: NSObject {
    var defaults = NSUserDefaults.standardUserDefaults() //use to get app-wide data
    
    enum gameSound{
        case Correct
        case Incorrect
        case Start
        case Win
        case Lose
    }
    enum bgMusicToggle{
        case On
        case Off
    }

    var correctSound =  NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("correctSound", ofType: "wav")!)
    var incorrectSound =  NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("incorrectSound", ofType: "wav")!)
    var startSound =  NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("lightgong", ofType: "aif")!)
    var loseSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("loss", ofType: "wav")!)
    var winSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("win", ofType: "wav")!)
    
    var backgroundMusic = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("BackgroundMusic", ofType: "m4a")!)

    
    var startAudioPlayer = AVAudioPlayer()
    var correctAudioPlayer = AVAudioPlayer()
    var incorrectAudioPlayer = AVAudioPlayer()
    var lossAudioPlayer = AVAudioPlayer()
    var winAudioPlayer = AVAudioPlayer()
    
    var backgroundMusicPlayer = AVAudioPlayer()
    
    override init(){
        do{
        startAudioPlayer = try AVAudioPlayer(contentsOfURL: startSound)
        }catch _{
            print("\nError occurred with sounds")
        }
        startAudioPlayer.prepareToPlay()
        
        do{
        correctAudioPlayer = try AVAudioPlayer(contentsOfURL: correctSound)
        }catch _{
            print("\nError occurred with sounds")
        }
        correctAudioPlayer.prepareToPlay()
        
        do{
        incorrectAudioPlayer = try AVAudioPlayer(contentsOfURL: incorrectSound)
        }catch _{
            print("\nError occurred with sounds")
        }
        incorrectAudioPlayer.prepareToPlay()
        
        do{
        lossAudioPlayer = try AVAudioPlayer(contentsOfURL: loseSound)
        }catch _{
            print("\nError occurred with sounds")
        }
        lossAudioPlayer.prepareToPlay()
        
        do{
        winAudioPlayer = try AVAudioPlayer(contentsOfURL: winSound)
        }catch _{
            print("\nError occurred with sounds")
        }
        winAudioPlayer.prepareToPlay()
        
        do{
        backgroundMusicPlayer = try AVAudioPlayer(contentsOfURL: backgroundMusic)
        }catch _{
            print("\nError occurred with sounds")
        }
        backgroundMusicPlayer.numberOfLoops = -1
        backgroundMusicPlayer.volume = 0.1
        backgroundMusicPlayer.prepareToPlay()
    }

    func playSound(sound:gameSound){
        switch sound{
        case .Correct:
            correctAudioPlayer.stop()
            correctAudioPlayer.volume = 1.0
            correctAudioPlayer.play()
        case .Incorrect:
            incorrectAudioPlayer.stop()
            incorrectAudioPlayer.volume = 1.0
            incorrectAudioPlayer.play()
        case .Start:
            startAudioPlayer.volume = 1.0
            startAudioPlayer.play()
        case .Lose:
            lossAudioPlayer.volume = 1.0
            lossAudioPlayer.play()
        case .Win:
            winAudioPlayer.volume = 1.0
            winAudioPlayer.play()
        }
    }
    
    func toggleBGMusic(){
        if backgroundMusicPlayer.playing{
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient)
            } catch _ {
            }
            backgroundMusicPlayer.pause()
            self.defaults.setBool(false, forKey: "musicOn")
        } else{
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
            } catch _ {
            }
            backgroundMusicPlayer.play()
            self.defaults.setBool(true, forKey: "musicOn")
        }
        
        let time = dispatch_time(DISPATCH_TIME_NOW, 0)
        dispatch_after(time, dispatch_get_main_queue(), {
            //save in the background
            self.defaults.synchronize()
        })
    }
}
