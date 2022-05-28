//
//  CalendarView.swift
//  ClassRoom Attendance
//
//  Created by Rahul Roy on 15/05/22.
//

import UIKit
import FSCalendar
import RealmSwift

let cal = FSCalendar()
var selectedDate = "" //Stores the selected date
var allDates: [String] = [] //Stores dates for which attendance is available

class CalendarView: UIViewController, FSCalendarDelegate, FSCalendarDataSource {
   
    let realm = try! Realm()
    
    @IBOutlet var calendar: FSCalendar!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        calendar.delegate = self
        calendar.dataSource = self
        calendar.appearance.titleDefaultColor = .label
        
        let allDateObjects = realm.objects(DateCalendar.self) //Retrieves all DateCalendar objects present in the database
        for dateObject in allDateObjects {
            allDates.append(dateObject.dateName)
        }
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateSelection = formatter.string(from: date) //converts current date to string
        selectedDate = dateSelection
        let feedbackGenerator = UINotificationFeedbackGenerator()
        guard let currSelection = self.realm.object(ofType: DateCalendar.self, forPrimaryKey: dateSelection) else { //Check if selected date has attendance or not
            let alertController = UIAlertController(title:"No Attendace Available on selected date.", message:nil, preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        feedbackGenerator.notificationOccurred(.success)
        
        var sectionDataIsPresent: SectionData?
    
        for section in currSelection.sectionList { //Checks if current selected section is present in the database or not
            if section.sec == currentSection.sec {
                sectionDataIsPresent = section
                break
            }
        }
        
        let alert: UIAlertController
        if sectionDataIsPresent == nil { //If selected section attendance is not present
            alert = UIAlertController(title: "Attendance of other sections found on the selected date. Do you want to view them?", message: nil , preferredStyle: .alert)
        } else { //If selected section attendance is present
            alert = UIAlertController(title: "Attendance for the section \"\(currentSection.sec)\" found. Do you want to export it?", message: nil , preferredStyle: .alert)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Show Details", style: .default, handler: { action in //Shows attendance of all sections including deleted ones
            
            //Presents sheet view controller to show all details
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let dateDetailsController = storyboard.instantiateViewController(identifier: "DateDetailsViewController")
            if let sheet = dateDetailsController.presentationController as? UISheetPresentationController {
                sheet.detents = [.medium()]
            }
            DispatchQueue.main.async { [unowned self] in
                self.present(dateDetailsController, animated: true)
            }
        }))
        
        if sectionDataIsPresent != nil {
            alert.addAction(UIAlertAction(title: "Export", style: .default, handler: { action in //Exports attendance of current selected section
                let file_name = currSelection.dateName + "_" + sectionDataIsPresent!.sec + ".csv"
                let path = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(file_name)
                var csvHead = "Roll No,Name,E-Mail,Attendance,Present Time\n" //Sets Header
                var number = 0 //Number of Entries
                
                for students in sectionDataIsPresent!.students { //Adds Entry for Each Student
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
            }))
        }
        present(alert, animated: true)
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int { //Marks dates which have attendance as events
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: date)
        if allDates.contains(dateString) { //Marks events for all available dates
            return 1
        }
        return 0
    }
}
