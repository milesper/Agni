//
//  SkinPickerViewController.swift
//  Agni
//
//  Created by Michael Ginn on 8/20/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class SkinPickerViewController: MenuItemViewController, iCarouselDataSource, iCarouselDelegate {
    @IBOutlet var carousel : iCarousel!
    var defaults = UserDefaults.standard //get app-wide data
    var skins:[NSManagedObject] = []
    var selectedSkinName:String?
    var lastSelectedIndex:Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        carousel.type = iCarouselType.cylinder
        loadSkins()
    }
    
    func loadSkins(){
        //get skins saved in persistant memory
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Skin") //get the list of skins
        
        self.skins = []
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
        }catch _{
            print("Something went wrong getting skins")
        }
        
        if (fetchedResults != nil){
            for skin in fetchedResults!{
                if skin.value(forKey: "unlocked") == nil || skin.value(forKey:"unlocked") as! Bool{
                    self.skins.append(skin)
                }
            }
        }
        skins.sort(by: {($0.value(forKey: "date") as! NSDate).compare(($1.value(forKey: "date") as! NSDate) as Date) == .orderedDescending})
        self.selectedSkinName = (defaults.value(forKey: "currentSkin") as! String)
        carousel.reloadData()
        
        for i in 0 ..< skins.count{
            if (skins[i].value(forKey: "name") as! String) == selectedSkinName{
                self.lastSelectedIndex = i + 1
            }
        }
        carousel.scrollToItem(at: lastSelectedIndex, animated: false)
        NotificationCenter().addObserver(self, selector: #selector(skinsUpdated), name: Notification.Name("skins-refreshed"), object: nil)

    }
    
    @objc func skinsUpdated(){
        print("Skins have been updated")
        loadSkins()
        carousel.reloadData()
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        return (skins.count + 1)
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        var itemView:UIButton
        var checkView:UIImageView
        if (view == nil){
            itemView = UIButton(frame:CGRect(x:0, y:0, width:212, height:206))
            itemView.contentMode = .scaleAspectFit
            itemView.imageView?.contentMode = .scaleAspectFit
            itemView.isUserInteractionEnabled = true
            
            checkView = UIImageView(frame: CGRect(x: 0, y: 174, width: 50, height: 50))
            checkView.center.x = itemView.center.x
            checkView.tag = 1
            
            itemView.addSubview(checkView)
        } else
        {
            //get a reference to the label in the recycled view
            itemView = view as! UIButton;
        }
        
        //set up the image and selection image
        
        checkView = itemView.viewWithTag(1) as! UIImageView
        if index == 0{
            itemView.setImage(UIImage(named: "Sheep large"), for:.normal)
            if self.defaults.string(forKey: "currentSkin") == "Default"{
                self.lastSelectedIndex = 0
                checkView.image = UIImage(named: "Checkmark-100.png")
            }
            itemView.addTarget(self, action: #selector(useSkin(sender:)), for: .touchUpInside)
        }else{
            let skin = skins[index-1]
            itemView.setImage(UIImage(data: (skin.value(forKey: "file") as! NSData) as Data), for:.normal)
            
            let isAwardSkin = skin.value(forKey: "forList") != nil && skin.value(forKey: "forList") as! String != "" //Will use to determine if skin is locked
            
            if self.defaults.string(forKey: "currentSkin") == skin.value(forKey: "name") as? String{
                self.lastSelectedIndex = index
                checkView.image = UIImage(named: "Checkmark-100.png")
            }else if !isAwardSkin && !defaults.bool(forKey: "skinsUnlocked"){
                checkView.image = UIImage(named: "Lock-100.png")
            }
            itemView.addTarget(self, action: #selector(useSkin(sender:)), for: .touchUpInside)
        }
        
        return itemView
    }
    
    @objc func useSkin(sender:UIButton){
        let index = carousel.index(ofItemViewOrSubview: sender)
        
        if index == 0{
            defaults.setValue("Default", forKey: "currentSkin")
            let checkImageView = sender.viewWithTag(1) as! UIImageView
            checkImageView.image = UIImage(named: "Checkmark-100.png")
            checkImageView.alpha = 1.0;
            
            if (lastSelectedIndex != index){
                let previousItemView = carousel.itemView(at: lastSelectedIndex)
                let lastButton = previousItemView?.viewWithTag(1) as! UIImageView
                lastButton.alpha = 0.0
                lastSelectedIndex = index
            }
            print("Current Skin: %@", defaults.value(forKey: "currentSkin") as! String)
        }else{
            let skin = skins[index-1]
            let isAwardSkin = skin.value(forKey: "forList") != nil && skin.value(forKey: "forList") as! String != ""
            
            if isAwardSkin || defaults.bool(forKey: "skinsUnlocked"){
                print("Press!")
                let checkImageView = sender.viewWithTag(1) as! UIImageView
                checkImageView.image = UIImage(named: "Checkmark-100.png")
                checkImageView.alpha = 1.0;
                defaults.setValue(skin.value(forKey: "name") as? String, forKey: "currentSkin") //change it up
                
                
                if (lastSelectedIndex != index){
                    let previousItemView = carousel.itemView(at: lastSelectedIndex)
                    let lastButton = previousItemView?.viewWithTag(1) as! UIImageView
                    lastButton.alpha = 0.0
                    lastSelectedIndex = index
                }
                
                print("Current Skin: %@", defaults.value(forKey: "currentSkin") as! String)
            } else{
                self.performSegue(withIdentifier: "buySkins", sender: self)
            }
        }
    }
    
    @IBAction func randomSkin(_ sender: UIButton) {
        let randIndex = Int(arc4random_uniform(UInt32(skins.count+1)))
        let selectedView = carousel.itemView(at: randIndex) as! UIButton
        carousel.scrollToItem(at: randIndex, animated: true)
        useSkin(sender: selectedView)
    }
    
    @IBAction func refreshSkins(_ sender: UIButton) {
        let delegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
        delegate.downloadManager.getNewSkins()
    }
    
    
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat
    {
        if (option == .spacing)
        {
            return value * 1.1
        }
        if (option == .showBackfaces)
        {
            return 0.0
        }
        if (option == .arc)
        {
            return CGFloat(Double.pi)
        }
        return value
    }
    
    @IBAction func closeSkins(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
}
