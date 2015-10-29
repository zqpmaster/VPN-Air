#import "ConfigVPN.h"
#import <NetworkExtension/NetworkExtension.h>
#import <UIKit/UIKit.h>
#import "VPNAccount.h"

NSString *ConfigVPNStatusChangeNotification = @"ConfigVPNStatusChangeNotification";

@implementation ConfigVPN

//DEBUG
#define ALERT(title,msg)
#define ALERTReal(title,msg) dispatch_async(dispatch_get_main_queue(), ^{UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];[alert show];});

//Keychain
//从Keychain取密码对应的key
#define kPasswordReference @"passwordReferencess"
#define kSharedSecretReference @"sharedSecretReferencess"

#define kLocalIdentifier @"vpn"
#define kRemoteIdentifier @"vpn.psk"

+ (instancetype)shareManager
{
    static ConfigVPN *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ConfigVPN alloc] init];
    });
    
    return manager;
    
}

- (instancetype)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(VPNStatusDidChangeNotification) name:NEVPNStatusDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)configVPNKeychain
{
    
    if (![self searchKeychainCopyMatching:kPasswordReference])
    {
        [self deleteKeychainItem:kPasswordReference];
        [self addKeychainItem:kPasswordReference password:[VPNAccount shareManager].vpnUserPassword];
    }
    
    if (![self searchKeychainCopyMatching:kSharedSecretReference])
    {
        [self deleteKeychainItem:kSharedSecretReference];
        [self addKeychainItem:kSharedSecretReference password:[VPNAccount shareManager].sharePsk];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NEVPNStatusDidChangeNotification object:nil];
}

#pragma mark - Keychain
//获取Keychain里的对应密码
- (NSData *)searchKeychainCopyMatching:(NSString *)identifier
{
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    
    searchDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    //    searchDictionary[(__bridge id)kSecAttrGeneric] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrAccount] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrService] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    searchDictionary[(__bridge id)kSecReturnPersistentRef] = @YES;//这很重要
    searchDictionary[(__bridge id)kSecAttrSynchronizable] = @NO;
    
    CFTypeRef result = NULL;
    SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &result);
    return (__bridge NSData *)result;
}

//插入密码到Keychain
- (void)addKeychainItem:(NSString *)identifier password:(NSString*)password
{
    NSData *passData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    
    searchDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    //         searchDictionary[(__bridge id)kSecAttrGeneric] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrAccount] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrService] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecValueData] = passData;
    searchDictionary[(__bridge id)kSecAttrSynchronizable] = @NO;
    ;
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)(searchDictionary), &result);
    if (status != noErr)
    {
        //        //NSLog(@"Keychain插入错误!");
        ALERT(@"Keychain", @"密码保存出错!");
    }
}
- (void)deleteKeychainItem:(NSString *)identifier
{
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    
    searchDictionary[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    //    searchDictionary[(__bridge id)kSecAttrGeneric] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrAccount] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrService] = encodedIdentifier;
    searchDictionary[(__bridge id)kSecAttrSynchronizable] = @NO;
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)searchDictionary);
    if (status != noErr)
    {
        //        //NSLog(@"Keychain插入错误!");
    }
}

#pragma mark - VPNConfig
- (void)setupIPSec
{
    [self configVPNKeychain];

    NEVPNProtocolIPSec *p = [[NEVPNProtocolIPSec alloc] init];
    p.username = [VPNAccount shareManager].vpnUserName;
    p.passwordReference = [self searchKeychainCopyMatching:kPasswordReference];
    //    p.passwordReference = [@"99464189" dataUsingEncoding:NSUTF8StringEncoding];
    p.serverAddress = [VPNAccount shareManager].severAddress;
    p.authenticationMethod = NEVPNIKEAuthenticationMethodSharedSecret;
    p.sharedSecretReference = [self searchKeychainCopyMatching:kSharedSecretReference];
    //    p.sharedSecretReference = [@"vpn.psk" dataUsingEncoding:NSUTF8StringEncoding];
    //    p.identityData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    //    p.identityReference = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    //    p.identityDataPassword = @"test";
    p.disconnectOnSleep = NO;
    
    //需要扩展鉴定(群组)
    p.localIdentifier = kLocalIdentifier;
    p.remoteIdentifier = kRemoteIdentifier;
    p.useExtendedAuthentication = YES;
    
    [[NEVPNManager sharedManager] setProtocol:p];
    [[NEVPNManager sharedManager] setOnDemandEnabled:NO];
    [[NEVPNManager sharedManager] setLocalizedDescription:@"UC Love"];//VPN自定义名字
    [[NEVPNManager sharedManager] setEnabled:YES];
}

- (void)creatVPNProfile
{
    [self creatVPNProfileConnect:NO];
}

- (void)creatVPNProfileConnect:(BOOL)connect
{
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if(error)
        {
            //                    //NSLog(@"Load error: %@", error);
        }
        else
        {
            //配置IPSec
            [self setupIPSec];
            
            //保存VPN到系统->通用->VPN->个人VPN
            [[NEVPNManager sharedManager] saveToPreferencesWithCompletionHandler:^(NSError *error){
                if(error)
                {
                    ALERT(@"saveToPreferences", error.description);
                    self.status = ConfigVpnInvalid;
                    [[NSNotificationCenter defaultCenter] postNotificationName:ConfigVPNStatusChangeNotification object:self];
                }
                else
                {
                    ALERT(@"Saved", @"Saved");
                    if (connect && iGetSystemVersion() > 8)
                    {
                        [self performSelector:@selector(connectVPNfixProfile:) withObject:0 afterDelay:0];
                    }
                }
            }];
        }
    }];
    
}

float iGetSystemVersion()
{
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}


- (void)connectVPN
{
    [self connectVPNfixProfile:YES];
}

- (void)connectVPNfixProfile:(BOOL)fix
{
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if (!error)
        {
            //配置IPSec
            [self setupIPSec];
            NSError *intererror = nil;
            [[NEVPNManager sharedManager].connection startVPNTunnelAndReturnError:&intererror];
            if (intererror && fix)
            {
                [self creatVPNProfileConnect:YES];
            }
        }
    }];
}

- (void)disconnectVPN
{
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if (!error)
        {
            [[NEVPNManager sharedManager].connection stopVPNTunnel];
        }
    }];
}

- (void)removeVPNProfile
{
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if (!error)
        {
            [[NEVPNManager sharedManager] removeFromPreferencesWithCompletionHandler:^(NSError *error){
                if(error)
                {
                    //                            //NSLog(@"Remove error: %@", error);
                    ALERT(@"removeFromPreferences", error.description);
                }
                else
                {
                    ALERT(@"removeFromPreferences", @"删除成功");
                }
            }];
        }
    }];
}

- (void)connected:(void (^)(BOOL))completion
{
    [[NEVPNManager sharedManager] loadFromPreferencesWithCompletionHandler:^(NSError *error){
        if (!error)
        {
            [self setupIPSec];
            completion([self connected]);
        }
        else
        {
            completion(NO);
        }
    }];
}
- (BOOL)connected
{
    return (NEVPNStatusConnected == [[NEVPNManager sharedManager] connection].status);
}

- (void)VPNStatusDidChangeNotification
{
    switch ([NEVPNManager sharedManager].connection.status)
    {
        case NEVPNStatusInvalid:
        {
            NSLog(@"NEVPNStatusInvalid");
            self.status = ConfigVpnInvalid;
            [[NSNotificationCenter defaultCenter] postNotificationName:ConfigVPNStatusChangeNotification object:self];
            break;
        }
        case NEVPNStatusDisconnected:
        {
            NSLog(@"NEVPNStatusDisconnected");
            self.status = ConfigVpnDisconnected;
            [[NSNotificationCenter defaultCenter] postNotificationName:ConfigVPNStatusChangeNotification object:self];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
        }
        case NEVPNStatusConnecting:
        {
            NSLog(@"NEVPNStatusConnecting");
            self.status = ConfigVpnConnecting;
            [[NSNotificationCenter defaultCenter] postNotificationName:ConfigVPNStatusChangeNotification object:self];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;
        }
        case NEVPNStatusConnected:
        {
            NSLog(@"NEVPNStatusConnected");
            self.status = ConfigVpnConneced;
            [[NSNotificationCenter defaultCenter] postNotificationName:ConfigVPNStatusChangeNotification object:self];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
        }
        case NEVPNStatusReasserting:
        {
            NSLog(@"NEVPNStatusReasserting");
            self.status = ConfigVpnReasserting;
            [[NSNotificationCenter defaultCenter] postNotificationName:ConfigVPNStatusChangeNotification object:self];
            break;
        }
        case NEVPNStatusDisconnecting:
        {
            NSLog(@"NEVPNStatusDisconnecting");
            self.status = ConfigVpnDisconnecting;
            [[NSNotificationCenter defaultCenter] postNotificationName:ConfigVPNStatusChangeNotification object:self];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;
        }
            
        default:
            break;
    }
}
@end
