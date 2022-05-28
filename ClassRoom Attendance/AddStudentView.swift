//
//  AddStudentView.swift
//  ClassRoom Attendance
//
//  Created by Rahul Roy on 14/05/22.
//

import UIKit

class AddStudentView: UIViewController {

    @IBOutlet var studentImageView: UIImageView!
    @IBOutlet var studentName: UITextField!
    @IBOutlet var studentRoll: UITextField!
    @IBOutlet var studentEmail: UITextField!
    @IBOutlet var captureButton: UIButton!
    
    var hasImage = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        studentImageView.layer.cornerRadius = 100
        
        captureButton.layer.cornerRadius = 0.5 * captureButton.bounds.size.width
        captureButton.clipsToBounds = true
        
        studentName.delegate = self
        studentRoll.delegate = self
        studentEmail.delegate = self
        
        captureButton.menu = addMenuItems()
    }
    
    //Adds Image Library button on long press of Capture button
    func addMenuItems() -> UIMenu {
        let menuItem = UIMenu(title: "", options: .displayInline, children: [
            UIAction(title: "Import from Photos", image: UIImage(systemName: "photo.on.rectangle"), handler: { _ in
                DispatchQueue.main.async { [unowned self] in
                    let vc = UIImagePickerController()
                    vc.sourceType = .photoLibrary
                    vc.delegate = self
                    self.present(vc, animated: true)
                }
            })
        ])
        return menuItem
    }
    
    //Function to capture Image
    @IBAction func captureImage(_ sender: UIButton) {
        hasImage = false
        DispatchQueue.main.async { [unowned self] in
            let picker = UIImagePickerController()
            if (UIImagePickerController.isSourceTypeAvailable(.camera)) { //Checks if camera is available
                picker.sourceType = .camera
                picker.delegate = self
                present(picker, animated: true)
            } else { //Shows error
                let alertController = UIAlertController(title:"Camera not Available", message:nil, preferredStyle:.alert)
                self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                    self.dismiss(animated: true, completion: nil)
                })})
                return
            }
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        if currentSection.sec.isEmpty { //Checks if any section is present or not
            let alertController = UIAlertController(title:"Choose a Section First", message:nil, preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            dismiss(animated: true, completion: nil)
            feedbackGenerator.notificationOccurred(.success)
            return
        }
        let text = studentRoll.text
        if realm.object(ofType: Student.self, forPrimaryKey: text) == nil { //Checks if roll number already exists or not
            save()
        }
        else { //Shows error
            let alertController = UIAlertController(title:"Student already Exists", message:nil, preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
    }
    
    func save()
    {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        guard let name = studentName.text, !name.isEmpty else { //Checks if name is empty or not
            let alertController = UIAlertController(title:"Name can't be blank.", message:nil, preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        guard let roll = studentRoll.text, !roll.isEmpty else { //Checks if roll number is empty or not
            let alertController = UIAlertController(title:"Roll No. can't be blank.", message:nil, preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        guard let email = studentEmail.text, !email.isEmpty else { //Checks if email id is empty or not
            let alertController = UIAlertController(title:"Email can't be blank.", message:nil, preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        guard let image: UIImage = studentImageView.image, hasImage else { //Checks if student image is empty or not
            let alertController = UIAlertController(title:"Image can't be blank.", message:nil, preferredStyle:.alert)
            self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                self.dismiss(animated: true, completion: nil)
            })})
            feedbackGenerator.notificationOccurred(.error)
            return
        }
        
        for character in roll { //Checks if all characters or roll number are numbers or not(Faced issue while storing roll number as integer)
            if !(character >= "0" && character <= "9") {
                let alertController = UIAlertController(title:"Invalid Roll Number.", message:nil, preferredStyle:.alert)
                self.present(alertController, animated:true, completion:{Timer.scheduledTimer(withTimeInterval: 1, repeats:false, block: {_ in
                    self.dismiss(animated: true, completion: nil)
                })})
                feedbackGenerator.notificationOccurred(.error)
                return
            }
        }
        let student = Student()
        let nsdata = NSData(data: image.jpegData(compressionQuality: 1.0)!)
        if (Double(nsdata.count)/1000.0) > 300.0 { //If student image is more than 300kb (To avoid destroying lower quality images)
            student.image = image.compress(to: 200) //Compresses the image
        } else {
            student.image = image.jpegData(compressionQuality: 1.0)
        }
        
        student.name = name
        student.roll = roll
        student.email = email
        realm.beginWrite()
        currentSection.students.append(student) //Adds new student to current section
        try! realm.commitWrite()
        
        NotificationCenter.default.post(name: Notification.Name("text"), object: "Yes") //Sends notification to reload the collection view to update the section
        
        dismiss(animated: true, completion: nil)
        feedbackGenerator.notificationOccurred(.success)
    }
}

extension AddStudentView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if studentImageView.image?.jpegData(compressionQuality: 1.0) != UIImage(named: "user")?.jpegData(compressionQuality: 1.0)
        {
            hasImage = true
        }
        picker.dismiss(animated: true, completion: nil) //Dismisses picker
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        
        let nsdata = NSData(data: image.jpegData(compressionQuality: 1.0)!) //converts image to NSData

        if (Double(nsdata.count)/1000.0) > 300.0 { //If student image is more than 300kb
            //Resizes the image
            let imageData = image.jpegData(compressionQuality: 1.0)
            let maxWidth = 255
            DispatchQueue(label: "com.imagedecode", qos: .userInteractive, attributes: .concurrent).async { [weak self] in
                guard self != nil else {
                    return
                }
                if let imageData = imageData, let image = imageData.scaleImageData(toMaximumPixelCount: maxWidth) {
                    DispatchQueue.main.async {
                        self!.studentImageView.image = image
                    }
                }
            }
        } else {
            studentImageView.image = image //Saves the image as it is
        }
        hasImage = true
    }
}

extension AddStudentView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.switchBasedNextTextField(textField)
        return true
    }
    func switchBasedNextTextField(_ textField: UITextField) { //Keyboard enter button switches fields
        switch textField {
        case self.studentName:
            self.studentRoll.becomeFirstResponder()
        case self.studentRoll:
            self.studentEmail.becomeFirstResponder()
        default:
            self.studentEmail.resignFirstResponder()
            saveButton("Saves Student Data")
        }
    }
}
