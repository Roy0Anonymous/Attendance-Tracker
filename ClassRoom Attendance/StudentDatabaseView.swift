//
//  StudentDatabaseView.swift
//  ClassRoom Attendance
//
//  Created by Rahul Roy on 13/05/22.
//

import UIKit
import RealmSwift
import DropDown
//import FSCalendar

let dropDown = DropDown()
var currentSection = Section()
var dropDownValues: [String] = []

class StudentDatabaseView: UIViewController {

    var studentImage: UIImage!
    @IBOutlet var studentCollectionView: UICollectionView!
    @IBOutlet var dropDownView: UIView!
    @IBOutlet var availableSectionsLabel: UIButton!
    @IBOutlet var addStudentsButton: UIButton!
    
    let realm = try! Realm()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        becomeFirstResponder() //To enable shake gesture
        
        addStudentsButton.layer.cornerRadius = 0.5 * addStudentsButton.bounds.size.width
        addStudentsButton.clipsToBounds = true
        
        let addSections = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(didTapAddSections)) //Adds option to add sections from NavBar Button
        let markAttendance = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.down"), style: .plain, target: self, action: #selector(didTapMarkAttendance)) //Adds option to mark attendance from NavBar Button
        navigationItem.rightBarButtonItems = [addSections, markAttendance]

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(didTapDelete)) //Adds option to delete sections from NavBar Button

        //Setting drop down attributes
        dropDown.backgroundColor = .systemBackground
        dropDown.textColor = .label
        dropDown.backgroundColor = .secondarySystemGroupedBackground
        dropDown.cornerRadius = 15
        
        //Collection View
        studentCollectionView.dataSource = self
        studentCollectionView.delegate = self
        studentCollectionView.collectionViewLayout = UICollectionViewFlowLayout()

        //Adding section names to drop down
        for section in sections {
            dropDownValues.append(section.sec)
        }

        //Adding constraints for drop down
        dropDown.anchorView = dropDownView
        dropDown.dataSource = dropDownValues
        dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
        dropDown.topOffset = CGPoint(x: 0, y:-(dropDown.anchorView?.plainView.bounds.height)!)

        //Loads the data of selected Section to collection view
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            self.availableSectionsLabel.setTitle(item, for: .normal)
            if let currSec = realm.object(ofType: Section.self, forPrimaryKey: item) {
                currentSection = currSec
                self.studentCollectionView.reloadData() //Reloads collection view after new section is choosen
            }
        }
        
        //Initial drop down button text
        availableSectionsLabel.setTitle("Section is Empty", for: .normal)
        if !dropDownValues.isEmpty {
            self.availableSectionsLabel.setTitle(dropDownValues.first, for: .normal)
            if let currSec = realm.object(ofType: Section.self, forPrimaryKey: dropDownValues.first) {
                currentSection = currSec
                self.studentCollectionView.reloadData()
            }
        }

        //Gets Student object when new student is added
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: Notification.Name("text"), object: nil)
    }

    override var canBecomeFirstResponder: Bool { //To enable shake gesture
        return true
    }
    
    @IBAction func checkAvailableSections(_ sender: UIButton) {
        dropDown.show() //Presents dropdown on tap
    }

    @objc func didGetNotification(_ notification: Notification) {
        DispatchQueue.main.async { [self] in
            self.studentCollectionView.reloadData() //Reloads collection view when new student is added
        }
    }

    //Adds new section
    @objc func didTapAddSections() {
        let alert = UIAlertController(title: "Add a New Section", message: "" , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addTextField { field in
            field.placeholder = "Section Name"
            field.returnKeyType = .done
            field.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { action in
            guard let field = alert.textFields, field[0].text! != "" else { //Checks if field is empty or not
                let alertWrong = UIAlertController(title: "Incorrect Input", message: "" , preferredStyle: .alert)
                self.present(alertWrong, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                    self.dismiss(animated: true, completion: nil)
                })})
                let feedbackGenerator = UINotificationFeedbackGenerator()
                feedbackGenerator.notificationOccurred(.error)
                return
            }
            let inputSection = field[0]
            if self.realm.object(ofType: Section.self, forPrimaryKey: inputSection.text!) == nil {
                self.realm.beginWrite()
                let newSection = Section()
                newSection.sec = inputSection.text!
                self.realm.add(newSection) //Add a new section to database
                try! self.realm.commitWrite()
                dropDownValues.append(newSection.sec) //Adds new section to dropdown menu
                dropDown.dataSource = dropDownValues
                
                if currentSection.sec.isEmpty { //Automatically switches to new section if the current section is empty
                    currentSection = newSection
                    self.availableSectionsLabel.setTitle(currentSection.sec, for: .normal)
                    self.studentCollectionView.reloadData()
                }
                
                let feedbackGenerator = UINotificationFeedbackGenerator()
                feedbackGenerator.notificationOccurred(.success)
            }
            else { //Checks if section already exists
                let alertController = UIAlertController(title:"Section Already Exists", message:nil, preferredStyle:.alert)
                self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                    self.dismiss(animated: true, completion: nil)
                })})
                let feedbackGenerator = UINotificationFeedbackGenerator()
                feedbackGenerator.notificationOccurred(.error)
            }
        }))
        present(alert, animated: true)
    }

    //Helper function for didTapMarkAttendance and motionEnded(Shake gesture)
    func attendanceMarkHelper(overwrite: Bool, current: DateCalendar, iterator: Int?, dateAvailable: Bool, allowPresent: Bool, title: String, message: String?) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        let alert = UIAlertController(title: title, message: message , preferredStyle: .alert) //Custom message
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { action in
            let newSection = SectionData()
            self.realm.beginWrite()
            if overwrite == true { //If attendance for the section already exists
                current.sectionList[iterator!].students.removeAll()
            } else {
                newSection.sec = currentSection.sec
            }
            for student in currentSection.students {
                let newStudentData = StudentData() //Creates new student
                newStudentData.name = student.name
                newStudentData.roll = student.roll
                newStudentData.email = student.email
                if allowPresent == true { //If function is called by didTapAttendance
                    newStudentData.isPresent = student.isPresent
                    newStudentData.presentTime = student.presentTime
                } else { //If function is called by shake gesture
                    newStudentData.isPresent = true
                    newStudentData.presentTime = "N/A"
                }
                if overwrite == true { //Appends new student data to the same old section
                    current.sectionList[iterator!].students.append(newStudentData)
                } else { //Appends student data to newly created section
                    newSection.students.append(newStudentData)
                }
            }
            try! self.realm.commitWrite()
            if !dateAvailable { //If date is not present(No attendance of any section available for the date)
                self.realm.beginWrite()
                current.sectionList.append(newSection) //Adds the new section to the new date
                self.realm.add(current) //Adds the newly created date to database
                try! self.realm.commitWrite()
            }
            self.realm.beginWrite()
            if overwrite == false && dateAvailable {
                current.sectionList.append(newSection) //Appends the new saction to the which is already present
            }
            try! self.realm.commitWrite()
            feedbackGenerator.notificationOccurred(.success)
        }))
        present(alert, animated: true)
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) { //Marks everyone present by shake gesture
        let feedbackGenerator = UINotificationFeedbackGenerator()
        
        //Checks if current section is not present or current section has no students
        if currentSection.sec.isEmpty || currentSection.students.isEmpty {
            let alertWrong = UIAlertController(title: "Section not choosen or Section is Empty", message: "Please choose a section before marking the attendance and make sure it is not empty." , preferredStyle: .alert)
            self.present(alertWrong, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        if motion == .motionShake { //Checks if motion is of shake type
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MM-YYYY"
            let today = formatter.string(from: cal.today!)
            
            //Three possible cases:-
            //1. Date is already present and section attendance data is already present
            //2. Date is already present and section attendance data is not present
            //3. Date is not present
            let msg = "Do you want to mark all students in the section \"\(currentSection.sec)\" as present?"
            if let current = self.realm.object(ofType: DateCalendar.self, forPrimaryKey: today) {
                var iterator = 0
                while iterator < current.sectionList.count {
                    if current.sectionList[iterator].sec == currentSection.sec { //Case 1
                        attendanceMarkHelper(overwrite: true, current: current, iterator: iterator, dateAvailable: true, allowPresent: false, title: msg, message: nil)
                        return
                    }
                    iterator += 1
                }
                //Case 2
                attendanceMarkHelper(overwrite: false, current: current, iterator: nil, dateAvailable: true, allowPresent: false, title: msg, message: nil)
            } else {
                //Case 3
                let currentDate = DateCalendar()
                currentDate.dateName = today
                attendanceMarkHelper(overwrite: false, current: currentDate, iterator: nil, dateAvailable: false, allowPresent: false, title: msg, message: nil)
            }
        }
    }
    
    @objc func didTapMarkAttendance() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        
        //Checks if current section is not present or current section has no students
        if currentSection.sec.isEmpty || currentSection.students.isEmpty {
            let alertWrong = UIAlertController(title: "Section not choosen or Section is Empty", message: "Please choose a section before marking the attendance and make sure it is not empty." , preferredStyle: .alert)
            self.present(alertWrong, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-YYYY"
        let today = formatter.string(from: cal.today!)
        
        //Three possible cases:-
        //1. Date is already present and section attendance data is already present
        //2. Date is already present and section attendance data is not present
        //3. Date is not present
        if let current = self.realm.object(ofType: DateCalendar.self, forPrimaryKey: today) {
            var iterator = 0
            while iterator < current.sectionList.count {
                if current.sectionList[iterator].sec == currentSection.sec { //Case 1
                    attendanceMarkHelper(overwrite: true, current: current, iterator: iterator, dateAvailable: true, allowPresent: true, title: "Attendance for the section \"\(currentSection.sec)\" already marked. Do you want to update the attendace?", message: "You cannot mark already present students as absent")
                    return
                }
                iterator += 1
            }
            //Case 2
            attendanceMarkHelper(overwrite: false, current: current, iterator: nil, dateAvailable: true, allowPresent: true, title: "Do you want to mark attendance for the section \"\(currentSection.sec)\"?", message: nil)
        } else {
            //Case 3
            let currentDate = DateCalendar()
            currentDate.dateName = today
            attendanceMarkHelper(overwrite: false, current: currentDate, iterator: nil, dateAvailable: false, allowPresent: true, title: "Do you want to mark attendance for the section \"\(currentSection.sec)\"?", message: nil)
        }
    }
    
    //Deletes current Section
    @objc func didTapDelete() {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        guard !currentSection.sec.isEmpty else { //Checks if section is present or not
            let alertController = UIAlertController(title:"Select a Section First", message:nil, preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        let alert = UIAlertController(title: "Are you sure you want to delete the Section?", message: "This would permanently delete the Section and the Students." , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
            var iterator = 0
            while iterator < dropDownValues.count {
                if dropDownValues[iterator] == currentSection.sec {
                    dropDownValues.remove(at: iterator) //Removes current selected section from dropdown
                    break
                }
                iterator += 1
            }
            dropDown.dataSource = dropDownValues //Update data source

            self.realm.beginWrite()
            self.realm.delete(currentSection.students) //Deletes all students of current section
            self.realm.delete(currentSection) //Deletes the current section
            try! self.realm.commitWrite()

            guard let firstSec = sections.first else { //If all sections are removed
                currentSection = Section()
                self.availableSectionsLabel.setTitle("Section is Empty", for: .normal)
                self.studentCollectionView.reloadData()
                feedbackGenerator.notificationOccurred(.success)
                return
            }
            //If atleast one section is present
            currentSection = firstSec
            self.availableSectionsLabel.setTitle(currentSection.sec, for: .normal)
            self.studentCollectionView.reloadData()
            feedbackGenerator.notificationOccurred(.success)
        }))
        present(alert, animated: true)
    }
}

extension StudentDatabaseView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentSection.students.count //Returns count of students in the section
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StudentCollectionViewCell", for: indexPath) as! StudentCollectionViewCell
        cell.setup(with: currentSection.students[indexPath.row])
        return cell //Reusable cell to save memory
    }
}

extension StudentDatabaseView: UICollectionViewDelegateFlowLayout { //Collection view layout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (view.frame.size.width/3)-3, height: (view.frame.size.height/4))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}


//Shows data of student when cell is tapped
extension StudentDatabaseView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let alert = UIAlertController(title: "Name: \(currentSection.students[indexPath.row].name) \n Roll No.: \(currentSection.students[indexPath.row].roll) \n E-Mail: \(currentSection.students[indexPath.row].email)", message: "" , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let image = UIImage(data:currentSection.students[indexPath.row].image! as Data)
        alert.addImage(image: image!)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
            self.realm.beginWrite()
            self.realm.delete(currentSection.students[indexPath.row])
            try! self.realm.commitWrite()
            self.studentCollectionView.reloadData()
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
        }))
        present(alert, animated: true)
    }
}

//To get image in an alert with proper dimensions
extension UIImage {
    func imageWithSize(_ size:CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero

        let aspectWidth:CGFloat = size.width / self.size.width
        let aspectHeight:CGFloat = size.height / self.size.height
        let aspectRatio:CGFloat = min(aspectWidth, aspectHeight)

        scaledImageRect.size.width = self.size.width * aspectRatio
        scaledImageRect.size.height = self.size.height * aspectRatio
        scaledImageRect.origin.x = (size.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (size.height - scaledImageRect.size.height) / 2.0

        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        self.draw(in: scaledImageRect)

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage!
    }
}

// To get image in an alert with proper dimensions
extension UIAlertController {
    func addImage(image: UIImage) {
        let maxSize = CGSize(width: 245, height: 300)
        let imgSize = image.size
        var ratio: CGFloat!
        if (imgSize.width > imgSize.height) {
            ratio = maxSize.width / imgSize.width
        }
        else {
            ratio = maxSize.height / imgSize.height
        }
        let scaledSize = CGSize(width: imgSize.width * ratio, height: imgSize.height * ratio)
        var resizedImage = image.imageWithSize(scaledSize)
        if (imgSize.height > imgSize.width) {
            let left = (maxSize.width - resizedImage.size.width) / 2
            resizedImage = resizedImage.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -left, bottom: 0, right: 0))
            let imgAction = UIAlertAction(title: "", style: .default, handler: nil)
            imgAction.isEnabled = false
            imgAction.setValue(resizedImage.withRenderingMode(.alwaysOriginal),forKey:"image")
            self.addAction(imgAction)
        }
    }
}
