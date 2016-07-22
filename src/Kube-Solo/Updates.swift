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
    
    func checkAppVersionGithub(showPopUp:String?=nil) {
        // get latest github version
        let script = NSBundle.mainBundle().resourcePath! + "/check_app_version_github.command"
        let latest_app_version = shell(script, arguments: [])
        print("latest app version: " + latest_app_version)
        //
        if (latest_app_version == "" ) {
            NSLog("Cannot check latest version on Github, must be API limit was reached or other Github tecnnical issues !!!")
            return
        }
        
        // get installed App version
        let installed_app_version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString")as? String
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
            // show alert message
            let mText: String = NSLocalizedString("AppUpdateMessage", comment: "")
            let infoText: String = NSLocalizedString("AppUpdatenformativeText", comment: "")
            displayWithMessage(mText, infoText: infoText)
            
            // open kube-solo.app releases URL
            let url: String = ["https://github.com/TheNewNormal/kube-solo-osx/releases"].componentsJoinedByString("")
            NSWorkspace.sharedWorkspace().openURL(NSURL(string: url)!)
        }
    }
    
    
    
    // testing function which returns string
    func sayHello(name: String) -> String {
        let nameForGreeting = name.characters.count == 0 ? "World" : name;
        let greeting = "Hello " + nameForGreeting + "!";
        return greeting;
    }
    
}