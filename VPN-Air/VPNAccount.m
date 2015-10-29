//
//  VPNAccount.m
//  VPN-Air
//
//  Created by ZQP on 15/10/25.
//  Copyright © 2015年 ZQP. All rights reserved.
//

#import "VPNAccount.h"

//VPN
/*************************************************/
#define kVPNName @"zqpmaster"
//#define kServerAddress @"66.155.104.74"
#define kServerAddress @"192.161.61.132"
#define kVPNPassword @"99464189"
#define kVPNSharePSK @"vpn.psk"
/*************************************************/

@implementation VPNAccount

+ (instancetype)shareManager
{
    static VPNAccount *vpnAccount = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        vpnAccount = [VPNAccount new];
    });
    
    return vpnAccount;
}

@end
