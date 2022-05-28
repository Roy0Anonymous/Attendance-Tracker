//
//  StudentClass.swift
//  ClassRoom Attendance
//
//  Created by Rahul Roy on 13/05/22.
//

import Foundation
import RealmSwift

let realm = try! Realm()

class Student: Object, Identifiable { //Current available students data
    @Persisted var name: String = ""
    @Persisted var email: String = ""
    @Persisted var roll: String = ""
    @Persisted var presentTime: String = ""
    @Persisted var image: Data?
    @Persisted var isPresent: Bool = false
    convenience init(name: String, email: String, roll: String, isPresent: Bool) {
        self.init()
        self.name = name
        self.email = email
        self.roll = roll
        self.isPresent = isPresent
    }
    //Roll Number set as primary key so that only one student with a roll number can exists at a particular time
    override static func primaryKey() -> String? {
        return "roll"
    }
}

class Section: Object, Identifiable { //Current available section data
    @Persisted var sec: String = ""
    @Persisted var students = List<Student>()
    convenience init(sec: String) {
        self.init()
        self.sec = sec
    }
    //Section set as primary key so that only one Section with a particular name can exists at a particular time
    override static func primaryKey() -> String? {
        return "sec"
    }
}

class StudentData: Object, Identifiable { //Student Data for attendance purpose
    @Persisted var name: String = ""
    @Persisted var email: String = ""
    @Persisted var roll: String = ""
    @Persisted var presentTime: String = ""
    @Persisted var isPresent: Bool = false
    convenience init(name: String, email: String, roll: String, isPresent: Bool) {
        self.init()
        self.name = name
        self.email = email
        self.roll = roll
        self.isPresent = isPresent
    }
    //No primary key because each date can contain sections which has the same student
}

class SectionData: Object, Identifiable { //Section Data for attendance purpose
    @Persisted var sec: String = ""
    @Persisted var students = List<StudentData>()
    convenience init(sec: String) {
        self.init()
        self.sec = sec
    }
    //No primary key because each date can contain the same section
}

class DateCalendar: Object, Identifiable { //Date to store the attendances of each day
    @Persisted var dateName: String = ""
    @Persisted var sectionList = List<SectionData>()
    convenience init(dateName: String) {
        self.init()
        self.dateName = dateName
    }
    override static func primaryKey() -> String? { //Date set as primary key because only one date with same name can exist at a time
        return "dateName"
    }
}

class Confidence: Object, Identifiable { //Confidence Level for recognition
    @Persisted var conf: Float = 0.0
    convenience init(conf: Float) {
        self.init()
        self.conf = conf
    }
}

let sections = realm.objects(Section.self) //section objects
