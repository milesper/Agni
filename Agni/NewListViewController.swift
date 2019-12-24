//
//  NewListViewController.swift
//  Agni
//
//  Created by Michael Ginn on 7/15/16.
//  Copyright © 2016-17 Michael Ginn. All rights reserved.
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
    
    @IBOutlet weak var listTitleTextField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var authorTextField: UITextField!
    @IBOutlet weak var studyModeSwitch: UISwitch!
    
    var currentlyEditingTextField: UITextField? = nil
    
    var listToEdit:NSManagedObject?
    var words:[String] = []
    var meanings:[String] = []
    var studyMode = false
    enum EditMode{
        case new
        case edit
    }
    var mode:EditMode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        registerForKeyboardNotifications()
        
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
            if let meaningsData = listToEdit!.value(forKey: "word_meanings") as? Data{
                meanings =  NSKeyedUnarchiver.unarchiveObject(with: meaningsData) as! [String]
            }else{
                meanings = [String](repeating: "", count: words.count)
            }
            if let hasStudyMode = listToEdit?.value(forKey: "has_study_mode") as? Bool{
                studyModeSwitch.setOn(hasStudyMode, animated: true)
                self.studyModeSwitched(studyModeSwitch)
            }
            saveButton.isEnabled = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func titleDidChange(){
        if listTitleTextField.text?.count > 0 && authorTextField.text?.count > 0{
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
            if studyMode{
                let meaningData = NSKeyedArchiver.archivedData(withRootObject: meanings)
                listToEdit!.setValue(meaningData, forKey: "word_meanings")
                listToEdit!.setValue(true, forKey: "has_study_mode")
            }else{
                listToEdit!.setValue(false, forKey: "has_study_mode")
            }
            do {
                try managedContext.save()
                print("Saved \(listTitleTextField.text!)")
            } catch let error1 as NSError {
                print("%@", error1)
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
                    Converter.saveListToCoreData(listItems: words,listItemMeanings:meanings, listTitle: listTitleTextField.text!, listAuthor: authorTextField.text!)
                    
                    AgniDefaults.userCreatedListTitles.append(listTitleTextField.text!)
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
        if indexPath.row == words.count{
            //empty cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "newWordCell")
            let textField = cell?.viewWithTag(1) as! UITextField
            textField.text = ""
            textField.delegate = self
            let meaningTextField = cell?.viewWithTag(5) as! UITextField
            meaningTextField.delegate = self
            meaningTextField.text = ""
            meaningTextField.isHidden = !studyMode
            return cell!
        }else{
            //cell with word
            let cell = tableView.dequeueReusableCell(withIdentifier: "wordCell")
            let textField = cell?.viewWithTag(1) as! UITextField
            textField.text = words[indexPath.row]
            textField.delegate = self
            let meaningTextField = cell?.viewWithTag(5) as! UITextField
            meaningTextField.delegate = self
            meaningTextField.text = indexPath.row < meanings.count ? meanings[indexPath.row] : ""
            meaningTextField.isHidden = !studyMode

            return cell!
        }
    }
    
    //Text Field
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.currentlyEditingTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.tag == 2 || textField.tag == 3{
            textField.resignFirstResponder()
            return true
        }
        guard let cell = textField.superview?.superview as? UITableViewCell else{return false}
        guard let indexPath = tableView.indexPath(for: cell) else{return false}
        
        if textField.tag == 1 && !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)!{
            //Word text field, not blank
            let hintTextField = cell.viewWithTag(5) as! UITextField
            if studyMode{
                //Go to hint text field
                hintTextField.becomeFirstResponder()
                self.currentlyEditingTextField = hintTextField
                return true
            }else{
                if indexPath.row == words.count{
                    //Cell is last cell
                    words.append(textField.text!)
                    meanings.append("")
                    
                    tableView.reloadData() //Create a new cell
                    let lastCell = tableView.cellForRow(at: IndexPath(row: words.count, section: 0))
                    let lastCellTextField = lastCell?.viewWithTag(1) as! UITextField
                    lastCellTextField.becomeFirstResponder()
                    return true
                }else{
                    words[indexPath.row] = textField.text!
                    textField.resignFirstResponder()
                    return true
                }
            }
        }else if textField.tag == 5{
            //Hint field
            let wordTextField = cell.viewWithTag(1) as! UITextField
            
            if indexPath.row == words.count{
                //Cell is last cell
                if !(wordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                    words.append(wordTextField.text!)
                    meanings.append(textField.text!)
                    
                    tableView.reloadData() //Create a new cell
                    let lastCell = tableView.cellForRow(at: IndexPath(row: words.count, section: 0))
                    let lastCellTextField = lastCell?.viewWithTag(1) as! UITextField
                    lastCellTextField.becomeFirstResponder()
                }else{
                    //Word cell is empty
                    textField.resignFirstResponder()
                }
            }else{
                words[indexPath.row] = wordTextField.text!
                meanings[indexPath.row] = textField.text!
                textField.resignFirstResponder()
            }
            return true
        }else{
            return false
        }

    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.currentlyEditingTextField = nil
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        print("scrolling")
        guard let textField = currentlyEditingTextField else{return}
        textField.resignFirstResponder()
        
        guard let cell = textField.superview?.superview as? UITableViewCell else{return}
        guard let indexPath = tableView.indexPath(for: cell) else{return}
        //Now we know its in the table view
        
        if textField.tag == 1{
            //Words textfield
            let hintTextField = cell.viewWithTag(5) as! UITextField
            
            if !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)!{
                //Textfield is not empty
                if indexPath.row == words.count{
                    //Cell is the last cell
                    words.append(textField.text!)
                    meanings.append(hintTextField.text!)
                    tableView.reloadData()
                }else{
                    //Cell is not last cell
                    words[indexPath.row] = textField.text!
                }
            }else{
                //Textfield is empty
                if indexPath.row != words.count{
                    words.remove(at: indexPath.row)
                    tableView.reloadData()
                }
            }
        }else if textField.tag == 5{
            //Meanings textfield
            let wordTextField = cell.viewWithTag(1) as! UITextField
            if indexPath.row == words.count{
                //Cell is last cell
                words.append(wordTextField.text!)
                meanings.append(textField.text!)
                
                tableView.reloadData() //Create a new cell
            }else{
                words[indexPath.row] = wordTextField.text!
                meanings[indexPath.row] = textField.text!
            }

        }
    }
    
    @IBAction func studyModeSwitched(_ sender: UISwitch) {
        studyMode = sender.isOn
        UIView.transition(with: tableView, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: nil)
    }
    
    
    //Keyboard 
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(aNotification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(aNotification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWasShown(aNotification: NSNotification) {
        guard currentlyEditingTextField != nil else{return}
        let info = aNotification.userInfo as! [String: AnyObject],
        kbSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.size,
        contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: kbSize.height, right: 0)
        
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
        
        // If active text field is hidden by keyboard, scroll it so it's visible
        // Your app might not need or want this behavior.
        var aRect = self.view.frame
        aRect.size.height -= kbSize.height
        
        if !aRect.contains(self.currentlyEditingTextField!.frame.origin) {
            self.tableView.scrollRectToVisible(self.currentlyEditingTextField!.frame, animated: true)
        }
    }
    
    @objc func keyboardWillBeHidden(aNotification: NSNotification) {
        let contentInsets = UIEdgeInsets.zero
        self.tableView.contentInset = contentInsets
        self.tableView.scrollIndicatorInsets = contentInsets
    }
}
