//
//  AppDelegate.m
//  Kube-Solo for macOS
//
//  Created by Rimantas on 03/06/2015.
//  Copyright (c) 2015 Rimantas Mocevicius. All rights reserved.
//

#import "AppDelegate.h"
#import "VMManager.h"
#import "NSURL+KubeSolo.h"
#import "Kube_Solo-Swift.h"

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
    
    // check resourcePath and exit the App if it runs from the dmg
    Helpers *run_check_for_dmg = [Helpers new];
    [run_check_for_dmg check_for_dmg];
    
    // check that corectl.app is installed in /Applications folder
    Helpers *run_check_for_corectl_app = [Helpers new];
    [run_check_for_corectl_app check_for_corectl_app];
    
    //check for latest app version and notify user if there is such one
    Updates *run_checkAppVersionGithub = [Updates new];
    [run_checkAppVersionGithub checkAppVersionGithub:@"no"];
    
    // get resourcePath
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSLog(@"App resource path: '%@'", resourcePath);

    // check if the Apps' home folder exits
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSURL ks_homeURL] path] isDirectory:&isDir] && isDir) {
        // write down App's resource path a file
        [resourcePath writeToURL:[NSURL ks_resourcePathURL] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        // write down App's version a file
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        [version writeToURL:[NSURL ks_appVersionURL] atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        [self.vmManager checkVMStatus];
    }
    else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert setMessageText:NSLocalizedString(@"NotSetupAlertMessage", nil)];
        [alert setInformativeText:NSLocalizedString(@"NotSetupAlertInformativeText", nil)];
        [alert setAlertStyle:NSWarningAlertStyle];

        if ([alert runModal] == NSAlertFirstButtonReturn) {
            // OK clicked
            [self initialInstall:self];
        }
        else {
            // Cancel clicked
            [self alertWithMessage:NSLocalizedString(@"SetupAlertMessage", nil) infoText:NSLocalizedString(@"SetupAlertInformativeText", nil)];
        }
    }
}

#pragma mark - Menu Items

- (IBAction)Start:(id)sender {
    // check that corectl.app is installed in /Applications folder
    Helpers *run_check_for_corectl_app = [Helpers new];
    [run_check_for_corectl_app check_for_corectl_app];
    
    // give a few secs for server to start
    DELAY(5);
    
    
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown: {
            BOOL isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSURL ks_homeURL] path] isDirectory:&isDir] && isDir) {
                [self notifyUserWithTitle:NSLocalizedString(@"WillSetupNotificationTitle", nil) text:NSLocalizedString(@"WillSetupNotificationMessage", nil)];
                [self.vmManager start];
            }
            else {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [alert setMessageText:NSLocalizedString(@"NotSetupAlertMessage", nil)];
                [alert setInformativeText:NSLocalizedString(@"NotSetupAlertInformativeText", nil)];
                [alert setAlertStyle:NSWarningAlertStyle];

                if ([alert runModal] == NSAlertFirstButtonReturn) {
                    // OK clicked
                    [self initialInstall:self];
                }
                else {
                    // Cancel clicked
                    [self alertWithMessage:NSLocalizedString(@"SetupAlertMessage", nil) infoText:NSLocalizedString(@"SetupAlertInformativeText", nil)];
                }
            }

            break;
        }

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"VMStateRunning", nil)];
            break;
    }
}

- (IBAction)Stop:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateAlreadyOff", nil)];
            break;
        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"VMStateWillStop", nil)];
            [self.vmManager halt];
            [self notifyUserWithText:NSLocalizedString(@"VMStateStopping", nil)];

            VMStatus vmStatusCheck = VMStatusUp;
            while (vmStatusCheck == VMStatusUp) {
                vmStatusCheck = [self.vmManager checkVMStatus];
                if (vmStatusCheck == VMStatusDown) {
                    [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
                    break;
                }
                else {
                    [self.vmManager kill];
                }
            }
            break;
    }
}

- (IBAction)Restart:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"VMStateWillReload", nil)];
            [self.vmManager reload];
            break;
    }
}

- (IBAction)update_k8s:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp:
            [self notifyUserWithTitle:NSLocalizedString(@"KubernetesUpdateNotificationTitle", nil) text:NSLocalizedString(@"KubernetedUpdateNotificationMessage", nil)];
            [self.vmManager updateKubernetes];
            break;
    }
}

- (IBAction)update_k8s_version:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;
        case VMStatusUp:
            [self notifyUserWithTitle:NSLocalizedString(@"KubernetesUpdateNotificationTitle", nil) text:NSLocalizedString(@"KubernetesVersionChangeNotificationMessage", nil)];
            [self.vmManager updateKubernetesVersion];
            break;
    }
}

- (IBAction)updates:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"ClientsWillBeUpdatedNotificationMessage", nil)];
            [self.vmManager updateClients];
            break;
    }
}

- (IBAction)checkForAppUpdates:(id)sender {
    //check for latest app version and notify user if there is such one
    Updates *run_checkAppVersionGithub = [Updates new];
    [run_checkAppVersionGithub checkAppVersionGithub:@"yes"];
}


- (IBAction)changeReleaseChannel:(id)sender {
    [self notifyUserWithText:NSLocalizedString(@"ReleaseChannelChangeNotificationMessage", nil)];
    [self.vmManager changeReleaseChannel];
}


- (IBAction)changeVMRAM:(id)sender {
    [self notifyUserWithText:NSLocalizedString(@"VMRAMChangeNotificationMessage", nil)];
    [self.vmManager changeVMRAM];
}


- (IBAction)enableNFS:(id)sender {
    [self notifyUserWithText:NSLocalizedString(@"NFSChangeNotificationMessage", nil)];
    [self.vmManager changeNFSsettings];
}


- (IBAction)destroy:(id)sender {
    [self notifyUserWithText:NSLocalizedString(@"VMStateWillDestroy", nil)];
    [self.vmManager destroy];
    VMStatus status = [self.vmManager checkVMStatus];
    switch (status) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateStopped", nil)];
            break;
        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"VMStateRunning", nil)];
            break;
    }
}


- (IBAction)initialInstall:(id)sender {
    BOOL isDir;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSURL ks_homeURL] path] isDirectory:&isDir] && isDir) {
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"HomeFolderExistsAlertInformativeText", nil), [[NSURL ks_homeURL] path]];
        [self alertWithMessage:NSLocalizedString(@"AppName", nil) infoText:msg];
    }
    else {
        NSLog(@"Folder does not exist: '%@'", [NSURL ks_homeURL]);
        [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL ks_envURL] withIntermediateDirectories:YES attributes:nil error:nil];

        NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
        [resourcePath writeToURL:[NSURL ks_resourcePathURL] atomically:YES encoding:NSUTF8StringEncoding error:nil];

        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        [version writeToURL:[NSURL ks_appVersionURL] atomically:YES encoding:NSUTF8StringEncoding error:nil];

        [self.vmManager install];
    }
}


- (IBAction)About:(id)sender {
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"AboutAlertMessage", nil), version];
    NSString *infoText = NSLocalizedString(@"AboutInformativeText", nil);

    [self alertWithMessage:message infoText:infoText];
}


- (IBAction)runShell:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"ShellWillOpenNotificationMessage", nil)];
            [self.vmManager runShell];
            break;
    }
}

- (IBAction)runSsh:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"SSHShellWillOpenNotificationMessage", nil)];
            [self.vmManager runSSH];
            break;
    }
}

- (IBAction)KubernetesUI:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
            break;

        case VMStatusUp: {
            NSString *vmIP = [NSString stringWithContentsOfURL:[NSURL ks_ipAddressURL] encoding:NSUTF8StringEncoding error:nil];
            NSString *url = [NSString stringWithFormat:@"http://%@:8080/ui", vmIP];
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
            break;
        }
    }
}


- (IBAction)quit:(id)sender {
    VMStatus vmStatus = [self.vmManager checkVMStatus];

    switch (vmStatus) {
        case VMStatusDown:
            break;

        case VMStatusUp:
            [self notifyUserWithText:NSLocalizedString(@"VMStateWillStop", nil)];
            [self.vmManager halt];
            [self notifyUserWithText:NSLocalizedString(@"VMStateStopping", nil)];

            VMStatus vmStatusCheck = VMStatusUp;
            while (vmStatusCheck == VMStatusUp) {
                vmStatusCheck = [self.vmManager checkVMStatus];
                if (vmStatusCheck == VMStatusDown) {
                    [self notifyUserWithText:NSLocalizedString(@"VMStateOff", nil)];
                    break;
                }
                else {
                    [self.vmManager kill];
                }
            }
            break;
    }

    [self notifyUserWithTitle:NSLocalizedString(@"QuittingNotificationTitle", nil) text:nil];

    [[NSApplication sharedApplication] terminate:self];
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
    [self notifyUserWithTitle:NSLocalizedString(@"AppName", nil) text:text];
}

- (void)alertWithMessage:(NSString *)message infoText:(NSString *)infoText {
    NSAlert *alert = [[NSAlert alloc] init];

    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:message];
    [alert setInformativeText:infoText];
    [alert runModal];
}

@end
