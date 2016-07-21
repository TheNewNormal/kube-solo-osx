//
//  VMManager.h
//  Kube-Solo
//
//  Created by Brandon Evans on 2015-10-28.
//  Copyright © 2015 Rimantas Mocevicius. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VMStatus) {
    VMStatusDown = 0,
    VMStatusUp = 1
};

@interface VMManager : NSObject

- (VMStatus)checkVMStatus;
- (void)start;
- (void)halt;
- (void)kill;
- (void)reload;
- (void)updateKubernetes;
- (void)updateKubernetesVersion;
- (void)updateClients;
- (void)changeReleaseChannel;
- (void)changeVMRAM;
- (void)changeNFSsettings;
- (void)destroy;
- (void)install;
- (void)runShell;
- (void)runSSH;
- (NSString*)getAppVersionGithub;

@end
