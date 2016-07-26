//
//  Helpers.swift
//  Kube-Solo
//
//  Created by Rimantas Mocevicius on 12/07/2016.
//  Copyright © 2016 Rimantas Mocevicius. All rights reserved.
//

import Foundation
import Cocoa


// to be used from obj-c
@objc class Helpers: NSObject {
    
    // check if app runs from dmg
    func check_for_dmg() {
        // get the App's main bundle path
        let resoucesPathFromApp = NSBundle.mainBundle().resourcePath!
        NSLog("applicationDirectory: '%@'", resoucesPathFromApp)
        //
        let dmgPath: String = "/Volumes/Kube-Solo/Kube-Solo.app/Contents/Resources"
        NSLog("DMG resource path: '%@'", dmgPath)
        // check resourcePath and exit the App if it runs from the dmg
        if resoucesPathFromApp.isEqual(dmgPath) {
            // show alert message
            let mText: String = NSLocalizedString("DmgAlertMessage", comment: "")
            let infoText: String = NSLocalizedString("DmgAlertInformativeText", comment: "")
            displayWithMessage(mText, infoText: infoText)
        
            // exit App
            exit(0)
        }
    }
    
    
    func check_for_corectl_app() {
        
        if  !NSWorkspace.sharedWorkspace().launchApplication("/Applications/corectl.app") &&
            !NSTask.launchedTaskWithLaunchPath("/usr/local/bin/corectld", arguments: ["start])
        {
            NSLog("corectl failed to launch")
            
            // show alert message
            let mText: String = NSLocalizedString("CorectlAppAlertMessage", comment: "")
            let infoText: String = NSLocalizedString("CorectlAppAlertInformativeText", comment: "")
            displayWithMessage(mText, infoText: infoText)
            
            // open corectl.app releases URL
            let url: String = ["https://github.com/TheNewNormal/corectl.app/releases"].componentsJoinedByString("")
            NSWorkspace.sharedWorkspace().openURL(NSURL(string: url)!)
            
            // show quitting App message
          //  self.notifyUserWithTitle(NSLocalizedString("QuittingNotificationTitle"), text: nil)
            let notification: NSUserNotification = NSUserNotification()
            notification.title = "Kube-Solo"
            notification.informativeText = NSLocalizedString("QuittingNotificationTitle", comment: "")
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
            
            // exiting App
            exit(0)
        }
    }

    
    func check_for_home_folder() {
        

    }
    

    // Adds the app to the system's list of login items.
    // NOTE: This is a relatively janky way of doing this. Using a
    // bundled helper app is Apple's recommended approach, but that
    // has a lot of configuration overhead to get right.
    func addToLoginItems() {
        NSTask.launchedTaskWithLaunchPath(
            "/usr/bin/osascript",
            arguments: [
                "-e",
                "tell application \"System Events\" to make login item at end with properties {path:\"/Applications/Kube-Solo.app\", hidden:false, name:\"Kube-Solo\"}"
            ]
        )
    }


// end of class Helpers
}
