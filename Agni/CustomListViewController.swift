//
//  CustomListViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/19/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData

class CustomListViewController: UIViewController {
    
    var backgroundImage:UIImage?
    var list:NSManagedObject?
    var fileURL:URL?
    
    @IBOutlet weak var fileNameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        /**backgroundImage = UIImageEffects.imageByApplyingBlur(to: backgroundImage, withRadius: 30, tintColor: UIColor(white: 1.0, alpha: 0.2), saturationDeltaFactor: 1.0, maskImage: nil)
        
        let bgImageView = UIImageView(frame: self.view.frame)
        bgImageView.image = self.backgroundImage!
        self.view.insertSubview(bgImageView, at: 0)
         **/
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CustomListViewController.dismissView))
        self.view.addGestureRecognizer(gestureRecognizer)
        
        fileNameLabel.text = (list?.value(forKey: "title") as! String)
        
        //Make textfile
        var stringToWrite = (list!.value(forKey: "title") as! String) + "\n" + (list!.value(forKey: "author") as! String) + "\n"
        var wordList = NSKeyedUnarchiver.unarchiveObject(with: list!.value(forKey: "words") as! Data) as! [String]
        guard wordList.count > 0 else{return}
        
        stringToWrite += wordList.removeFirst()
        for word in wordList{
            stringToWrite += ", "
            stringToWrite += word
        }
        
        if list?.value(forKey: "has_study_mode") as! Bool{
            //List has study mode, lets write the meanings on a new line
            stringToWrite += "\n"
            var hintList = NSKeyedUnarchiver.unarchiveObject(with: list!.value(forKey: "word_meanings") as! Data) as! [String]
            guard hintList.count > 0 else{return}
            stringToWrite += hintList.removeFirst()
            for hint in hintList{
                stringToWrite += ", "
                stringToWrite += hint
            }
        }
        
        //Save textfile
        do{
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)
            let path = documentsDirectory.first! + "/" + (list?.value(forKey: "title") as! String) + ".awl"
            print(path)
            
            try stringToWrite.write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            self.fileURL = URL(fileURLWithPath: path, isDirectory: false)
        }catch {
            print("Error creating file: \(error)")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func dismissView(){
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func shareAction(_ sender: AnyObject) {
        let activityViewController = UIActivityViewController(activityItems: [self.fileURL!], applicationActivities: nil)
        if activityViewController.responds(to: #selector(getter: UIViewController.popoverPresentationController)){
            activityViewController.popoverPresentationController?.sourceView = sender as! UIButton
        }
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func editAction(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "editList", sender: self)
    }

    @IBAction func deleteAction(_ sender: AnyObject) {
        
        
        let alert = UIAlertController(title: "Delete List", message: "Really delete '\(self.fileNameLabel.text!)'?", preferredStyle: .alert)
        let actionNo = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let actionYes = UIAlertAction(title: "Delete", style: .destructive, handler: {
            action in
            
            //remove list from selected
            if AgniDefaults.selectedTitle == self.fileNameLabel.text{
                AgniDefaults.selectedTitle = "English Starter Pack"
            }
            
            // remove from core data as well
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            managedContext.delete(self.list!)
            do{ try managedContext.save()
            }catch{print(error)}
            
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(actionNo)
        alert.addAction(actionYes)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editList"{
            let destVC = segue.destination as! NewListViewController
            destVC.listToEdit = list
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let fileManager = FileManager.default
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)
        let path = documentsDirectory.first!
        do{
            let directoryContents = try fileManager.contentsOfDirectory(atPath: path)
            for file in directoryContents{
                if file.contains(".awl"){
                    try fileManager.removeItem(atPath: path + "/" + file)
                    print("removed \(file)")
                }
            }
        }catch {
            print((error as NSError).description)
        }

        
    }
}
