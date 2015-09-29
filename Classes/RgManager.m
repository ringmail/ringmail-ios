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

+ (NSString*)addressFromSIPUser:(NSString*)addr
{
    return [addr stringByReplacingOccurrencesOfString:@"\\" withString:@"@"];
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

+ (void)startCall:(NSString*)address
{
    NSString* displayName = [address copy];
    ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
    if (contact) {
        displayName = [FastAddressBook getContactDisplayName:contact];
    }
    if ([address rangeOfString:@"@"].location != NSNotFound)
    {
        displayName = [NSString stringWithString:address];
        address = [RgManager addressToSIP:address];
        NSLog(@"New Address: %@", address);
    }
    [[LinphoneManager instance] call:address displayName:displayName transfer:FALSE];
}

+ (void)startMessage:(NSString*)address
{
    [[LinphoneManager instance] setChatTag:address];
    [[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE];
}

+ (void)startMessageMD5
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        LinphoneManager *lm = [LinphoneManager instance];
        NSString* md5 = [lm chatMd5];
        if (md5 != nil && ! [md5 isEqualToString:@""])
        {
            NSString *chat = [[lm chatManager] dbGetSessionByMD5:md5];
            if (![chat isEqualToString:@""])
            {
                [lm setChatMd5:@""];
                UICompositeViewDescription* curView = [[PhoneMainView instance] topView];
                if ((curView == nil) || (!
                    ( // If not in the same chat room already
                        [curView equal:[ChatRoomViewController compositeViewDescription]] &&
                        [lm chatTag] != nil &&
                        [chat isEqualToString:[lm chatTag]]
                     )
                )) {
                    [RgManager startMessage:chat];
                }
            }
        }
    }];
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

+(BOOL)checkEmailAddress:(NSString *)checkString
{
    // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

+ (BOOL)checkRingMailAddress:(NSString*)address
{
    //NSLog(@"RingMail: URI - Check Address: %@", address);
    if ([address length] > 200)
    {
        return false; // Too long, you're probably trying something fishy
    }
    NSString *lcAddress = [address lowercaseString];
    NSMutableString *numAddress = [address mutableCopy];
    [numAddress replaceOccurrencesOfRegex:@"[^0-9]" withString:@""];
    if ([address isMatchedByRegex:@"\\@"])
    {
        //NSLog(@"RingMail: URI - Email Address: %@", address);
        // check email
        return [RgManager checkEmailAddress:address];
    }
    else if ([address isMatchedByRegex:@"\\."])
    {
        //NSLog(@"RingMail: URI - Domain Address: %@", address);
        // check domain
        if ([address isMatchedByRegex:@"([A-Za-z0-9-]+\\.)+[A-Za-z]{1,}$"])
        {
            return true;
        }
    }
    else if ([lcAddress isMatchedByRegex:@"^#[a-z0-9_]+$"]) // check hashtag
    {
        return true;
    }
    /*else if ([numAddress length]) // has a digit
    {
        // TODO: calling DIDs, etc...
        return false;
    }*/
    NSLog(@"RingMail: URI - Bad Address: %@", address);
    return false;
}

+ (NSString *)filterRingMailAddress:(NSString*)address
{
    // only call after address has been checked
    NSString *lcAddress = [address lowercaseString];
    NSMutableString *numAddress = [address mutableCopy];
    [numAddress replaceOccurrencesOfRegex:@"[^0-9]" withString:@""];
    if ([address isMatchedByRegex:@"\\@"])
    {
        return address;
    }
    else if ([address isMatchedByRegex:@"\\."])
    {
        return address;
    }
    else if ([lcAddress isMatchedByRegex:@"^#"])
    {
        return address;
    }
    else if ([numAddress length])
    {
        return numAddress;
    }
    return @""; // Bad address
}

+ (void)processRingURI:(NSString*)uri
{
    NSMutableString *ringuri = [uri mutableCopy];
    [ringuri replaceOccurrencesOfRegex:@"^ring:(//)?" withString:@""];
    NSLog(@"RingMail: URI - %@ (from: %@)", ringuri, uri);
    if ([ringuri isMatchedByRegex:@"^message/"])
    {
        [ringuri replaceOccurrencesOfRegex:@"^message/" withString:@""];
        if ([RgManager checkRingMailAddress:ringuri])
        {
            [RgManager startMessage:[RgManager filterRingMailAddress:ringuri]];
        }
        return;
    }
    else if ([ringuri isMatchedByRegex:@"^call/"])
    {
        [ringuri replaceOccurrencesOfRegex:@"^call/" withString:@""];
    }
    if ([RgManager checkRingMailAddress:ringuri])
    {
        NSLog(@"RingMail: URI - Valid For Call: %@", ringuri);
        [RgManager startCall:[RgManager filterRingMailAddress:ringuri]];
    }
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
    NSLog(@"RingMail - Current Settings: %@", [settings getSettings]);
    
    // RingMail Defaults
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"start_at_boot_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"backgroundmode_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"enable_video_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"opus_preference"];
    [settings setObject:[NSNumber numberWithBool:0] forKey:@"pcmu_preference"];
    [settings setObject:[NSNumber numberWithBool:0] forKey:@"g722_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"vp8_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"ice_preference"];
    [settings setObject:@"stun1.l.google.com:19302" forKey:@"stun_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"adaptive_rate_control_preference"];
    [settings setObject:@"Simple" forKey:@"adaptive_rate_algorithm_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"autoanswer_notif_preference"];
    [settings setObject:[NSNumber numberWithInt:128] forKey:@"audio_codec_bitrate_limit_preference"];
    [settings setObject:[NSNumber numberWithBool:0] forKey:@"voiceproc_preference"];
    [settings setObject:@"8576" forKey:@"audio_port_preference"];
    [settings setObject:@"8577" forKey:@"video_port_preference"];
    
    for (NSString *i in @[@"aaceld_16k", @"aaceld_22k", @"aaceld_32k", @"aaceld_44k", @"aaceld_48k", @"avpf", @"gsm", @"ilbc", @"pcma", @"silk_16k", @"silk_24k", @"speex_16k", @"speex_8k", @"h264", @"mp4v-es"])
    {
        [settings setObject:[NSNumber numberWithBool:0] forKey:[NSString stringWithFormat:@"%@_preference", i]];
    }
    
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
    }
    NSLog(@"RingMail - New Settings: %@", [settings getSettings]);
    [settings synchronize];
    
    LevelDB* cfg = [RgManager configDatabase];
    [cfg setObject:@"1" forKey:@"ringmail_verify_email"];
    [cfg setObject:[cred objectForKey:@"chat_password"] forKey:@"ringmail_chat_password"];
    [RgManager chatEnsureConnection];
    [[RgNetwork instance] registerPushToken];
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
    NSString* chatPass = [cfg objectForKey:@"ringmail_chat_password"];
    if (chatPass != nil && ! [chatPass isEqualToString:@""])
    {
        [mgr.chatManager connectWithJID:[cfg objectForKey:@"ringmail_login"] password:chatPass];
    }
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
        NSString* chatPass = [cfg objectForKey:@"ringmail_chat_password"];
        if (chatPass != nil && ! [chatPass isEqualToString:@""])
        {
            [mgr.chatManager connectWithJID:[cfg objectForKey:@"ringmail_login"] password:chatPass];
        }
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
        NSLog(@"Initial Chat Pass: %@", rgChatPass);
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
