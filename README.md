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

## Known Bugs
- Calendar Event does not get updated immediately sometimes (It can be fixed by reopening the app)
- Errors not handled for the case when the "Test Section" is deleted and new section with students with Roll Numbers between 1 to 5 is created. App throws error after it is reopened in this case (Can be fixed by commenting Test Section creation lines OR Reserving Roll Numbers for Test Section OR Assigning Roll Numbers which are not used(Time Consuming)) 
