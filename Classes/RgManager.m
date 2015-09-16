//
//  RgManager.m
//  ringmail
//
//  Created by Mike Frager on 9/1/15.
//
//

#import "LinphoneCoreSettingsStore.h"
#import "PhoneMainView.h"
#import "RgManager.h"
#import "RgNetwork.h"

/* RingMail */

NSString *const kRgTextReceived = @"RgTextReceived";

NSString *const kRgSelf = @"self";
NSString *const kRgSelfName = @"Self";

static LevelDB* theConfigDatabase = nil;

@implementation RgManager

+ (NSString*)ringmailHost
{
    return @"staging.ringmail.com";
}

+ (NSString*)ringmailHostSIP
{
    return @"sip.staging.ringmail.com";
}

+ (NSString*)addressToSIP:(NSString*)addr
{
    return [addr stringByReplacingOccurrencesOfString:@"@" withString:@"\\"];
}

+ (NSString*)addressFromSIP:(NSString*)addr
{
    NSString *res = [addr stringByMatching:@"^\\w+:(.*?)\\@" capture:1];
    res = [res stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [res stringByReplacingOccurrencesOfString:@"\\" withString:@"@"];
}

+ (NSString*)addressToXMPP:(NSString*)addr
{
    addr = [addr stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLUserAllowedCharacterSet];
    return [NSString stringWithFormat:@"%@@%@", addr, [RgManager ringmailHost]];
}

+ (NSString*)addressFromXMPP:(NSString*)addr
{
    NSString *res = [addr stringByMatching:@"^(.*?)\\@" capture:1];
    return [res stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString*)pushToken:(NSData*)tokenData
{
    const unsigned char *tokenBuffer = [tokenData bytes];
    NSMutableString *tokenString = [NSMutableString stringWithCapacity:[tokenData length] * 2];
    for (int i = 0; i < [tokenData length]; ++i) {
        [tokenString appendFormat:@"%02X", (unsigned int)tokenBuffer[i]];
    }
#ifdef USE_APN_DEV
#define APPMODE_SUFFIX @"dev"
#else
#define APPMODE_SUFFIX @"prod"
#endif
    NSString *params =
    [NSString stringWithFormat:@"pn-type=apple;app-id=%@.%@;pn-tok=%@",
     [[NSBundle mainBundle] bundleIdentifier], APPMODE_SUFFIX, tokenString];
    
    NSLog(@"APNS Set Proxy Token: %@", params);
    return params;
}

+ (LevelDB*)configDatabase
{
    if (theConfigDatabase == nil)
    {
        theConfigDatabase = [LevelDB databaseInLibraryWithName:@"ringmail_config.ldb"];
    }
    return theConfigDatabase;
}

+ (void)closeConfigDatabase
{
    theConfigDatabase = nil;
}

+ (void)configReset
{
    LevelDB* cfg = [RgManager configDatabase];
    [cfg setObject:@"" forKey:@"ringmail_login"];
    [cfg setObject:@"" forKey:@"ringmail_password"];
    [cfg setObject:@"" forKey:@"ringmail_chat_password"];
    [cfg setObject:@"0" forKey:@"ringmail_email_verify"];
}

+ (BOOL)configReady
{
    LevelDB* cfg = [RgManager configDatabase];
    NSString* login = [cfg objectForKey:@"ringmail_login"];
    NSString* password = [cfg objectForKey:@"ringmail_password"];
    if (
        login != nil && (! [login isEqualToString:@""]) &&
        password != nil && (! [password isEqualToString:@""])
    ) {
        return YES;
    }
    return NO;
}

+ (BOOL)configVerified
{
    LevelDB* cfg = [RgManager configDatabase];
    NSString* verify = [cfg objectForKey:@"ringmail_verify_email"];
    if (verify != nil && [verify isEqualToString:@"1"])
    {
        return YES;
    }
    return NO;
}

+ (BOOL)configReadyAndVerified
{
    return ([RgManager configReady] && [RgManager configVerified]) ? YES : NO;
}

+ (NSDictionary *)getCredentials
{
    NSMutableDictionary* cred = [NSMutableDictionary dictionary];
    LevelDB* cfg = [RgManager configDatabase];
    NSString* rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString* rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        [cred setObject:rgLogin forKey:@"login"];
        [cred setObject:rgPass forKey:@"password"];
        return cred;
    }
    else
    {
        return nil;
    }
}

+ (void)updateCredentials:(NSDictionary*)cred
{
    NSLog(@"RingMail Update Credentials: %@", cred);
    LinphoneCoreSettingsStore* settings = [[LinphoneCoreSettingsStore alloc] init];
    [settings transformLinphoneCoreToKeys];
    NSString *newSipUser = [cred objectForKey:@"sip_login"];
    NSString *oldSipUser = [settings objectForKey:@"username_preference"];
    NSString *newSipPass = [cred objectForKey:@"sip_password"];
    NSString *oldSipPass = [settings objectForKey:@"password_preference"];
    if ((! [oldSipUser isEqualToString:newSipUser]) || (! [oldSipPass isEqualToString:newSipPass]))
    {
        [settings setObject:newSipUser forKey:@"username_preference"];
        [settings setObject:newSipPass forKey:@"password_preference"];
        [settings setObject:@"tcp" forKey:@"transport_preference"];
        [settings setObject:[RgManager ringmailHostSIP] forKey:@"domain_preference"];
        [settings synchronize];
    }
    LevelDB* cfg = [RgManager configDatabase];
    [cfg setObject:@"1" forKey:@"ringmail_verify_email"];
    [RgManager chatEnsureConnection];
}

+ (void)chatConnect
{
    LevelDB* cfg = [RgManager configDatabase];
    LinphoneManager* mgr = [LinphoneManager instance];
    if (mgr.chatManager != nil)
    {
        if (![[mgr.chatManager xmppStream] isDisconnected])
        {
            [mgr.chatManager disconnect];
        }
    }
    else
    {
        mgr.chatManager = [[RgChatManager alloc] init];
    }
    [mgr.chatManager connectWithJID:[cfg objectForKey:@"ringmail_login"] password:[cfg objectForKey:@"ringmail_chat_password"]];
}

+ (void)chatEnsureConnection
{
    LevelDB* cfg = [RgManager configDatabase];
    LinphoneManager* mgr = [LinphoneManager instance];
    if (mgr.chatManager == nil)
    {
        mgr.chatManager = [[RgChatManager alloc] init];
    }
    if ([[mgr.chatManager xmppStream] isDisconnected])
    {
        [mgr.chatManager connectWithJID:[cfg objectForKey:@"ringmail_login"] password:[cfg objectForKey:@"ringmail_chat_password"]];
    }
}

+ (void)initialLogin
{
    NSLog(@"RingMail: Initial - Login");
    LinphoneManager* mgr = [LinphoneManager instance];
    LevelDB* cfg = [RgManager configDatabase];
    NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        [mgr setRingLogin:rgLogin];
        NSString *rgChatPass = [cfg objectForKey:@"ringmail_chat_password"];
        if (rgChatPass != nil && (! [rgChatPass isEqualToString:@""])) // Check if chat password exists
        {
            [RgManager chatConnect];
        }
        [[RgNetwork instance] login:rgLogin password:rgPass callback:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary* res = responseObject;
            NSString *ok = [res objectForKey:@"result"];
            if ([ok isEqualToString:@"ok"])
            {
                [RgManager updateCredentials:res];
            }
            else
            {
                [mgr setRingLogin:@""];
                WizardViewController *controller = DYNAMIC_CAST(
                    [[PhoneMainView instance] changeCurrentView:[WizardViewController compositeViewDescription]],
                    WizardViewController);
                if (controller != nil) {
                    [controller reset];
                }
            }
        }];
    }
}

+ (void)verifyLogin:(RgNetworkCallback)callback
{
    NSLog(@"RingMail: Verify - Login");
    LinphoneManager* mgr = [LinphoneManager instance];
    LevelDB* cfg = [RgManager configDatabase];
    NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        [mgr setRingLogin:rgLogin];
        [[RgNetwork instance] login:rgLogin password:rgPass callback:callback];
    }
}

@end
