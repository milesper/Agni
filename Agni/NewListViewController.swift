//
//  NewListViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/15/16.
//  Copyright © 2016 Michael Ginn. All rights reserved.
//

import UIKit
import CoreData
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class NewListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var defaults = UserDefaults.standard //use to get app-wide data
    
    @IBOutlet weak var listTitleTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var authorTextField: UITextField!
    
    var listToEdit:NSManagedObject?
    var words:[String] = []
    enum EditMode{
        case new
        case edit
    }
    var mode:EditMode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        listTitleTextField.addTarget(self, action: #selector(NewListViewController.titleDidChange), for: .editingChanged)
        authorTextField.addTarget(self, action: #selector(NewListViewController.titleDidChange), for: .editingChanged)
        if listToEdit == nil{
            mode = .new
            topLabel.text = "CREATE NEW LIST"
        }else{
            mode = .edit
            topLabel.text = "EDIT LIST"
            
            listTitleTextField.text = (listToEdit!.value(forKey: "title") as! String)
            listTitleTextField.isEnabled = false
            authorTextField.text = (listToEdit!.value(forKey: "author") as! String)
            authorTextField.isEnabled = false
            words = NSKeyedUnarchiver.unarchiveObject(with: listToEdit!.value(forKey: "words") as! Data) as! [String]
            saveButton.isEnabled = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func titleDidChange(){
        if listTitleTextField.text?.characters.count > 0 && authorTextField.text?.characters.count > 0{
            saveButton.isEnabled = true
        }else{
            saveButton.isEnabled = false
        }
    }
    
    @IBAction func saveList(_ sender: AnyObject) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        if mode == .edit{
            let data = NSKeyedArchiver.archivedData(withRootObject: words) //turn it into CoreData data
            listToEdit!.setValue(data, forKey: "words")
            do {
                try managedContext.save()
                NSLog("Saved \(listTitleTextField.text)")
            } catch let error1 as NSError {
                NSLog("%@", error1)
            }
            self.dismiss(animated: true, completion: nil)
        }else{
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"WordList") //get the list of lists
            
            let predicate = NSPredicate(format: "title == %@", listTitleTextField.text!)
            fetchRequest.predicate = predicate
            do {
                let results = try managedContext.fetch(fetchRequest)
                if results.count > 0{
                    let alert = UIAlertController(title: "List name already taken", message: "Choose a different name:", preferredStyle: .alert)
                    let okButton = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                    alert.addAction(okButton)
                    self.present(alert, animated: true, completion: nil)
                    return
                }else{
                    Converter.saveListToCoreData(listItems: words, listTitle: listTitleTextField.text!, listAuthor: authorTextField.text!)
                    var userCreatedLists = defaults.array(forKey: "userCreatedLists") as! [String]
                    userCreatedLists.append(listTitleTextField.text!)
                    defaults.set(userCreatedLists, forKey: "userCreatedLists")
                    defaults.synchronize()
                    self.dismiss(animated: true, completion: nil)
                }
                
            }catch {
                print("Error checking for dupes")
            }
        }
        
    }
    
    @IBAction func cancelNewList(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //Table View
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return words.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).row == words.count{
            let cell = tableView.dequeueReusableCell(withIdentifier: "newWordCell")
            let textField = cell?.viewWithTag(1) as! UITextField
            textField.delegate = self
            return cell!
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "wordCell")
            let textField = cell?.viewWithTag(1) as! UITextField
            textField.text = words[(indexPath as NSIndexPath).row]
            textField.delegate = self
            return cell!
        }
    }
    
    //Text Field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 1{
            let cell = textField.superview?.superview as! UITableViewCell
            let indexPath = tableView.indexPath(for: cell)
            
            if (indexPath as NSIndexPath?)?.row == words.count{
                //Cell is last
                words.append(textField.text!)
                tableView.reloadData()
                let lastCell = tableView.cellForRow(at: IndexPath(row: words.count, section: 0))
                let newTextField = lastCell?.viewWithTag(1) as! UITextField
                newTextField.text = ""
                newTextField.becomeFirstResponder()
            }else{
                textField.resignFirstResponder()
            }
            
        }else if textField.tag == 2{
            self.authorTextField.becomeFirstResponder()
        }else{
            textField.resignFirstResponder()
        }
        return false
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 1{
            let cell = textField.superview?.superview as! UITableViewCell
            let indexPath = tableView.indexPath(for: cell)
            
            if textField.text == ""{
                if (indexPath! as NSIndexPath).row < words.count{
                    words.remove(at: (indexPath! as NSIndexPath).row)
                    tableView.reloadSections(IndexSet.init(integer: 0), with: .fade)
                }else{
                    tableView.reloadData()
                }
            }else{
                if (indexPath as NSIndexPath?)?.row == words.count{
                    words.append(textField.text!)
                    tableView.reloadSections(IndexSet.init(integer: 0), with: .fade)
                    let lastCell = tableView.cellForRow(at: IndexPath(row: words.count, section: 0))
                    let newTextField = lastCell?.viewWithTag(1) as! UITextField
                    newTextField.text = ""
                }
            }
            
        }
    }
}
