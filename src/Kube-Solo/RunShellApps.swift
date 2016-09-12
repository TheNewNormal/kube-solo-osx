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
func runScript(_ scriptName: String, arguments: String) {
    let task: Process = Process()
    let launchPath = Bundle.main.resourcePath! + "/" + scriptName
    task.launchPath = launchPath
    task.arguments = [arguments]
    task.launch()
    task.waitUntilExit()
}


// run an app
func runApp(_ appName: String, arguments: String) {
    // lunch an external App
    NSWorkspace.shared().openFile(arguments, withApplication: appName)
}


// shell commands to run
func shell(_ launchPath: String, arguments: [String]) -> String
{
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: String.Encoding.utf8)!
    if output.characters.count > 0 {
        return output.substring(to: output.characters.index(output.endIndex, offsetBy: -1))
    }
    return output
}

