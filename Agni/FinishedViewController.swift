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
    
    let defaults = UserDefaults.standard //use to get app-wide data
    var selectedTitle:String = ""
    
    enum SkinLoadingError:Error{
        case noSkins
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        selectedTitle = defaults.value(forKey: "selectedTitle") as! String
        
        self.beatenLabel.text = "You have beaten the word pack \(selectedTitle)."
        
        if selectedTitle == "Latin Starter Pack"{
            latinSPSetup()
        }else if selectedTitle == "English Starter Pack"{
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
            newSkinLabel.text = "Can't get a skin :("
            newSkinLabel.textColor = UIColor.AgniColors.Red
            newSkinImage.image = UIImage(named: "Sheep missing")
        }

    }
    
    func latinSPSetup(){
        var latinSPOriginalWords:[String] = [] //Contains all the words
        
        let path = Bundle.main.path(forResource: "Latin1", ofType: "txt")
        let content = (try! NSString(contentsOfFile: path!, encoding:String.Encoding.utf8.rawValue)) as String
        latinSPOriginalWords += content.components(separatedBy: ", ")
        defaults.set(latinSPOriginalWords, forKey: "latinSPRemaining")
        
        var beatenTitles = (defaults.value(forKey: "beatenWordLists") as! [String])
        if beatenTitles.contains("Latin Starter Pack"){
            //Already beaten
            beatenLabel.text = "You've already beaten this pack. Way to do it again!"
            newSkinLabel.text = "You already have this skin!"
        }else{
            //Never completed this pack
            beatenTitles.append("Latin Starter Pack")
            defaults.set(beatenTitles, forKey: "beatenWordLists")
            beatenLabel.text = "You have beaten the Latin Starter Pack!"
            newSkinLabel.text = "You have unlocked a new skin!"
            
            //TODO: Load skin
        }
    }
    
    func englishSPSetup(){
        let path = Bundle.main.path(forResource: "EnglishStarterPack", ofType: "txt")
        let content = (try! NSString(contentsOfFile: path!, encoding:String.Encoding.utf8.rawValue)) as String
        let engList = content.components(separatedBy: ", ")
        defaults.set(engList, forKey: "englishSPRemaining")
        
        var beatenTitles = (defaults.value(forKey: "beatenWordLists") as! [String])
        if beatenTitles.contains("English Starter Pack"){
            //Already beaten
            beatenLabel.text = "You've already beaten this pack. Way to do it again!"
            newSkinLabel.text = "Play with this skin?"
        }else{
            //Never completed this pack
            beatenTitles.append("English Starter Pack")
            defaults.set(beatenTitles, forKey: "beatenWordLists")
            beatenLabel.text = "You have beaten the English Starter Pack!"
            newSkinLabel.text = "You have unlocked a new skin!"
        }
    }
    
    func otherWordPackSetup() {
        var beatenTitles = (defaults.value(forKey: "beatenWordLists") as! [String])
        if beatenTitles.contains(selectedTitle){
            beatenLabel.text = "You've already beaten this pack. Way to do it again!"
            newSkinLabel.text = "Play with this skin?"
        }else{
            //Never completed this pack
            beatenTitles.append(selectedTitle)
            defaults.set(beatenTitles, forKey: "beatenWordLists")
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
                defaults.set("English Starter Pack", forKey: "selectedTitle") 
            }
            
            //Now save the full list to the remaining
            let remainingWordsData = NSKeyedArchiver.archivedData(withRootObject: fullList)
            list.setValue(remainingWordsData, forKey: "remaining_words")
            do {
                try managedContext.save()
                print("Saved remaining words")
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
