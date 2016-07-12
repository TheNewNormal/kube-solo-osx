//
//  RunShellApps.swift
//  corectl
//
//  Created by Rimantas Mocevicius on 06/07/2016.
//  Copyright © 2016 The New Normal. All rights reserved.
//

import Foundation
import Cocoa


// run script
func runScript(scriptName: String, arguments: String) {
    let task: NSTask = NSTask()
    let launchPath = NSBundle.mainBundle().resourcePath! + "/" + scriptName
    task.launchPath = launchPath
    task.arguments = [arguments]
    task.launch()
    task.waitUntilExit()
}


// run an app
func runApp(appName: String, arguments: String) {
    // lunch an external App
    NSWorkspace.sharedWorkspace().openFile(arguments, withApplication: appName)
}


// shell commands to run
func shell(launchPath: String, arguments: [String]) -> String
{
    let task = NSTask()
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = NSPipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: NSUTF8StringEncoding)!
    if output.characters.count > 0 {
        return output.substringToIndex(output.endIndex.advancedBy(-1))
    }
    return output
}

