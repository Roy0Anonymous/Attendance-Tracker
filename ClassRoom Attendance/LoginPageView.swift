//
//  ViewController.swift
//  ClassRoom Attendance
//
//  Created by Rahul Roy on 13/05/22.
//

import UIKit
import LocalAuthentication
import RealmSwift

class LoginPageView: UIViewController {
    
    let realm = try! Realm()
    
    var context = LAContext()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-YYYY"
        let today = formatter.string(from: cal.today!) //Stores current date
        guard self.realm.object(ofType: DateCalendar.self, forPrimaryKey: today) != nil else { //Checks if it a new date or not
            let allSections = self.realm.objects(Section.self)
            for section in allSections {
                for student in section.students { //Resets isPresent and presentTime for each student of each section
                    self.realm.beginWrite()
                    student.isPresent = false
                    student.presentTime = ""
                    try! self.realm.commitWrite()
                }
            }
            return
        }
    }

    @IBAction func tapToSignIn(_ sender: UIButton) { //Signs in the user of the device(3D face scanning done locally for security reasons)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainTabBarController = storyboard.instantiateViewController(identifier: "MainTabBarController")
        mainTabBarController.modalPresentationStyle = .fullScreen
        context = LAContext()
        context.localizedCancelTitle = "Please Try Again"
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) { //Checks if biometrics is allowed or not
            let reason = "Log in to the App"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                if success { //If sucessful then presents the mainTabBarController which has the other View Controllers
                    DispatchQueue.main.async { [unowned self] in
                        self.present(mainTabBarController, animated: true, completion: nil)
                    }
                } else {//If fails print error
                    print(error?.localizedDescription ?? "Failed to authenticate")
                }
            }
        }
        else { //If fails print error
            print(error?.localizedDescription ?? "Can't evaluate policy")
        }
    }
    
}
