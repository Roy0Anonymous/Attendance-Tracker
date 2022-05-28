//
//  CapturePicture.swift
//  ClassRoom Attendance
//
//  Created by Rahul Roy on 13/05/22.
//

import UIKit

class CapturePictureView: UIViewController {
    
    @IBOutlet var displayCapturedImage: UIImageView!
    @IBOutlet var finderText: UILabel!
    @IBOutlet var captureScanButton: UIButton!
    @IBOutlet var detectedOrNot: UIView!
    
    var faceIDArray: [String] = [] //Stores Face ID of Current Section
    var imageFinder: UIImage? = nil //Stores Image on the finder

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Adds Test Section and Students
        if realm.object(ofType: Section.self, forPrimaryKey: "Test Section") == nil {
            let testSection = Section()
            testSection.sec = "Test Section"

            let bill = Student()
            bill.roll = "1"
            bill.name = "Bill Gates"
            bill.email = "billgates@microsoft.com"
            bill.image = UIImage(named: "Bill Gates")?.jpegData(compressionQuality: 0.3)

            let steve = Student()
            steve.roll = "2"
            steve.name = "Steve Jobs"
            steve.email = "stevejobs@apple.com"
            steve.image = UIImage(named: "Steve Jobs")?.jpegData(compressionQuality: 1.0)

            let tim = Student()
            tim.roll = "3"
            tim.name = "Tim Cook"
            tim.email = "timcook@apple.com"
            tim.image = UIImage(named: "Tim Cook")?.jpegData(compressionQuality: 0.5)

            let elon = Student()
            elon.roll = "4"
            elon.name = "Elon Musk"
            elon.email = "elonmusk@tesla.com"
            elon.image = UIImage(named: "Elon Musk")?.jpegData(compressionQuality: 1.0)

            let sundar = Student()
            sundar.roll = "5"
            sundar.name = "Sundar Pichai"
            sundar.email = "sundarpichai@google.com"
            sundar.image = UIImage(named: "Sundar Pichai")?.jpegData(compressionQuality: 1.0)

            testSection.students.append(bill)
            testSection.students.append(steve)
            testSection.students.append(tim)
            testSection.students.append(elon)
            testSection.students.append(sundar)

            realm.beginWrite()
            realm.add(testSection)
            try! realm.commitWrite()
        }
        
        if let secPresent = realm.objects(Section.self).first { //Stores the first section if available
            currentSection = secPresent
        }
        
        let currentConfidence = realm.objects(Confidence.self) //Retrieves confidence level from database
        if !currentConfidence.isEmpty { //If confidence is present then it uses the old confidence value
            confidence = currentConfidence.first!.conf
        } else { //Otherwise it sets the default confidence as 0.7 and adds it to the database
            confidence = 0.7
            realm.beginWrite()
            let newConfidence = Confidence(conf: 0.7)
            realm.add(newConfidence)
            try! realm.commitWrite()
        }
        
        // Do any additional setup after loading the view.
        displayCapturedImage.layer.cornerRadius = 20
        detectedOrNot.layer.cornerRadius = 20
        
        captureScanButton.menu = addMenuItems() //Adds options for long press on Capture/Scan button
        
        //Brings UI Elements forward
        self.view.bringSubviewToFront(displayCapturedImage)
        self.view.bringSubviewToFront(finderText)
    }
    
    //Adds delete button and Image Library button on long press of Capture/Scan button
    func addMenuItems() -> UIMenu {
        let menuItem = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: "Delete", image: UIImage(systemName: "trash"), handler: { _ in
                self.displayCapturedImage.image = nil
                self.captureScanButton.setTitle("Capture", for: .normal)
                self.finderText.text = "Tap on the Capture button to search"
                self.view.backgroundColor = .systemGroupedBackground
            }),
            UIAction(title: "Import from Photos", image: UIImage(systemName: "photo.on.rectangle"), handler: { _ in
                DispatchQueue.main.async { [unowned self] in
                    let vc = UIImagePickerController()
                    vc.sourceType = .photoLibrary
                    vc.delegate = self
                    self.present(vc, animated: true)
                }
            }),
            UIAction(title: "Set Confidence", image: UIImage(systemName: "eye.fill"), handler: { _ in
                let feedbackGenerator = UINotificationFeedbackGenerator()
                let alert = UIAlertController(title: "Set Confidence\nCurrent Confidence: \(confidence)", message: "The confidence should range between 0.1 and 1.0" , preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addTextField { field in
                    field.placeholder = "Confidence"
                    field.returnKeyType = .done
                    field.keyboardType = .decimalPad
                }
                alert.addAction(UIAlertAction(title: "Set", style: .default, handler: { action in
                    guard let field = alert.textFields, field[0].text! != "" else { //Checks if field is empty or not
                        let alertWrong = UIAlertController(title: "Incorrect Input", message: "" , preferredStyle: .alert)
                        self.present(alertWrong, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                            self.dismiss(animated: true, completion: nil)
                        })})
                        feedbackGenerator.notificationOccurred(.error)
                        return
                    }
                    let conf = Float(field[0].text!) ?? 0.0
                    if conf == 0.0 { //Checks if the new confidence value is valid or not
                        let alertWrong = UIAlertController(title: "Incorrect Input", message: "" , preferredStyle: .alert)
                        self.present(alertWrong, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                            self.dismiss(animated: true, completion: nil)
                        })})
                        feedbackGenerator.notificationOccurred(.error)
                    } else if conf < 0.1 || conf > 1.0 { //Checks if the new confidence value is within the range or not
                        let alertWrong = UIAlertController(title: "Out of Range", message: "" , preferredStyle: .alert)
                        self.present(alertWrong, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                            self.dismiss(animated: true, completion: nil)
                        })})
                        feedbackGenerator.notificationOccurred(.error)
                    } else { //Sets the new confidence value and updates it in the database
                        confidence = conf
                        let currentConfidence = realm.objects(Confidence.self)
                        if !currentConfidence.isEmpty
                        {
                            realm.beginWrite()
                            currentConfidence.first?.conf = confidence
                            try! realm.commitWrite()
                        }
                        feedbackGenerator.notificationOccurred(.success)
                    }
                }))
                self.present(alert, animated: true)
            })
        ])
        return menuItem
    }
    
    @IBAction func imageCaptureButton(_ sender: UIButton) {
        if captureScanButton.titleLabel?.text == "Capture" { //Takes image for scanning
            DispatchQueue.main.async { [unowned self] in
                let picker = UIImagePickerController()
                if (UIImagePickerController.isSourceTypeAvailable(.camera)) { //Checks if camera is available or not
                    picker.sourceType = .camera //Displays camera to click pictures of students
                    picker.delegate = self
                    present(picker, animated: true)
                } else { //Prints Error
                    let alertController = UIAlertController(title:"Camera not Available", message:nil, preferredStyle:.alert)
                    self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                        self.dismiss(animated: true, completion: nil)
                    })})
                    return
                }
            }
        } else { //Scans image to mark attendance
            faceIDArray.removeAll() // Removes old face data to remove conflict with other sections
            var studentFaceDic: [String: Student] = [:] // Stores faceid to Student
            
            if currentSection.students.isEmpty { //Checks if current section has students or not
                let alertWrong = UIAlertController(title: "Section not choosen", message: "Section is not choosen or the section is empty.\nIf both are not the case then try adding students in the database again" , preferredStyle: .alert)
                self.present(alertWrong, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 2, repeats:false, block: {_ in
                    self.dismiss(animated: true, completion: nil)
                })})
                let feedbackGenerator = UINotificationFeedbackGenerator()
                feedbackGenerator.notificationOccurred(.error)
                return
            }
            
            let students = currentSection.students //Stores student objects of current section
            let dataOfFinder = imageFinder!.compress(to: 200) //Compress image
            let faceIdOfFinder = AzureFaceRecognition.shared.syncDetectFaceIds(imageData: dataOfFinder as Data) //Extracts all faces from finder(Multiple students supported)
            if faceIdOfFinder.isEmpty { //If no student is detected in the finder
                self.detectedOrNot.backgroundColor = .yellow //Shows yellow color to signify that no student/s were found
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.detectedOrNot.backgroundColor = .systemGroupedBackground
                }
                let alertWrong = UIAlertController(title: "Student Not Found", message: "Please come close to the camera and make sure that your face is clearly visible." , preferredStyle: .alert)
                self.present(alertWrong, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                    self.dismiss(animated: true, completion: nil)
                })})
                let feedbackGenerator = UINotificationFeedbackGenerator()
                feedbackGenerator.notificationOccurred(.error)
                displayCapturedImage.image = nil
                self.finderText.text = "Tap on the Capture button to search"
                captureScanButton.setTitle("Capture", for: .normal)
                return
            }
            
            for student in students { //Extracts Face ID of each student
                guard let image = UIImage(data:student.image! as Data) else {
                    return
                }
                let data = NSData(data: image.jpegData(compressionQuality: 1.0)!) //Image of student/s from student database of current section(Not Compressed)
                //Extracts faces from student database of current section(Only one each image)
                if let faceId = AzureFaceRecognition.shared.syncDetectFaceIds(imageData: data as Data).first {
                    studentFaceDic[faceId] = student
                    self.faceIDArray.append(faceId)
                } else { // If student with invalid Face data is found
                    let alertWrong = UIAlertController(title: "Face data of \(student.name) with Roll number \(student.roll) not found", message: "Please remove the student and add their data again. Make sure to take a clear image" , preferredStyle: .alert)
                    self.present(alertWrong, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 2, repeats:false, block: {_ in
                        self.dismiss(animated: true, completion: nil)
                    })})
                    return
                }
            }
            
            var countPresent = 0 //Counts students which are present
            var countNotPresent = 0 //Counts students which are not present
            var displayedPresent = false //Checks if student found message already shown or not
            
            for face in faceIdOfFinder {//Tries to match each face from the finder
                AzureFaceRecognition.shared.findSimilars(faceId: face, faceIds: self.faceIDArray) { (faceIds) in //Shows matching faces
                    
                    if faceIds.isEmpty {
                        countNotPresent -= 1 //decreased if student was not found
                    } else {
                        countPresent += 1//Increases if student was found
                        if studentFaceDic[faceIds.first!]!.presentTime.isEmpty { //If student found for the first time
                            let date = Date()
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm:ss" //Sets time format
                            realm.beginWrite()
                            studentFaceDic[faceIds.first!]!.isPresent = true //Notes the attendance
                            studentFaceDic[faceIds.first!]!.presentTime = formatter.string(from: date) //Notes the present time
                            try! realm.commitWrite()
                        }
                    }
                    if countPresent == 1 && !displayedPresent { //If atleast one student is found
                        displayedPresent = true //Marks true as one student was found
                        let alertController = UIAlertController(title:"Student/s marked as Present.", message:nil, preferredStyle:.alert)
                        self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                                self.dismiss(animated: true, completion: nil)
                        })})
                        
                        DispatchQueue.main.async { [unowned self] in
                            self.detectedOrNot.backgroundColor = .green //Shows green color to signify that atleast one student was found
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { //Delay of 1.5 seconds before restoring color
                                self.detectedOrNot.backgroundColor = .systemGroupedBackground
                            }
                            let feedbackGenerator = UINotificationFeedbackGenerator()
                            feedbackGenerator.notificationOccurred(.success) //Gives Haptic Feedback for sucess
                        }
                    }
                    if countNotPresent == -faceIdOfFinder.count { //If no student is found out of the detected faces
                        let alertController = UIAlertController(title:"Student/s not found.", message:nil, preferredStyle:.alert)
                        self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                        self.dismiss(animated: true, completion: nil)
                        })})
            
                        DispatchQueue.main.async { [unowned self] in
                            self.detectedOrNot.backgroundColor = .red //Shows red color to signify that no student was found
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { //Delay of 1.5 seconds before restoring color
                                self.detectedOrNot.backgroundColor = .systemGroupedBackground
                            }
                            let feedbackGenerator = UINotificationFeedbackGenerator()
                            feedbackGenerator.notificationOccurred(.error) //Gives Haptic Feedback for error
                        }
                    }
                }
            }
            displayCapturedImage.image = nil //Resets Finder image
            self.finderText.text = "Tap on the Capture button to search" //Resets Finder Text
            captureScanButton.setTitle("Capture", for: .normal) //Shows Capture Button again
        }
    }
}

extension CapturePictureView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        
        self.finderText.text = ""
        captureScanButton.setTitle("Scan", for: .normal)
        
        //For image resize
        let imageData = image.jpegData(compressionQuality: 1.0)
        let maxWidth = 255
        DispatchQueue(label: "com.imagedecode", qos: .userInteractive, attributes: .concurrent).async { [weak self] in
            guard self != nil else {
                return
            }
            if let imageData = imageData, let image = imageData.scaleImageData(toMaximumPixelCount: maxWidth) {
                DispatchQueue.main.async {
                    self!.displayCapturedImage.image = image
                    self!.imageFinder = image
                }
            }
        }
    }
}


// Compress Image
extension UIImage {
    func resized(withPercentage percentage: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }

    func compress(to kb: Int, allowedMargin: CGFloat = 0.2) -> Data {
        let bytes = kb * 1024
        var compression: CGFloat = 1.0
        let step: CGFloat = 0.05
        var holderImage = self
        var complete = false
        while(!complete) {
            if let data = holderImage.jpegData(compressionQuality: 1.0) {
                let ratio = data.count / bytes
                if data.count < Int(CGFloat(bytes) * (1 + allowedMargin)) {
                    complete = true
                    return data
                } else {
                    let multiplier:CGFloat = CGFloat((ratio / 5) + 1)
                    compression -= (step * multiplier)
                }
            }

            guard let newImage = holderImage.resized(withPercentage: compression) else {
                break
            }
            holderImage = newImage
        }
        return Data()
    }
}
