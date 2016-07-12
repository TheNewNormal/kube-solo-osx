//
//  Notifications.swift
//  corectl
//
//  Created by Rimantas Mocevicius on 06/07/2016.
//  Copyright © 2016 The New Normal. All rights reserved.
//

import Foundation
import Cocoa

// notifications
func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
    return true
}


func displayWithMessage(mText: String, infoText: String) {
    let alert: NSAlert = NSAlert()
    // alert.alertStyle = NSInformationalAlertStyle
    // alert.icon = NSImage(named: "coreos-wordmark-vert-color")
    alert.messageText = mText
    alert.informativeText = infoText
    alert.runModal()
}

