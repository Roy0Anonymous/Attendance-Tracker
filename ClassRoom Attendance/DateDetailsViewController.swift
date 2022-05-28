//
//  DateDetailsViewController.swift
//  ClassRoom Attendance
//
//  Created by Rahul Roy on 24/05/22.
//

import UIKit
import RealmSwift
import DropDown

class DateDetailsViewController: UIViewController {

    let sectionDropDown = DropDown()
    var sectionDropDownValues: [String] = [] //Stores names of all sections
    var currentSelectedSection: SectionData?
    var currentSelection: DateCalendar?
    let realm = try! Realm()
    
    @IBOutlet var showSectionDropdown: UIView!
    @IBOutlet var sectionNameButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        sectionDropDown.backgroundColor = .systemBackground
        sectionDropDown.textColor = .label
        sectionDropDown.backgroundColor = .secondarySystemGroupedBackground
        sectionDropDown.cornerRadius = 15
        
        guard let currSelection = self.realm.object(ofType: DateCalendar.self, forPrimaryKey: selectedDate) else {
            return
        }
        
        //Adding section names to drop down
        for section in currSelection.sectionList {
            sectionDropDownValues.append(section.sec)
        }
        
        //Adding constraints for drop down
        sectionDropDown.anchorView = showSectionDropdown
        sectionDropDown.dataSource = sectionDropDownValues
        sectionDropDown.bottomOffset = CGPoint(x: 0, y:(sectionDropDown.anchorView?.plainView.bounds.height)!)
        sectionDropDown.topOffset = CGPoint(x: 0, y:-(sectionDropDown.anchorView?.plainView.bounds.height)!)
        
        sectionDropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.sectionNameButton.setTitle(item, for: .normal)
            self.sectionNameButton.titleLabel?.font = .systemFont(ofSize: 20)
            for section in currSelection.sectionList {
                if section.sec == item {
                    currentSelectedSection = section //Stores selected section from dropdown
                    break
                }
            }
        }
    }
    
    @IBAction func SelectSection(_ sender: UIButton) {
        sectionDropDown.show() //Presents dropdown on tap
    }
    
    @IBAction func deleteAllSectionAttendace(_ sender: UIButton) {
        guard let currSelection = self.realm.object(ofType: DateCalendar.self, forPrimaryKey: selectedDate) else {
            return
        }
        currentSelection = currSelection
        realm.beginWrite()
        for selection in currSelection.sectionList {
            realm.delete(selection.students) //Deletes all students from each section
        }
        realm.delete(currSelection.sectionList) //Deletes all sections
        realm.delete(currSelection) //Deletes the selected date
        try! realm.commitWrite()
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.success)
        dismiss(animated: true)
    }
    
    
    @IBAction func deleteSavedAttendance(_ sender: UIButton) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        guard let currentSelectedSec = currentSelectedSection else {
            let alertController = UIAlertController(title:"No Section Selected", message:nil, preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        sectionNameButton.setTitle("Select Section", for: .normal)
        var iterator = 0
        while iterator < sectionDropDownValues.count {
            if sectionDropDownValues[iterator] == currentSelectedSec.sec {
                sectionDropDownValues.remove(at: iterator) //Removes the selected section from dropdown
                break
            }
            iterator += 1
        }
        sectionDropDown.dataSource = sectionDropDownValues //Updates dropdown
        realm.beginWrite()
        realm.delete(currentSelectedSec.students) //Deletes all students from current section
        realm.delete(currentSelectedSec) //Deletes the section
        try! realm.commitWrite()
        currentSelectedSection = nil

        if sectionDropDownValues.isEmpty {
            guard let currSelection = self.realm.object(ofType: DateCalendar.self, forPrimaryKey: selectedDate) else {
                return
            }
            realm.beginWrite()
            realm.delete(currSelection) //Deletes the selected date if all section data is removed
            try! realm.commitWrite()
            dismiss(animated: true)
        }
        feedbackGenerator.notificationOccurred(.success)
    }
    
    
    @IBAction func export(_ sender: UIButton) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        guard let currentSelectedSection = currentSelectedSection else {
            let alertController = UIAlertController(title:"No Section Selected", message:nil, preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        let file_name = selectedDate + "_" + (sectionNameButton.titleLabel?.text)! + ".csv"
        let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(file_name)
        var csvHead = "Roll No,Name,E-Mail,Attendance,Present Time\n" //Sets Header
        var number = 0
        
        for students in currentSelectedSection.students { //Adds Entry for Each Student
            number += 1
            var presentOrNot: String = ""
            presentOrNot = students.isPresent ? "Present" : "Not Present"
            csvHead.append("\(students.roll),\(students.name),\(students.email),\(presentOrNot),\(students.presentTime)\n")
        }
        
        do {
            try csvHead.write(to: path!, atomically: true, encoding: .utf8)
            let exportSheet = UIActivityViewController(activityItems: [path as Any], applicationActivities: nil)
            self.present(exportSheet, animated: true, completion: nil)
        } catch {
            let alertController = UIAlertController(title:"An error occured, while exporting the attendance.", message:"Please try after some time", preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
        }
    }
}
