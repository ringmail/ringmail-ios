//
//  RgManager.m
//  ringmail
//
//  Created by Mike Frager on 9/1/15.
//
//

#import "LinphoneCoreSettingsStore.h"
#import "PhoneMainView.h"
#import "NSStringAdditions.h"
#import "RgManager.h"
#import "RgNetwork.h"
#import "RgChatManager.h"

/* RingMail */

NSString *const kRgTextReceived = @"RgTextReceived";
NSString *const kRgTextSent = @"RgTextSent";
NSString *const kRgTextUpdate = @"RgTextUpdate";
NSString *const kRgContactsUpdated = @"RgContactsUpdated";
NSString *const kRgSetAddress = @"RgSetAddress";
NSString *const kRgMainRefresh = @"RgMainRefresh";
NSString *const kRgMainRemove = @"RgMainRemove";
NSString *const kRgFavoriteRefresh = @"RgFavoriteRefresh";
NSString *const kRgAttemptVerify = @"kRgAttemptVerify";
NSString *const kRgLaunchBrowser = @"kRgLaunchBrowser";
NSString *const kRgToggleNumberPad = @"kRgToggleNumberPad";
NSString *const kRgCallRefresh = @"kRgCallRefresh";
NSString *const kRgContactRefresh = @"kRgContactRefresh";

NSString *const kRgSelf = @"self";
NSString *const kRgSelfName = @"Self";

static LevelDB* theConfigDatabase = nil;

@implementation RgManager

+ (NSString*)ringmailHost
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleIdentifier isEqualToString:@"com.ringmail.phone"])
    {
        return @"ringmail.com";
    }
    else
    {
        return @"www-mb.ringxml.com";
    }
}

+ (NSString*)ringmailHostSIP
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleIdentifier isEqualToString:@"com.ringmail.phone"])
    {
        return @"sip.ringmail.com";
    }
    else
    {
        return @"sip-mb.ringxml.com";
    }
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

+ (BOOL)hasContactId:(NSNumber*)contact
{
    LinphoneManager *mgr = [LinphoneManager instance];
    ABRecordRef item = [[mgr fastAddressBook] getContactById:contact];
    if (item == NULL)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}

+ (NSString*)formatPhoneNumber:(NSString*)addr
{
    addr = [addr stringByReplacingOccurrencesOfRegex:@"\\D" withString:@""];
    if ([addr length] == 0)
    {
        return @"";
    }
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSError *anError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:addr defaultRegion:@"US" error:&anError];
    NSString *res = addr;
    if (anError == nil)
    {
        if ([phoneUtil isValidNumber:myNumber])
        {
            res = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&anError];
        }
        else
        {
            LOGI(@"RingMail: Invalid Phone Number: '%@'", addr);
        }
    }
    else
    {
        LOGI(@"RingMail: NBPhoneNumberUtil Error '%@'", [anError localizedDescription]);
    }
    return res;
}

+ (void)startCall:(NSString*)address contact:(ABRecordRef)contact video:(BOOL)video
{
    NSString* displayName = [address copy];
    NSNumber* contactNum = nil;
    if (contact == NULL)
    {
        contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
    }
    if (contact != NULL)
    {
        contactNum = [[[LinphoneManager instance] fastAddressBook] getContactId:contact];
        displayName = [FastAddressBook getContactDisplayName:contact];
    }
    else
    {
        displayName = [NSString stringWithString:address];
    }
    if ([address rangeOfString:@"@"].location != NSNotFound)
    {
        address = [RgManager addressToSIP:address];
    }
    [[LinphoneManager instance] call:address contact:(NSNumber*)contactNum displayName:displayName transfer:FALSE video:video];
}

+ (void)startMessage:(NSString*)address contact:(ABRecordRef)contact
{
    LinphoneManager *lm = [LinphoneManager instance];
    NSNumber *contactNum = nil;
    if (contact == NULL)
    {
        contact = [[lm fastAddressBook] getContact:address];
    }
    if (contact != NULL)
    {
        contactNum = [[lm fastAddressBook] getContactId:contact];
    }
    NSDictionary *sessionData = [[lm chatManager] dbGetSessionID:address to:nil contact:contactNum uuid:nil];
    [lm setChatSession:sessionData[@"id"]];
    [[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE];
}

+ (void)startMessageMD5
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        LinphoneManager *lm = [LinphoneManager instance];
        NSString* md5 = [lm chatMd5];
        if (md5 != nil && ! [md5 isEqualToString:@""])
        {
            NSNumber *chat = [[lm chatManager] dbGetSessionByMD5:md5];
            if ([chat intValue] != 0)
            {
                [lm setChatMd5:@""];
                UICompositeViewDescription* curView = [[PhoneMainView instance] topView];
                if ((curView == nil) || (!
                                         ( // If not in the same chat room already
                                          [curView equal:[ChatRoomViewController compositeViewDescription]] &&
                                          [lm chatSession] != nil &&
                                          [chat isEqualToNumber:[lm chatSession]]
                                          )
                                         )) {
                    [lm setChatSession:chat];
                    [[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE];
                }
            }
        }
    }];
}

+ (void)startHashtag:(NSString*)address
{
    [[RgNetwork instance] lookupHashtag:@{
                                          @"hashtag": address,
                                          } callback:^(NSURLSessionTask *operation, id responseObject) {
                                              NSDictionary* res = responseObject;
                                              NSString *ok = [res objectForKey:@"result"];
                                              if ([ok isEqualToString:@"ok"])
                                              {
                                                  RgChatManager *cmgr = [[LinphoneManager instance] chatManager];
                                                  NSDictionary *sessionData = [cmgr dbGetSessionID:address to:nil contact:nil uuid:nil];
                                                  [cmgr dbInsertCall:@{
                                                                       @"sip": @"",
                                                                       @"address": address,
                                                                       @"state": [NSNumber numberWithInt:0],
                                                                       @"inbound": [NSNumber numberWithBool:NO],
                                                                       } session:sessionData[@"id"]];
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:kRgLaunchBrowser object:self userInfo:@{
                                                                                                                                                     @"address": [res objectForKey:@"target"],
                                                                                                                                                     }];
                                                  [[NSNotificationCenter defaultCenter] postNotificationName:kRgMainRefresh object:self userInfo:nil];
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
    
    //LOGI(@"RingMail: APNS Set Proxy Token: %@", params);
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
    //LOGI(@"RingMail: URI - Check Address: %@", address);
    if ([address length] > 200)
    {
        return false; // Too long, you're probably trying something fishy
    }
    NSString *lcAddress = [address lowercaseString];
    NSMutableString *numAddress = [address mutableCopy];
    [numAddress replaceOccurrencesOfRegex:@"[^0-9]" withString:@""];
    if ([address isMatchedByRegex:@"\\@"])
    {
        //LOGI(@"RingMail: URI - Email Address: %@", address);
        // check email
        return [RgManager checkEmailAddress:address];
    }
    else if ([address isMatchedByRegex:@"\\."])
    {
        //LOGI(@"RingMail: URI - Domain Address: %@", address);
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
    else if ([numAddress length] >= 10 && [numAddress length] <= 20) // has a digit
    {
        return true;
    }
    LOGI(@"RingMail: URI - Bad Address: %@", address);
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
    __block NSMutableString *ringuri = [uri mutableCopy];
    [ringuri replaceOccurrencesOfRegex:@"^ring:(//)?" withString:@"" options:RKLCaseless range:(NSRange){0, [ringuri length]} error:NULL];
    LOGI(@"RingMail: URI - %@ (from: %@)", ringuri, uri);
    
    if ([RgManager configReadyAndVerified])
    {
        __block BOOL video = NO;
        if ([ringuri isMatchedByRegex:@"^(message|chat|text)/"])
        {
            [ringuri replaceOccurrencesOfRegex:@"^(message|chat|text)/" withString:@""];
            if ([RgManager checkRingMailAddress:ringuri])
            {
                ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:ringuri];
                [RgManager startMessage:[RgManager filterRingMailAddress:ringuri] contact:contact];
            }
            return;
        }
        else if ([ringuri isMatchedByRegex:@"^call/"])
        {
            [ringuri replaceOccurrencesOfRegex:@"^call/" withString:@""];
        }
        else if ([ringuri isMatchedByRegex:@"^video/"])
        {
            [ringuri replaceOccurrencesOfRegex:@"^video/" withString:@""];
            video = YES;
        }
        else if ([ringuri length] > 0 && [[ringuri substringToIndex:1] isEqualToString:@"#"])
        {
            if ([RgManager checkRingMailAddress:ringuri])
            {
                [RgManager startHashtag:ringuri];
            }
            return;
        }
        if ([RgManager checkRingMailAddress:ringuri])
        {
            LOGI(@"RingMail: URI - Valid: %@", ringuri);
            BOOL coreReady = [[[LinphoneManager instance] coreReady] boolValue];
            BOOL startCall = NO;
            LOGI(@"RingMail: Core Ready - %d", coreReady);
            
            if (coreReady)
            {
                LinphoneProxyConfig *cfg = linphone_core_get_default_proxy_config([LinphoneManager getLc]);
                BOOL isReg = linphone_proxy_config_is_registered(cfg);
                LOGI(@"RingMail: Is Registered - %d", isReg);
                if (isReg)
                {
                    startCall = YES;
                }
            }
            if (startCall)
            {
                LOGI(@"RingMail: Start Call Now");
                [RgManager startCall:[RgManager filterRingMailAddress:ringuri] contact:NULL video:video];
            }
            else
            {
                LOGI(@"RingMail: Queue Call");
                LinphoneManager *mgr = [LinphoneManager instance];
                [[mgr opQueue] setSuspended:YES];
                [[mgr opQueue] cancelAllOperations]; // reset queue
                [[mgr opQueue] addOperationWithBlock:^{
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                        ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:ringuri];
                        [RgManager startCall:[RgManager filterRingMailAddress:ringuri] contact:contact video:video];
                    }];
                }];
            }
        }
    }
    else if ([ringuri isMatchedByRegex:@"^verify$"])
    {
        LevelDB *cfg = [RgManager configDatabase];
        cfg[@"ringmail_check_email"] = @1;
        [[NSNotificationCenter defaultCenter] postNotificationName:kRgAttemptVerify object:self userInfo:nil];
    }
    else
    {
        // TODO: defer URI until after login
    }
}

+ (NSString *)configDatabaseName
{
    NSString *name;
#ifdef DEBUG
    name = @"ringmail_config_dev";
#else
    name = @"ringmail_config";
#endif
    name = [name stringByAppendingString:@"_v1.1.1.ldb"];
    return name;
}

+ (LevelDB*)configDatabase
{
    if (theConfigDatabase == nil)
    {
        LOGI(@"RingMail: Create Config Database");
        theConfigDatabase = [LevelDB databaseInLibraryWithName:[RgManager configDatabaseName]];
    }
    if (! [theConfigDatabase objectForKey:@"ringmail_device_uuid"])
    {
        [theConfigDatabase setObject:[NSString stringByGeneratingUUID] forKey:@"ringmail_device_uuid"];
    }
    return theConfigDatabase;
}

+ (void)closeConfigDatabase
{
    [theConfigDatabase close];
    theConfigDatabase = nil;
}

+ (void)configReset
{
    // Remove config database
    LevelDB *cfg = [RgManager configDatabase];
    NSString *deviceUUID = [cfg objectForKey:@"ringmail_device_uuid"];
    [RgManager closeConfigDatabase];
    NSString *cfgPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[RgManager configDatabaseName]];
    if ([[NSFileManager defaultManager] removeItemAtPath:cfgPath error:NULL])
    {
        LOGI(@"RingMail: Config File Removed: %@", cfgPath);
    }
    [RgManager configDatabase]; // Create a new blank one
    cfg = [RgManager configDatabase]; // Get the new one
    // Restore original device UUID
    [cfg setObject:deviceUUID forKey:@"ringmail_device_uuid"];
    
    // Remove sqlite database
    NSString *dbPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[RgChatManager databasePath]];
    if ([[NSFileManager defaultManager] removeItemAtPath:dbPath error:NULL])
    {
        LOGI(@"RingMail: SQLite Database Removed: %@", dbPath);
    }
    LinphoneManager* mgr = [LinphoneManager instance];
    [[mgr chatManager] setupDatabase]; // Set it back up again for next time
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kRgMainRefresh object:self userInfo:nil];
    
    /*
     // Clear out the whole database
     LevelDB* cfg = [RgManager configDatabase];
     [cfg enumerateKeysAndObjectsUsingBlock:^(LevelDBKey *key, id value, BOOL *stop) {
     // This step is necessary since the key could be a string or raw data (use NSDataFromLevelDBKey in that case)
     NSString *keyString = NSStringFromLevelDBKey(key); // Assumes UTF-8 encoding
     // Do something clever
     [cfg removeObjectForKey:keyString];
     }];
     */
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

+ (BOOL)configEmailVerified
{
    LevelDB* cfg = [RgManager configDatabase];
    NSString* verify = [cfg objectForKey:@"ringmail_verify_email"];
    if (verify != nil && [verify isEqualToString:@"1"])
    {
        return YES;
    }
    return NO;
}

+ (BOOL)configPhoneVerified
{
    LevelDB* cfg = [RgManager configDatabase];
    NSString* verify = [cfg objectForKey:@"ringmail_verify_phone"];
    if (verify != nil && [verify isEqualToString:@"1"])
    {
        return YES;
    }
    return NO;
}

+ (BOOL)configReadyAndVerified
{
    return ([RgManager configReady] && [RgManager configEmailVerified] && [RgManager configPhoneVerified]) ? YES : NO;
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
    LOGI(@"RingMail: Login Complete: %@", cred);
    //[[LinphoneManager instance] startLinphoneCore];
    
    LinphoneCoreSettingsStore* settings = [[LinphoneCoreSettingsStore alloc] init];
    [settings transformLinphoneCoreToKeys];
    LOGI(@"RingMail: Current Settings: %@", [settings getSettings]);
    
    // RingMail Defaults
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"debugenable_preference"]; // ON for now
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"start_at_boot_preference"];
    [settings setObject:[NSNumber numberWithBool:0] forKey:@"backgroundmode_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"enable_video_preference"];
    [settings setObject:@"tls" forKey:@"transport_preference"];
    [settings setObject:@"5061" forKey:@"port_preference"];
    [settings setObject:@"None" forKey:@"media_encryption_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"opus_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"amr_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"pcmu_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"g722_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"g729_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"vp8_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"h264_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"ice_preference"];
    [settings setObject:@"stun1.l.google.com:19302" forKey:@"stun_preference"];
    //[settings setObject:@"74.125.142.127:19302" forKey:@"stun_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"adaptive_rate_control_preference"];
    [settings setObject:@"Simple" forKey:@"adaptive_rate_algorithm_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"autoanswer_notif_preference"];
    [settings setObject:[NSNumber numberWithInt:32] forKey:@"audio_codec_bitrate_limit_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"voiceproc_preference"];
    [settings setObject:@"8576" forKey:@"audio_port_preference"];
    [settings setObject:@"9078" forKey:@"video_port_preference"];
    [settings setObject:[NSNumber numberWithBool:1] forKey:@"accept_video_preference"];
    [settings setObject:@"custom" forKey:@"video_preset_preference"];
    [settings setObject:[NSNumber numberWithInt:2] forKey:@"video_preferred_size_preference"];
    [settings setObject:[NSNumber numberWithInt:10] forKey:@"video_preferred_fps_preference"];
    [settings setObject:[NSNumber numberWithInt:256] forKey:@"download_bandwidth_preference"];
    
    for (NSString *i in @[@"aaceld_16k", @"aaceld_22k", @"aaceld_32k", @"aaceld_44k", @"aaceld_48k", @"avpf", @"gsm", @"ilbc", @"pcma", @"silk_16k", @"silk_24k", @"speex_16k", @"speex_8k", @"mp4v-es"])
    {
        [settings setObject:[NSNumber numberWithBool:0] forKey:[NSString stringWithFormat:@"%@_preference", i]];
    }
    
    NSString *newSipUser = [cred objectForKey:@"sip_login"];
    //NSString *oldSipUser = [settings objectForKey:@"username_preference"];
    NSString *newSipPass = [cred objectForKey:@"sip_password"];
    
    NSLog(@"RingMail SIP Login: %@ Password: %@", newSipUser, newSipPass);
    //NSString *oldSipPass = [settings objectForKey:@"password_preference"];
    //if ((! [oldSipUser isEqualToString:newSipUser]) || (! [oldSipPass isEqualToString:newSipPass]))
    //{
    [settings setObject:newSipUser forKey:@"username_preference"];
    [settings setObject:newSipPass forKey:@"password_preference"];
    [settings setObject:[RgManager ringmailHostSIP] forKey:@"domain_preference"];
    //}
    //LOGI(@"RingMail: New Settings: %@", [settings getSettings]);
    [settings synchronize];
    
    LevelDB* cfg = [RgManager configDatabase];
    [[LinphoneManager instance] setRingLogin:cfg[@"ringmail_login"]];
    LOGI(@"RingMail: ringLogin: %@", [[LinphoneManager instance] ringLogin]);
    [cfg setObject:[cred objectForKey:@"chat_password"] forKey:@"ringmail_chat_password"];
    [RgManager chatEnsureConnection];
    [[RgNetwork instance] registerPushToken];
}

+ (void)setupPushToken
{
    RgNetwork* net = [RgNetwork instance];
    if (! [[net pushReady] boolValue])
    {
        [[RgNetwork instance] registerPushToken];
    }
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
        [RgManager setupDefaultHashtags:cfg];
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
        [RgManager setupDefaultHashtags:cfg];
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

+ (void)setupDefaultHashtags:(LevelDB*)cfg
{
    // Setup default hashtags
    if (cfg[@"ringmail_hashtags"] != nil)
    {
        LinphoneManager* mgr = [LinphoneManager instance];
        NSArray *ht = (NSArray*)cfg[@"ringmail_hashtags"];
        for (NSString *tag in [[ht reverseObjectEnumerator] allObjects])
        {
            NSDictionary *rec = [mgr.chatManager dbGetSessionID:tag to:nil contact:nil uuid:nil];
            [mgr.chatManager dbInsertCall:@{
                                            @"sip": @"",
                                            @"address": tag,
                                            @"state": [NSNumber numberWithInt:0],
                                            @"inbound": [NSNumber numberWithBool:NO],
                                            } session:rec[@"id"]];
            //NSLog(@"Default Hashtag: %@ - %@", tag, rec);
        }
        [cfg removeObjectForKey:@"ringmail_hashtags"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kRgMainRefresh object:self userInfo:nil];
    }
}

+ (void)updateContacts:(NSDictionary*)res
{
    LinphoneManager *mgr = [LinphoneManager instance];
    RgContactManager *contactMgr = [mgr contactManager];
    
    // 1st round of ringmail-enabled contact updates from server (2nd is the reply to sendContactData)
    [contactMgr dbUpdateEnabled:[res objectForKey:@"rg_contacts"]];
    
    NSString *serverTimestamp = [res objectForKey:@"ts_latest"];
    BOOL send = 1; // send first time
    
    // Check to see if contacts database is newer than server
    if (! [serverTimestamp isEqualToString:@""]) // always send if server has no data yet
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
        NSDate *serverDate = [dateFormatter dateFromString:serverTimestamp];
        NSDate *serverCount = [res objectForKey:@"contacts"];
        NSArray *contactList = [contactMgr getContactList];
        NSDictionary *summary = [contactMgr getAddressBookStats:contactList];
        NSDate *internalDate = [summary objectForKey:@"date_update"];
        NSNumber *internalCount = [summary objectForKey:@"count"];
        LOGI(@"RingMail: Server(%@:%@) Internal(%@:%@)", serverDate, serverCount, internalDate, internalCount);
        if ((! ([internalDate compare:serverDate] == NSOrderedDescending)) && [serverCount isEqual:internalCount])
        {
            send = 0;
            LOGI(@"RingMail: Server Contacts Up To Date");
        }
    }
    if (send)
    {
        [contactMgr sendContactData];
    }
}

+ (void)initialLogin
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleIdentifier isEqualToString:@"com.ringmail.phone"])
    {
        LOGI(@"RingMail: Login");
    }
    else
    {
        LOGI(@"RingMail: Login (DEV)");
    }
    LinphoneManager* mgr = [LinphoneManager instance];
    LevelDB* cfg = [RgManager configDatabase];
    NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        [mgr setRingLogin:rgLogin];
        NSString *rgChatPass = [cfg objectForKey:@"ringmail_chat_password"];
        //LOGI(@"RingMail: Initial Chat Pass: %@", rgChatPass);
        if (rgChatPass != nil && (! [rgChatPass isEqualToString:@""])) // Check if chat password exists
        {
            [RgManager chatConnect];
        }
        [[RgNetwork instance] login:rgLogin password:rgPass callback:^(NSURLSessionTask *operation, id responseObject) {
            NSDictionary* res = responseObject;
            NSString *ok = [res objectForKey:@"result"];
            if ([ok isEqualToString:@"ok"])
            {
                [RgManager updateCredentials:res];
                [RgManager updateContacts:res];
            }
            else
            {
                [mgr setRingLogin:@""];
                [RgManager reset];
                WizardViewController *controller = DYNAMIC_CAST(
                                                                [[PhoneMainView instance] changeCurrentView:[WizardViewController compositeViewDescription]],
                                                                WizardViewController);
                if (controller != nil) {
                    [controller reset];
                    [controller startWizard];
                }
            }
        }
        failure:^(NSURLSessionTask *operation, NSError *error) {
            LOGI(@"Initial login failure - network error");
        }];
    }
}

+ (void)verifyLogin:(RgNetworkCallback)callback failure:(RgNetworkError)failure
{
    LOGI(@"RingMail: Verify - Login");
    LinphoneManager* mgr = [LinphoneManager instance];
    LevelDB* cfg = [RgManager configDatabase];
    NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        [mgr setRingLogin:rgLogin];
        [[RgNetwork instance] login:rgLogin password:rgPass callback:callback failure:failure];
    }
}

+ (void)reset
{
    // clear linphone recent calls
    linphone_core_clear_call_logs([LinphoneManager getLc]);
    [[RgNetwork instance] signOut];
    [[[LinphoneManager instance] chatManager] disconnect];
    [LinphoneManager instance].chatManager = nil;
    [RgManager configReset];
}

@end
