//
//  VMManager.m
//  Kube-Solo
//
//  Created by Brandon Evans on 2015-10-28.
//  Copyright © 2015 Rimantas Mocevicius. All rights reserved.
//

#import "VMManager.h"

@implementation VMManager

- (VMStatus)checkVMStatus {
    // check VM status and return the shell script output
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:@"check_vm_status" ofType:@"command"]];
    //    task.arguments  = @[@"status"];

    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];

    NSFileHandle *file;
    file = [pipe fileHandleForReading];

    [task launch];
    [task waitUntilExit];

    NSData *data;
    data = [file readDataToEndOfFile];

    NSString *string;
    string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"Show VM status:\n%@", string);

    if ([string isEqual:@"VM is stopped"]) {
        NSLog(@"VM is Off");
        return VMStatusDown;
    } else {
        NSLog(@"VM is On");
        return VMStatusUp;
    }
}


- (NSString*)getAppVersionGithub {
    // get App github version and return the shell script output
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:@"check_app_version_github" ofType:@"command"]];
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
    NSLog (@"App latest github version:\n%@", string);
    
    return string;
}


- (void)start {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"up.command"]];
}

- (void)halt {
    [self runScript:@"halt" arguments:@""];
}

- (void)kill {
    [self runScript:@"kill_VM" arguments:@""];
}

- (void)reload {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"reload.command"]];
}

- (void)updateKubernetes {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"update_k8s.command"]];
}

- (void)updateKubernetesVersion {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"update_k8s_version.command"]];
}

- (void)updateClients {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"update_osx_clients_files.command"]];
}


- (void)runScript:(NSString *)scriptName arguments:(NSString *)arguments {
    NSTask *task = [[NSTask alloc] init];

    task.launchPath = [NSString stringWithFormat:@"%@", [[NSBundle mainBundle] pathForResource:scriptName ofType:@"command"]];
    task.arguments = @[ arguments ];
    [task launch];
    [task waitUntilExit];
}

- (void)runApp:(NSString *)appName arguments:(NSString *)arguments {
    // lunch an external App from the mainBundle
    [[NSWorkspace sharedWorkspace] openFile:arguments withApplication:appName];
}


- (void)changeReleaseChannel {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"change_release_channel.command"]];
}

- (void)changeVMRAM {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"change_vm_ram.command"]];
}

- (void)changeNFSsettings {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"enable_disable_nfs.command"]];
}

- (void)destroy {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"destroy.command"]];
}

- (void)install {
    [self runScript:@"kube-solo-install" arguments:[[NSBundle mainBundle] resourcePath]];
}

- (void)runShell {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"os_shell.command"]];
}

- (void)runSSH {
    [self runApp:@"iTerm" arguments:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ssh.command"]];
}

@end
