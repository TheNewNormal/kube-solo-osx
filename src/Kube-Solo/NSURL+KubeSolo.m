//
//  NSURL+KubeSolo.m
//  Kube-Solo
//
//  Created by Brandon Evans on 2015-10-28.
//  Copyright © 2015 Rimantas Mocevicius. All rights reserved.
//

#import "NSURL+KubeSolo.h"

@implementation NSURL (KubeSolo)

+ (instancetype)ks_homeURL {
    return [[NSURL fileURLWithPath:NSHomeDirectory()] URLByAppendingPathComponent:@"kube-solo/"];
}

+ (instancetype)ks_envURL {
    return [[self ks_homeURL] URLByAppendingPathComponent:@".env/"];
}

+ (instancetype)ks_resourcePathURL {
    return [[self ks_envURL] URLByAppendingPathComponent:@"resouces_path"];
}

+ (instancetype)ks_appVersionURL {
    return [[self ks_envURL] URLByAppendingPathComponent:@"version"];
}

+ (instancetype)ks_ipAddressURL {
    return [[self ks_envURL] URLByAppendingPathComponent:@"ip_address"];
}

@end
