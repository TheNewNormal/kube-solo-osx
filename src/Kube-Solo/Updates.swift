//
//  Updates.swift
//  Kube-Solo
//
//  Created by Rimantas Mocevicius on 12/07/2016.
//  Copyright © 2016 Rimantas Mocevicius. All rights reserved.
//

import Foundation
import Cocoa

// to be used from obj-c
@objc class Updates: NSObject {
    
    func checkAppVersionGithub(_ showPopUp:String?=nil) {
        // get latest github version
        let script = Bundle.main.resourcePath! + "/check_app_version_github.command"
        let latest_app_version = shell(script, arguments: [])
        print("latest app version: " + latest_app_version)
        //
        if (latest_app_version == "" ) {
            NSLog("Cannot check latest version on Github, must be API limit was reached or other Github tecnnical issues !!!")
            return
        }
        
        // get installed App version
        let installed_app_version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")as? String
        print("installed app version: " + installed_app_version!)
        
        if (latest_app_version == "v" + installed_app_version!){
            if (showPopUp == "yes") {
                // show alert message
                let mText: String = NSLocalizedString("NoAppUpdateMessage", comment: "")
                let infoText: String = NSLocalizedString("NoAppUpdatenformativeText", comment: "")
                displayWithMessage(mText, infoText: infoText)
            }
            else {
                NSLog("App is up-to-date!!!")
            }
        }
        else {
            NSLog("App has the update!!!")
            // show popup on the screen
            let alert: NSAlert = NSAlert()
            alert.messageText = NSLocalizedString("AppUpdateMessage", comment: "")
            alert.informativeText = NSLocalizedString("AppUpdatenformativeText", comment: "")
            alert.alertStyle = NSAlertStyle.warning
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == NSAlertFirstButtonReturn {
                // if OK clicked
                // open kube-solo.app releases URL in default browser
                let url: String = NSLocalizedString("AppReleaseURL", comment: "")
                NSWorkspace.shared().open(URL(string: url)!)
            }
            else {
                // Cancel was pressed
                NSLog("App update was canceled !!!")
            }
        }
    }
    
    
    
    // testing function which returns string
    func sayHello(_ name: String) -> String {
        let nameForGreeting = name.characters.count == 0 ? "World" : name;
        let greeting = "Hello " + nameForGreeting + "!";
        return greeting;
    }
    
}
