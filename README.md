# Attendance-Tracker

## Requirement
- Latest MacOS and XCode Recommended
- iOS 15.0 or above required

## Prerequisite

1. Install [HomeBrew](https://brew.sh)
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
2. Run these commands after installation to add brew to your path
```
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/test/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```
3. Install CocoaPods
```
brew install cocoapods
```

## Setup

1. Clone the repository
2. Open terminal in the cloned directory
3. Use this command to install dependencies
```
pod install
```
4. Open 
> ClassRoom Attendance.xcworkspace

Note:- Do not use the ClassRoom Attendance.xcodeproj

5. Click on
> ClassRoom Attendance > Again click ClassRoom Attendance under Targets > Signing and Capibilities > Change Team to your current Apple ID(It must be a Developer Account)

6. Now select the device from the top (Physical device is highly recommended instead of an emulator) and build it.

## Features

1. 3D Face ID secure for secure login (on iPhone X and later except iPhone SE models)
2. Confidence level can be set manually
3. Students can be added via the camera or photos
4. Green, red or yellow indicator depending upon if student is present in the section, student is not present in the section, student is not detected respectively
5. Multiple Face Support
6. Students with invalid images in the student database are automatically detected and their names and roll numbers are mentioned during face scan
7. Multiple Section Support
8. Faces with Masks supported
9. Multiple Date Support
10. No two sections and roll numbers(in any section) can be same at a time
11. Functional Calendar with dates marked with a dot which has attendace of atleast one section
12. Past Student attendance data can be accessed through the Calendar
13. Student attendance automatically resets at 12:00AM in the morning but the old attendance (if saved, remains in the calendar)
14. Robust as all possible cases for each feature have been properly thought before implementation (and tested well after implementing)
15. Export CSV file for each section and keep a track of attendance of every single day just through one app
16. Students attendace as well as time of arrival is properly mention in the output CSV file
17. SHAKE FEATURE to mark everyone as present for days when the teacher does not want to take the class (Happens with everyone)
18. Haptics are implemented throughout the UI
19. Light and Dark mode are supported
20. Offline Face Recognition(for login) and database is choosen for Data Security
21. Test Section has been provided for easy evaluation

## Known Bugs

- Calendar Event does not get updated immediately sometimes (It can be fixed by reopening the app)
- Errors not handled for the case when the "Test Section" is deleted and new section with students with Roll Numbers between 1 to 5 is created. App throws error after it is reopened in this case (Can be fixed by commenting Test Section creation lines OR Reserving Roll Numbers for Test Section OR Assigning Roll Numbers which are not used(Time Consuming)) 
