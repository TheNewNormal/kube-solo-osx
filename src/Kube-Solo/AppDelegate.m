//
//  AppDelegate.m
//  Kube-Solo for OS X
//
//  Created by Rimantas on 03/06/2015.
//  Copyright (c) 2015 Rimantas Mocevicius. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    [self.statusItem setImage: [NSImage imageNamed:@"icon"]];
    [self.statusItem setHighlightMode:YES];
    
    // get the App's main bundle path
    _resoucesPathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@""];
    NSLog(@"applicationDirectory: '%@'", _resoucesPathFromApp);

    NSString *home_folder = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo"];
    
    BOOL isDir;
    if([[NSFileManager defaultManager] fileExistsAtPath:home_folder isDirectory:&isDir] && isDir)
    // if kube-solo folder exists
    {
        // set resouces_path
        NSString *resources_content = _resoucesPathFromApp;
        NSData *fileContents1 = [resources_content dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/resouces_path"]
                                                contents:fileContents1
                                              attributes:nil];

        // write to file App version
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSData *app_version = [version dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/version"]
                                                contents:app_version
                                              attributes:nil];
        [self checkVMStatus];
            
    }
    else
    {
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
        else
        {
            // Cancel clicked
            NSString *msg = [NSString stringWithFormat:@"%@ ", @" 'Initial setup of Kube-Solo' at any time later one !!! "];
            [self displayWithMessage:@"You can set Kube-Solo from menu 'Setup':" infoText:msg];
        }
    }
}


- (IBAction)Start:(id)sender {
    int vm_status=[self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        ////
        NSString *home_folder = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo"];
        
        BOOL isDir;
        if([[NSFileManager defaultManager]
            fileExistsAtPath:home_folder isDirectory:&isDir] && isDir)
        {
            // send a notification on to the screen
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Kube Solo will be up shortly";
            notification.informativeText = @"and OS shell will be opened";
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            
            NSString *appName = [[NSString alloc] init];
            NSString *arguments = [[NSString alloc] init];
            [self runApp:appName = @"iTerm" arguments:arguments = [_resoucesPathFromApp stringByAppendingPathComponent:@"up.command"]];
        }
        else
        {
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
            else
            {
                // Cancel clicked
                NSString *msg = [NSString stringWithFormat:@"%@ ", @" 'Initial setup of Kube Solo' at any time later one !!! "];
                [self displayWithMessage:@"You can set VM from menu 'Setup':" infoText:msg];
            }
        }
    }
    else
    {
        NSLog (@"VM is On");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is already running !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    
}


- (IBAction)Stop:(id)sender {
    int vm_status = [self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is already Off !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else
    {
        NSLog (@"VM is On");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM will be stopped";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        NSString *scriptName = [[NSString alloc] init];
        NSString *arguments = [[NSString alloc] init];
        [self runScript:scriptName = @"halt" arguments:arguments = @""];
        
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is stopping !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        int vm_status_check = 1;
        while (vm_status_check == 1 ) {
            vm_status_check = [self checkVMStatus];
            if (vm_status_check == 0) {
                notification.title = @"Kube Solo";
                notification.informativeText = @"VM is OFF !!!";
                [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
                break;
            }
        }
    }
    
}


- (IBAction)Restart:(id)sender {
    int vm_status=[self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is Off !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else
    {
        NSLog (@"VM is On");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM will be reloaded";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        NSString *appName = [[NSString alloc] init];
        NSString *arguments = [[NSString alloc] init];
        [self runApp:appName = @"iTerm" arguments:arguments = [_resoucesPathFromApp stringByAppendingPathComponent:@"reload.command"]];
    }
}


// Updates menu
- (IBAction)update_k8s:(id)sender {
    int vm_status=[self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is Off !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else
    {
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube-Solo and";
        notification.informativeText = @"OS X kubectl will be updated";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    
        NSString *appName = [[NSString alloc] init];
        NSString *arguments = [[NSString alloc] init];
        [self runApp:appName = @"iTerm" arguments:arguments = [_resoucesPathFromApp stringByAppendingPathComponent:@"update_k8s.command"]];
        //     NSLog(@"Apps arguments: '%@'", [_resoucesPathFromApp stringByAppendingPathComponent:@"update.command"]);
    }
}


- (IBAction)updates:(id)sender {
    int vm_status=[self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is Off !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else
    {
        NSLog (@"VM is On");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"OS X clients will be updated";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        NSString *appName = [[NSString alloc] init];
        NSString *arguments = [[NSString alloc] init];
        [self runApp:appName = @"iTerm" arguments:arguments = [_resoucesPathFromApp stringByAppendingPathComponent:@"update_osx_clients_files.command"]];
    }
}



- (IBAction)fetchLatestISO:(id)sender {
    // send a notification on to the screen
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Kube Solo";
    notification.informativeText = @"CoreOS ISO image will be updated";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    
    NSString *appName = [[NSString alloc] init];
    NSString *arguments = [[NSString alloc] init];
    [self runApp:appName = @"iTerm" arguments:arguments = [_resoucesPathFromApp stringByAppendingPathComponent:@"fetch_latest_iso.command"]];
}
// Updates menu


// Setup menu
- (IBAction)changeReleaseChannel:(id)sender {
    // send a notification on to the screen
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Kube Solo";
    notification.informativeText = @"CoreOS release channel change";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    
    NSString *appName = [[NSString alloc] init];
    NSString *arguments = [[NSString alloc] init];
    [self runApp:appName = @"iTerm" arguments:arguments = [_resoucesPathFromApp stringByAppendingPathComponent:@"change_release_channel.command"]];
}


- (IBAction)destroy:(id)sender {
    // send a notification on to the screen
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"Kube Solo";
    notification.informativeText = @"VM will be destroyed";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    
    NSString *appName = [[NSString alloc] init];
    NSString *arguments = [[NSString alloc] init];
    [self runApp:appName = @"iTerm" arguments:arguments = [_resoucesPathFromApp stringByAppendingPathComponent:@"destroy.command"]];
    
    [self showVMStatus];
}


- (IBAction)initialInstall:(id)sender
{
    NSString *home_folder = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo"];
    
    BOOL isDir;
    if([[NSFileManager defaultManager]
        fileExistsAtPath:home_folder isDirectory:&isDir] && isDir){
        NSString *msg = [NSString stringWithFormat:@"%@ %@ %@", @"Folder", home_folder, @"exists, please delete or rename that folder !!!"];
        [self displayWithMessage:@"Kube-Solo" infoText:msg];
    }
    else
    {
        NSLog(@"Folder does not exist: '%@'", home_folder);
        // create home folder and .env subfolder
        NSString *env_folder = [home_folder stringByAppendingPathComponent:@".env"];
        NSError * error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:env_folder
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        // write to file App version
        NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSData *app_version = [version dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/version"]
                                                contents:app_version
                                              attributes:nil];
        // set resouces_path
        NSString *resources_content = _resoucesPathFromApp;
        NSData *fileContents1 = [resources_content dataUsingEncoding:NSUTF8StringEncoding];
        [[NSFileManager defaultManager] createFileAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/resouces_path"]
                                                contents:fileContents1
                                              attributes:nil];
        
        // run install script
        NSString *scriptName = [[NSString alloc] init];
        NSString *arguments = [[NSString alloc] init];
        [self runScript:scriptName = @"kube-solo-install" arguments:arguments = _resoucesPathFromApp ];
    }
}
// Setup menu

- (IBAction)About:(id)sender {
    
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
//    NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
//    NSString *app_version = [NSString stringWithFormat:@"%@%@.%@", @"v", version, build];
    NSString *app_version = [NSString stringWithFormat:@"%@%@", @"v", version];
    
    NSString *mText = [NSString stringWithFormat:@"%@ %@", @"Kube-Solo for OS X", app_version];
    NSString *infoText = @"It is a simple wrapper around xhyve + CoreOS VM, which allows to control Kube-Solo via Status Bar !!!";
    [self displayWithMessage:mText infoText:infoText];
}
//

// VM console
- (IBAction)attachConsole:(id)sender {
    int vm_status=[self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is Off !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else
    {
        NSLog (@"VM is On");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM's console will be opened";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        NSString *appName = [[NSString alloc] init];
        NSString *arguments = [[NSString alloc] init];
        [self runApp:appName = @"iTerm" arguments:arguments = [_resoucesPathFromApp stringByAppendingPathComponent:@"console.command"]];
    }
}


// OS shell
- (IBAction)runShell:(id)sender{
    int vm_status=[self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is Off !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else
    {
        NSLog (@"VM is On");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"OS X shell will be opened";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        NSString *appName = [[NSString alloc] init];
        NSString *arguments = [[NSString alloc] init];
        [self runApp:appName = @"iTerm" arguments:arguments = [_resoucesPathFromApp stringByAppendingPathComponent:@"os_shell.command"]];
    }
}


// ssh to VM
- (IBAction)runSsh:(id)sender {
    int vm_status=[self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is Off !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else
    {
        NSLog (@"VM is On");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM ssh shell will be opened";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
        
        NSString *appName = [[NSString alloc] init];
        NSString *arguments = [[NSString alloc] init];
        [self runApp:appName = @"iTerm" arguments:arguments = [_resoucesPathFromApp stringByAppendingPathComponent:@"ssh.command"]];
    }
}
// ssh to VM



// UI
- (IBAction)fleetUI:(id)sender {
    int vm_status=[self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is Off !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else
    {
        NSLog (@"VM is On");
        NSString *file_path = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/ip_address"];
        // read IP from file
        NSString *vm_ip = [NSString stringWithContentsOfFile:file_path
                                                    encoding:NSUTF8StringEncoding
                                                       error:NULL];
        NSString *url = [@[@"http://",vm_ip,@":3000"] componentsJoinedByString:@""];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    }
}


- (IBAction)KubernetesUI:(id)sender {
    int vm_status=[self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is Off !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else
    {
        NSLog (@"VM is On");
        NSString *file_path = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/ip_address"];
        // read IP from file
        NSString *vm_ip = [NSString stringWithContentsOfFile:file_path
                                                    encoding:NSUTF8StringEncoding
                                                       error:NULL];
        NSString *url = [@[@"http://",vm_ip,@":8080/ui"] componentsJoinedByString:@""];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    }
}

- (IBAction)node1_cAdvisor:(id)sender {
    int vm_status=[self checkVMStatus];
    //NSLog (@"VM status:\n%d", vm_status);
    
    if (vm_status == 0) {
        NSLog (@"VM is Off");
        // send a notification on to the screen
        NSUserNotification *notification = [[NSUserNotification alloc] init];
        notification.title = @"Kube Solo";
        notification.informativeText = @"VM is Off !!!";
        [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    }
    else
    {
        NSLog (@"VM is On");
        NSString *file_path = [NSHomeDirectory() stringByAppendingPathComponent:@"kube-solo/.env/ip_address"];
        // read IP from file
        NSString *vm_ip = [NSString stringWithContentsOfFile:file_path
                                                    encoding:NSUTF8StringEncoding
                                                       error:NULL];
        NSString *url = [@[@"http://",vm_ip,@":4194"] componentsJoinedByString:@""];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
    }
}

// UI


// helping functions
- (void)runScript:(NSString*)scriptName arguments:(NSString*)arguments
{
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:scriptName ofType:@"command"]];
    task.arguments  = @[arguments];
    [task launch];
    [task waitUntilExit];
    
}


- (void)runApp:(NSString*)appName arguments:(NSString*)arguments
{
    // lunch an external App from the mainBundle
    [[NSWorkspace sharedWorkspace] openFile:arguments withApplication:appName];
}


- (int)checkVMStatus {
    // check VM status and return the shell script output
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:@"check_vm_status" ofType:@"command"]];
    //    task.arguments  = @[@"status"];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    [task waitUntilExit];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    NSLog (@"Show VM status:\n%@", string);
    
    if ( [string  isEqual: @"VM is stopped"] ) {
        return 0;
    } else {
        return 1;
    }
}

- (void)showVMStatus {
    // check vm status and return the shell script output
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:@"check_vm_status" ofType:@"command"]];
    //    task.arguments  = @[@"status"];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    [task waitUntilExit];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    //NSLog (@"Returned:\n%@", string);
    
    // send a notification on to the screen
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.informativeText = string;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}


- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}


-(void) displayWithMessage:(NSString *)mText infoText:(NSString*)infoText
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSInformationalAlertStyle];
    // [alert setIcon:[NSImage imageNamed:@"icon2"]];
    [alert setMessageText:mText];
    [alert setInformativeText:infoText];
    [alert runModal];
}


@end
