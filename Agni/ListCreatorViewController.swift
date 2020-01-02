//
//  ListCreatorViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/14/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class ListCreatorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var userLists:[NSManagedObject] = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        loadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadData()
        collectionView.reloadData()
    }
    
    func loadData(){
        self.userLists = []
        if AgniDefaults.userCreatedListTitles == []{
            return
        }else{
            let listNames = AgniDefaults.userCreatedListTitles
            //get lists saved in persistant memory
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList") //get the list of lists
            let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            let predicate = NSPredicate(format: "title IN %@", listNames)
            fetchRequest.predicate = predicate
            
            var fetchedResults:[NSManagedObject]? = nil
            do{
                fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
            } catch _{
                print("Something went wrong getting words")
            }
            if (fetchedResults != nil){
                for list in fetchedResults!{
                    self.userLists.append(list)
                }
            }
            
        }
        
    }
    
    //Collection View
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userLists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath)
        let label = cell.viewWithTag(1) as! UILabel
        label.text = (userLists[(indexPath as NSIndexPath).row].value(forKey: "title") as! String)
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showListDetail"{
            let destVC = segue.destination as! CustomListViewController
            guard let indexPath = collectionView.indexPathsForSelectedItems?.first else {return}
            
            destVC.list = self.userLists[indexPath.row]
            
            UIGraphicsBeginImageContext(CGSize(width: view.frame.size.width, height: view.frame.size.height));
            view.drawHierarchy(in: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height), afterScreenUpdates: true)
            destVC.backgroundImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
        }
    }
    
    @IBAction func closeListCreator(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
