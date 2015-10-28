//
//  AppDelegate.m
//  Kube-Solo for OS X
//
//  Created by Rimantas on 03/06/2015.
//  Copyright (c) 2015 Rimantas Mocevicius. All rights reserved.
//

#import "AppDelegate.h"
#import "VMManager.h"

@interface AppDelegate ()

@property (nonatomic, strong) VMManager *vmManager;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    self.vmManager = [[VMManager alloc] init];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    [self.statusItem setImage: [NSImage imageNamed:@"StatusItemIcon"]];
    [self.statusItem setHighlightMode:YES];

    NSString *homeDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo"];
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:homeDirectory isDirectory:&isDir] && isDir) {
        NSData *resourceData = [[[NSBundle mainBundle] resourcePath] dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:[homeDirectory stringByAppendingPathComponent:@".env/resouces_path"] contents:resourceData attributes:nil];

        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSData *appVersion = [version dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:[homeDirectory stringByAppendingPathComponent:@".env/version"] contents:appVersion attributes:nil];
        [self.vmManager checkVMStatus];
    }
    else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:@"Kube-Solo was not set."];
        [alert setInformativeText:@"Do you want to set it up?"];
        [alert setAlertStyle:NSWarningAlertStyle];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked
            [self initialInstall:self];
        }
        else {
            // Cancel clicked
            NSString *msg = [NSString stringWithFormat:@"%@ ", @" 'Initial setup of Kube-Solo' at any time later one !!! "];
            [self displayWithMessage:@"You can set Kube-Solo from menu 'Setup':" infoText:msg];
        }
    }
}

#pragma mark - Menu Items

- (IBAction)Start:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown: {
            NSLog(@"VM is Off");
            NSString *homeDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo"];

            BOOL isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:homeDirectory isDirectory:&isDir] && isDir) {
                [self notifyUserWithTitle:@"Kube Solo will be up shortly" text:@"and OS shell will be opened"];
                [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"up.command"]];
            }
            else {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:@"OK"];
                [alert addButtonWithTitle:@"Cancel"];
                [alert setMessageText:@"Kube Solo was not set."];
                [alert setInformativeText:@"Do you want to set it up?"];
                [alert setAlertStyle:NSWarningAlertStyle];

                if ([alert runModal] == NSAlertFirstButtonReturn) {
                    // OK clicked
                    [self initialInstall:self];
                }
                else {
                    // Cancel clicked
                    NSString *msg = [NSString stringWithFormat:@"%@ ", @" 'Initial setup of Kube Solo' at any time later one !!! "];
                    [self displayWithMessage:@"You can set VM from menu 'Setup':" infoText:msg];
                }
            }

            break;
        }

        case VMStatusUp:
            NSLog(@"VM is On");
            [self notifyUserWithText:@"VM is already running !!!"];
            break;
    }
}

- (IBAction)Stop:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is already Off !!!"];
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            [self notifyUserWithText:@"VM will be stopped"];

            [self runScript:@"halt" arguments:@""];

            [self notifyUserWithText:@"VM is stopping !!!"];

            VMStatus vmStatusCheck = VMStatusUp;
            while (vmStatusCheck == VMStatusUp) {
                vmStatusCheck = [self.vmManager checkVMStatus];
                if (vmStatusCheck == VMStatusDown) {
                    [self notifyUserWithText:@"VM is OFF !!!"];
                    break;
                }
                else {
                    [self runScript:@"kill_VM" arguments:@""];
                }
            }
            break;
    }
}

- (IBAction)Restart:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is Off !!!"];
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            [self notifyUserWithText:@"VM will be reloaded"];
            [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"reload.command"]];
            break;
    }
}

- (IBAction)update_k8s:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is Off !!!"];
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            [self notifyUserWithTitle:@"Kube-Solo and" text:@"OS X kubectl will be updated"];
            [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"update_k8s.command"]];
            break;
    }
}

- (IBAction)update_k8s_version:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is Off !!!"];
            break;
        case VMStatusUp:
            NSLog(@"VM is On");
            [self notifyUserWithTitle:@"Kube-Solo and" text:@"OS X kubectl version will be changed"];
            [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"update_k8s_version.command"]];
            break;
    }
}

- (IBAction)updates:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is Off !!!"];
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            [self notifyUserWithText:@"OS X clients will be updated"];
            [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"update_osx_clients_files.command"]];
            break;
    }
}

- (IBAction)fetchLatestISO:(id)sender {
    [self notifyUserWithText:@"CoreOS ISO image will be updated"];
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"fetch_latest_iso.command"]];
}

- (IBAction)changeReleaseChannel:(id)sender {
    [self notifyUserWithText:@"CoreOS release channel change"];
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"change_release_channel.command"]];
}

- (IBAction)destroy:(id)sender {
    [self notifyUserWithText:@"VM will be destroyed"];
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"destroy.command"]];
    [self.vmManager showVMStatus];
}

- (IBAction)initialInstall:(id)sender {
    NSString *homeDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo"];
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:homeDirectory isDirectory:&isDir] && isDir) {
        NSString *msg = [NSString stringWithFormat:@"%@ %@ %@", @"Folder", homeDirectory, @"exists, please delete or rename that folder !!!"];
        [self displayWithMessage:@"Kube-Solo" infoText:msg];
    }
    else {
        NSLog(@"Folder does not exist: '%@'", homeDirectory);
        NSString *envDirectory = [homeDirectory stringByAppendingPathComponent:@".env"];
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:envDirectory withIntermediateDirectories:YES attributes:nil error:&error];

        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSData *appVersion = [version dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/version"] contents:appVersion attributes:nil];

        NSData *resourcesPath = [[[NSBundle mainBundle] resourcePath] dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/resouces_path"] contents:resourcesPath attributes:nil];

        [self runScript:@"kube-solo-install" arguments:[[NSBundle mainBundle] resourcePath]];
    }
}

- (IBAction)About:(id)sender {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *appVersion = [NSString stringWithFormat:@"%@%@", @"v", version];

    NSString *message = [NSString stringWithFormat:@"%@ %@", @"Kube-Solo for OS X", appVersion];
    NSString *infoText = @"It is a simple wrapper around xhyve + CoreOS VM, which allows to control Kube-Solo via Status Bar !!!";

    [self displayWithMessage:message infoText:infoText];
}

- (IBAction)attachConsole:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is Off !!!"];
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            [self notifyUserWithText:@"VM's console will be opened"];
            [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"console.command"]];
            break;
    }
}

- (IBAction)runShell:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is Off !!!"];
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            [self notifyUserWithText:@"OS X shell will be opened"];
            [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"os_shell.command"]];
            break;
    }
}

- (IBAction)runSsh:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is Off !!!"];
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            [self notifyUserWithText:@"VM ssh shell will be opened"];
            [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ssh.command"]];
            break;
    }
}

- (IBAction)fleetUI:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is Off !!!"];
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/ip_address"];
            // read IP from file
            NSString *vmIP = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
            NSString *url = [@[@"http://", vmIP, @":3000"] componentsJoinedByString : @""];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
            break;
    }
}

- (IBAction)KubernetesUI:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is Off !!!"];
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/ip_address"];
            // read IP from file
            NSString *vmIP = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
            NSString *url = [@[@"http://", vmIP, @":8080/ui"] componentsJoinedByString : @""];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
            break;
    }
}

- (IBAction)node1_cAdvisor:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            [self notifyUserWithText:@"VM is Off !!!"];
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/ip_address"];
            // read IP from file
            NSString *vmIP = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
            NSString *url = [@[@"http://", vmIP, @":4194"] componentsJoinedByString : @""];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
            break;
    }
}

- (IBAction)quit:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            NSLog(@"VM is Off");
            break;

        case VMStatusUp:
            NSLog(@"VM is On");
            [self notifyUserWithText:@"VM will be stopped"];
            [self runScript:@"halt" arguments:@""];
            [self notifyUserWithText:@"VM is stopping !!!"];

            VMStatus vmStatusCheck = VMStatusUp;
            while (vmStatusCheck == VMStatusUp) {
                vmStatusCheck = [self.vmManager checkVMStatus];
                if (vmStatusCheck == VMStatusDown) {
                    [self notifyUserWithText:@"VM is OFF !!!"];
                    break;
                }
                else {
                    [self runScript:@"kill_VM" arguments:@""];
                }
            }
            break;
    }

    [self notifyUserWithTitle:@"Quitting Kube-Solo App" text:@""];

    exit(0);
}

#pragma mark - NSUserNotificationCenterDelegate

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

#pragma mark - Helpers

- (void)notifyUserWithTitle:(NSString *_Nullable)title text:(NSString *_Nullable)text {
    NSUserNotification *notification = [[NSUserNotification alloc] init];

    notification.title = title;
    notification.informativeText = text;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)notifyUserWithText:(NSString *_Nullable)text {
    [self notifyUserWithTitle:@"Kube Solo" text:text];
}
- (void)runScript:(NSString *)scriptName arguments:(NSString *)arguments {
    NSTask *task = [[NSTask alloc] init];

    task.launchPath = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:scriptName ofType:@"command"]];
    task.arguments  = @[arguments];
    [task launch];
    [task waitUntilExit];
}

- (void)runApp:(NSString *)appName arguments:(NSString *)arguments {
    // lunch an external App from the mainBundle
    [[NSWorkspace sharedWorkspace] openFile:arguments withApplication:appName];
}

- (void)displayWithMessage:(NSString *)mText infoText:(NSString *)infoText {
    NSAlert *alert = [[NSAlert alloc] init];

    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:mText];
    [alert setInformativeText:infoText];
    [alert runModal];
}

@end
