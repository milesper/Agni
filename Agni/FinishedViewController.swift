//
//  FinishedViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/30/17.
//  Copyright © 2017 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class FinishedViewController: UIViewController {
    @IBOutlet weak var beatenLabel: UILabel!
    @IBOutlet weak var newSkinLabel: UILabel!
    @IBOutlet weak var newSkinImage: UIImageView!
    
    var selectedTitle:String = ""
    
    enum SkinLoadingError:Error{
        case noSkins
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        selectedTitle = AgniDefaults.selectedTitle
        
        self.beatenLabel.text = "You have beaten the word pack \(selectedTitle)."
        
        if(!AgniDefaults.customListUsed) {
            // dont give hints for a custom list cheater
            HintIAPManager.addHints(50, withDisplay: true)
        }
        
        if selectedTitle == Constants.LATIN_STARTER_PACK{
            latinSPSetup()
        }else if selectedTitle == Constants.ENGLISH_STARTER_PACK{
            englishSPSetup()
        }else{
            otherWordPackSetup()
        }

        //Get the new skin
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Skin") //get the list of skins
        let predicate = NSPredicate(format: "forList == %@", selectedTitle)
        fetchRequest.predicate = predicate
        
        do {
            let results = try managedContext.fetch(fetchRequest)
            if results.count > 0{
                let firstSkin = results[0] as! NSManagedObject
                newSkinImage.image = UIImage(data: firstSkin.value(forKey: "file") as! Data)
                
                if firstSkin.value(forKey: "name") as! String == "huge"{
                    newSkinImage.frame = CGRect(x: 0, y: 0, width: newSkinImage.frame.width * 2, height: newSkinImage.frame.height * 2)
                }
                firstSkin.setValue(true, forKey: "unlocked")
            }else{
                throw SkinLoadingError.noSkins
            }
        } catch let error {
            print(error.localizedDescription)
            newSkinLabel.text = ""
            newSkinLabel.textColor = UIColor.AgniColors.Red
            newSkinImage.image = UIImage()
        }

    }
    
    func latinSPSetup(){
        var latinSPOriginalWords:[String] = [] //Contains all the words
        
        let path = Bundle.main.path(forResource: "Latin1", ofType: "txt")
        let content = (try! NSString(contentsOfFile: path!, encoding:String.Encoding.utf8.rawValue)) as String
        latinSPOriginalWords += content.components(separatedBy: ", ")
        AgniDefaults.latinStarterPackRemaining = latinSPOriginalWords
        
        var beatenTitles = AgniDefaults.beatenWordLists
        if beatenTitles.contains(Constants.LATIN_STARTER_PACK){
            //Already beaten
            beatenLabel.text = "You've already beaten this pack. Way to do it again!"
            newSkinLabel.text = ""
            //newSkinLabel.text = "You already have this skin!"
        }else{
            //Never completed this pack
            beatenTitles.append(Constants.LATIN_STARTER_PACK)
            AgniDefaults.beatenWordLists = beatenTitles
            beatenLabel.text = "You have beaten the Latin Starter Pack!"
            //newSkinLabel.text = "You have unlocked a new skin!"
            newSkinLabel.text = ""
            //TODO: Load skin
        }
    }
    
    func englishSPSetup(){
        let path = Bundle.main.path(forResource: "EnglishStarterPack", ofType: "txt")
        let content = (try! NSString(contentsOfFile: path!, encoding:String.Encoding.utf8.rawValue)) as String
        let engList = content.components(separatedBy: ", ")
        AgniDefaults.englishStarterPackRemaining = engList
        
       var beatenTitles = AgniDefaults.beatenWordLists
        if beatenTitles.contains(Constants.ENGLISH_STARTER_PACK){
            //Already beaten
            beatenLabel.text = "You've already beaten this pack. Way to do it again!"
            newSkinLabel.text = "Play with this skin?"
        }else{
            //Never completed this pack
            beatenTitles.append(Constants.ENGLISH_STARTER_PACK)
            AgniDefaults.beatenWordLists = beatenTitles
            beatenLabel.text = "You have beaten the English Starter Pack!"
            newSkinLabel.text = "You have unlocked a new skin!"
        }
    }
    
    func otherWordPackSetup() {
        var beatenTitles = AgniDefaults.beatenWordLists
        if beatenTitles.contains(selectedTitle){
            beatenLabel.text = "You've already beaten this pack. Way to do it again!"
            newSkinLabel.text = "Play with this skin?"
        }else{
            //Never completed this pack
            beatenTitles.append(selectedTitle)
            AgniDefaults.beatenWordLists = beatenTitles
            beatenLabel.text = "You have beaten \(selectedTitle)!"
            newSkinLabel.text = "You have unlocked a new skin!"
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList") //get the list of lists
        
        let predicate = NSPredicate(format: "title == %@", selectedTitle)
        fetchRequest.predicate = predicate
        do {
            let results = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
            guard let list = results.first else{return}
            let fullList = NSKeyedUnarchiver.unarchiveObject(with: list.value(forKey: "words") as! Data) as! [String]
            if fullList.count <= 0 {
                AgniDefaults.selectedTitle = Constants.ENGLISH_STARTER_PACK
            }
            
            //Now save the full list to the remaining
            let remainingWordsData = NSKeyedArchiver.archivedData(withRootObject: fullList)
            list.setValue(remainingWordsData, forKey: "remaining_words")
            do {
                try managedContext.save()
                print("Saved remaining words")
                NotificationCenter.default.post(Notification(name: .sourceChanged))
            } catch let error1 as NSError {
                print("%@", error1)
            }
            
        }catch let error as NSError {
            print("%@", error)
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func resumePlay(sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

}
