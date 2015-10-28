//
//  NSURL+KubeSolo.h
//  Kube-Solo
//
//  Created by Brandon Evans on 2015-10-28.
//  Copyright © 2015 Rimantas Mocevicius. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (KubeSolo)

+ (instancetype)ks_homeURL;
+ (instancetype)ks_envURL;
+ (instancetype)ks_resourcePathURL;
+ (instancetype)ks_appVersionURL;
+ (instancetype)ks_ipAddressURL;

@end
