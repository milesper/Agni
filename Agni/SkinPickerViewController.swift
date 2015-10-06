//
//  SkinPickerViewController.swift
//  Agni
//
//  Created by Michael Ginn on 8/20/15.
//  Copyright (c) 2015 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class SkinPickerViewController: UIViewController, iCarouselDataSource, iCarouselDelegate {
    @IBOutlet var carousel : iCarousel!
    var defaults = NSUserDefaults.standardUserDefaults() //get app-wide data
    var skins:[NSManagedObject] = []
    var selectedSkinName:String?
    var lastSelectedIndex:Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        carousel.type = iCarouselType.Cylinder
        
        //get skins saved in persistant memory
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName:"Skin") //get the list of skins
        
        self.skins = []
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
        }catch _{
            NSLog("Something went wrong getting skins")
        }
        
        if (fetchedResults != nil){
            for skin in fetchedResults!{
                self.skins.append(skin)
            }
        }
        skins.sortInPlace({($0.valueForKey("date") as! NSDate).compare($1.valueForKey("date") as! NSDate) == .OrderedDescending})
        self.selectedSkinName = (defaults.valueForKey("currentSkin") as! String)
        carousel.reloadData()
        
        for (var i = 0; i<skins.count; i++){
            if (skins[i].valueForKey("name") as! String) == selectedSkinName{
                self.lastSelectedIndex = i + 1
            }
        }
        carousel.scrollToItemAtIndex(lastSelectedIndex, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        return (skins.count + 1)
    }
    
    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView {
        var itemView:UIButton
        var checkView:UIImageView
        if (view == nil){
            itemView = UIButton(frame:CGRect(x:0, y:0, width:212, height:206))
            itemView.imageView?.contentMode = .Top
            itemView.userInteractionEnabled = true
            
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
            itemView.setImage(UIImage(named: "Sheep small.png"), forState:.Normal)
            if self.defaults.stringForKey("currentSkin") == "Default"{
                self.lastSelectedIndex = 0
                checkView.image = UIImage(named: "Checkmark-50.png")
            }
            itemView.addTarget(self, action: "useSkin:", forControlEvents: .TouchUpInside)
        }else{
            itemView.setImage(UIImage(data: skins[index-1].valueForKey("file") as! NSData), forState:.Normal)
            
            if self.defaults.stringForKey("currentSkin") == skins[index - 1].valueForKey("name") as? String{
                self.lastSelectedIndex = index
                checkView.image = UIImage(named: "Checkmark-50.png")
            }
            itemView.addTarget(self, action: "useSkin:", forControlEvents: .TouchUpInside)
        }
        
        return itemView
    }
    
    func useSkin(sender:UIButton){
        if defaults.boolForKey("skinsUnlocked"){
            print("Press!")
            let index = carousel.indexOfItemViewOrSubview(sender)
            let checkImageView = sender.viewWithTag(1) as! UIImageView
            checkImageView.image = UIImage(named: "Checkmark-50.png")
            if index > 0{
                defaults.setValue(skins[index - 1].valueForKey("name") as? String, forKey: "currentSkin") //change it up
            } else{
                defaults.setValue("Default", forKey: "currentSkin")
            }
            
            defaults.synchronize()
            let previousItemView = carousel.itemViewAtIndex(lastSelectedIndex)
            let lastButton = previousItemView?.viewWithTag(1) as! UIImageView
            lastButton.image = UIImage()
            lastButton.alpha = 0.0
            lastSelectedIndex = index
            
            NSLog("Current Skin: %@", defaults.valueForKey("currentSkin") as! String)
        } else{
            self.performSegueWithIdentifier("buySkins", sender: self)
        }
    }

    func carousel(carousel: iCarousel, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat
    {
        if (option == .Spacing)
        {
            return value * 1.1
        }
        if (option == .ShowBackfaces)
        {
            return 0.0
        }
        if (option == .Arc)
        {
            return CGFloat(M_PI)
        }
        return value
    }
    
}
