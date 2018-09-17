//
//  WordListsViewController.swift
//
//
//  Created by Michael Ginn on 5/5/15.
//
//

import UIKit
import CoreData


class WordListsViewController: MenuItemViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    var selectedTitles:[String] = []
    var selectedTitle:String = ""
    var selectedCell:UITableViewCell?
    var lists:[NSManagedObject] = [] //lists from CoreData
    var customLists:[NSManagedObject] = []
    
    var defaults = UserDefaults.standard //get app-wide data
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor(red: 104/255.0, green: 104/255.0, blue: 104/255.0, alpha: 1.0)]
        
        //find all the lists and load em up
        self.lists = []
        
        //get lists saved in persistant memory
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName:"WordList") //get the list of lists
        let sortDescriptor = NSSortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        var fetchedResults:[NSManagedObject]? = nil
        do{
            fetchedResults = try managedContext.fetch(fetchRequest) as? [NSManagedObject]
        } catch _{
            print("Something went wrong getting words")
        }
        if (fetchedResults != nil){
            for list in fetchedResults!{
                if list.value(forKey: "Author") as! String == "Agni Dev"{
                    self.lists.append(list)
                }else{
                    self.customLists.append(list)
                }
            }
        }
        //self.selectedTitles = self.defaults.object(forKey: "selectedTitles") as! [String]
        self.selectedTitle = self.defaults.object(forKey: "selectedTitle") as! String
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView.tag == 1{
            return 2
        }else if tableView.tag == 2{
            return 1
        }else{
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1{
            if section == 0{
                return 2
            }else if section == 1{
                return self.lists.count
            }else{
                return 0
            }
        }else if tableView.tag == 2{
            return self.customLists.count
        }else{
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listCell", for: indexPath)
        guard let listLabel = cell.textLabel else{return cell}
        guard let authorLabel = cell.detailTextLabel else{return cell}
        var hasStudyMode = false
        let beatenTitles = (defaults.value(forKey: "beatenWordLists") as! [String])
        
        if tableView.tag == 1{
            if (indexPath as NSIndexPath).section == 0{
                if (indexPath as NSIndexPath).row == 0{
                    listLabel.text = "Latin Starter Pack"
                    authorLabel.text = "Agni Dev"
                    hasStudyMode = true
                    
                    if let remaining = defaults.array(forKey: "latinSPRemaining"){
                        if !beatenTitles.contains("Latin Starter Pack"){
                            let remainingPercent = Float(remaining.count) / 211.0
                            addCompletionGradient(label: listLabel, percentage: 1.0 - remainingPercent)
                        }else{
                            addCompletionGradient(label: listLabel, percentage: 1.0)
                        }
                        
                    }else{
                        addCompletionGradient(label: listLabel, percentage: 0.0)
                        //We'll let the later screen take care of initializing the remaining val
                    }
                }else if (indexPath as NSIndexPath).row == 1{
                    listLabel.text = "English Starter Pack"
                    authorLabel.text = "Agni Dev"
                    
                    if let remaining = defaults.array(forKey: "englishSPRemaining"){
                        
                        if !beatenTitles.contains("English Starter Pack"){
                            let remainingPercent = Float(remaining.count) / 51
                            addCompletionGradient(label: listLabel, percentage: 1.0 - remainingPercent)
                        }else{
                            addCompletionGradient(label: listLabel, percentage: 1.0)
                        }
                    }else{
                        addCompletionGradient(label: listLabel, percentage: 0.0)
                    }
                }
            }else{
                //Downloaded list
                let list = self.lists[indexPath.row]
                listLabel.text = (list.value(forKey: "title") as! String)
                authorLabel.text = (list.value(forKey: "author") as! String)
                
                let remainingData = list.value(forKey: "remaining_words") as! Data
                let remaining = NSKeyedUnarchiver.unarchiveObject(with: remainingData) as! [String]
                
                if let totalCount = list.value(forKey: "word_count") as? Int{
                    if !beatenTitles.contains(list.value(forKey: "title") as! String){
                        let remainingPercent = Float(remaining.count) / Float(totalCount)
                        addCompletionGradient(label: listLabel, percentage: 1.0 - remainingPercent)
                    }else{
                        //List has been completed
                        addCompletionGradient(label: listLabel, percentage: 1.0)
                    }
                }
                let studyMode = list.value(forKey: "has_study_mode") as? Bool
                if studyMode != nil{
                    hasStudyMode = studyMode!
                }else{
                    hasStudyMode = false
                }
            }
            //Study mode
            
            if hasStudyMode{
                addStudyModeIcon(cell: cell)
            }
            
        }else if tableView.tag == 2{
            let list = self.customLists[indexPath.row]
            listLabel.text = (list.value(forKey: "title") as! String)
            authorLabel.text = (list.value(forKey: "author") as! String)
            
            let remainingData = list.value(forKey: "remaining_words") as! Data
            let remaining = NSKeyedUnarchiver.unarchiveObject(with: remainingData) as! [String]
            if let totalCount = list.value(forKey: "word_count") as? Int{
                if !beatenTitles.contains(list.value(forKey: "title") as! String){
                    let remainingPercent = Float(remaining.count) / Float(totalCount)
                    addCompletionGradient(label: listLabel, percentage: remainingPercent)
                }else{
                    addCompletionGradient(label: listLabel, percentage: 1.0)
                }
            }
            if (list.value(forKey: "has_study_mode") as! Bool){
                addStudyModeIcon(cell: cell)
            }
        }

        if listLabel.text == selectedTitle{
            //list is selected
            cell.accessoryType = .checkmark
            self.selectedCell = cell
        }else{
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func addCompletionGradient(label:UILabel, percentage:Float){
        let labelCopy = UILabel(frame: CGRect(x: 1.0, y: 0.0, width: label.intrinsicContentSize.width, height: label.intrinsicContentSize.height))
        labelCopy.text = label.text
        
        let labelRect = CGRect(x: 15.0, y: 15.0, width: labelCopy.intrinsicContentSize.width, height: labelCopy.intrinsicContentSize.height) //This accounts for the dynamic text hopefully
        let gradView = UIView(frame: labelRect)
        
        let gradientLayer = CAGradientLayer()
        if percentage > 0.0 && percentage < 1.0{
            //Show some of both colors
            gradientLayer.colors = [UIColor.AgniColors.Blue.cgColor, UIColor.AgniColors.Blue.cgColor, UIColor.black.cgColor, UIColor.black.cgColor] //So we can control where the gradient is

            let beforeChange = NSNumber(value: (percentage - 0.1))
            let afterChange = NSNumber(value: (percentage + 0.1))
            gradientLayer.locations = [0.0,  beforeChange, afterChange, 1.0]
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            
            gradientLayer.frame = gradView.bounds
            gradView.layer.addSublayer(gradientLayer)
            
            label.superview?.addSubview(gradView)
            gradView.addSubview(labelCopy)
            
            labelCopy.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
            gradView.mask = labelCopy
            
            label.isHidden = true
        }else if percentage == 0.0{
            //None completed
            label.textColor = UIColor.black
            label.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
        }else if percentage == 1.0{
            //List completed
            label.textColor = UIColor.AgniColors.Blue
            label.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.thin)
        }
    }
    
    func addStudyModeIcon(cell:UITableViewCell){
        let xVal = cell.textLabel?.intrinsicContentSize.width
        let imageView = UIImageView(frame: CGRect(x: xVal! + 20, y: 15, width: 20, height: 20))
        imageView.image = UIImage(named: "StudyMode")
        imageView.tag = 2
        if cell.contentView.viewWithTag(2) == nil{
            cell.contentView.addSubview(imageView)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        guard let titleLabel = cell.textLabel else{return}
        
        self.selectedTitle = titleLabel.text!
        self.defaults.set(selectedTitle, forKey: "selectedTitle")
        tableView.deselectRow(at: indexPath, animated: true)
        self.selectedCell?.accessoryType = .none
        cell.accessoryType = .checkmark
        self.selectedCell = cell
        
        self.defaults.set(true, forKey: "needsUpdateSources")
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        //Space between starter and downloaded
        if section == 0{
            return 10
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UITableViewHeaderFooterView()
        footerView.backgroundView = UIView()
        footerView.backgroundView?.backgroundColor = UIColor.white
        return footerView
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let page = Int(floor((scrollView.contentOffset.x - pageWidth / 2 ) / pageWidth) + 1)
        
        pageControl.currentPage = page;
    }
    
    @IBAction func closeWordLists(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
