//
//  RgNetwork.m
//  ringmail
//
//  Created by Mike Frager on 9/4/15.
//
//

#import "LinphoneManager.h"
#import "RgNetwork.h"
#import "RgContactManager.h"

static RgNetwork* theRgNetwork = nil;

@implementation RgNetwork

@synthesize pushReady;

+ (RgNetwork *)instance {
    @synchronized(self) {
        if (theRgNetwork == nil) {
            theRgNetwork = [[RgNetwork alloc] init];
        }
    }
    return theRgNetwork;
}

- (id)init
{
    if (self = [super init])
    {
        self.networkHost = [RgManager ringmailHost];
        self.pushReady = [NSNumber numberWithBool:0];
    }
    return self;
}

- (void)log:(NSString*)logdata
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager.operationQueue waitUntilAllOperationsAreFinished];
    NSDictionary *parameters = @{@"message": logdata};
    NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/log", self.networkHost];
    [manager POST:postUrl parameters:parameters progress:nil success:^(NSURLSessionTask *operation, id responseObject) {
        NSLog(@"RingMail Logged: %@", logdata);
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"RingMail API Error: %@", error);
    }];
}

- (void)login:(NSString*)login password:(NSString*)password callback:(RgNetworkCallback)callback
{
    NSLog(@"RingMail: Login Request");
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    LevelDB* cfg = [RgManager configDatabase];
    NSDictionary *parameters = @{
                                 @"login": login,
                                 @"password": password,
                                 @"device": [cfg objectForKey:@"ringmail_device_uuid"],
                                 @"version": [info objectForKey:@"CFBundleShortVersionString"],
                                 @"build": [info objectForKey:@"CFBundleVersion"],
                                 @"timestamp": [NSString stringWithFormat:@"%s %s", __DATE__, __TIME__],
                                 };
    NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/login", self.networkHost];
    [manager POST:postUrl parameters:parameters progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"RingMail API Error: %@", error);
    }];
}

- (void)verifyPhone:(NSString*)code callback:(RgNetworkCallback)callback
{
    NSLog(@"RingMail: Verify Phone Code: %@", code);
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    LevelDB* cfg = [RgManager configDatabase];
    NSDictionary *parameters = @{
                                 @"login": cfg[@"ringmail_login"],
                                 @"password": cfg[@"ringmail_password"],
                                 @"phone": cfg[@"ringmail_phone"],
                                 @"code": code,
                                 };
    NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/check_phone", self.networkHost];
    [manager POST:postUrl parameters:parameters progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"RingMail API Error: %@", error);
    }];
}

- (void)registerPushToken
{
   NSData *tokenData = [[LinphoneManager instance] pushNotificationToken];
   if (tokenData != nil) {
       LevelDB* cfg = [RgManager configDatabase];
       NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
       NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
       NSData *rgVoipToken = [cfg objectForKey:@"ringmail_voip_token"];
       if (rgLogin != nil && rgPass != nil)
       {
           NSString* tokenString = [RgManager pushToken:tokenData];
           AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
           NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:@{@"login": rgLogin, @"password": rgPass, @"token": tokenString}];
           if (rgVoipToken)
           {
               [parameters setObject:[RgManager pushToken:rgVoipToken] forKey:@"voip_token"];
           }
           NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/register_push", self.networkHost];
           [manager POST:postUrl parameters:parameters progress:nil success:^(NSURLSessionTask *operation, id responseObject) {
               NSDictionary* res = responseObject;
               NSString *ok = [res objectForKey:@"result"];
               if (! [ok isEqualToString:@"ok"])
               {
                   NSLog(@"RingMail API Error: %@", @"Register Push Token Failed");
               }
               else
               {
                   self.pushReady = [NSNumber numberWithBool:1];
               }
           } failure:^(NSURLSessionTask *operation, NSError *error) {
               NSLog(@"RingMail API Error: %@", error);
           }];
       }
   }
}

 - (void)registerPushTokenVoIP:(NSData*)tokenData
{
    if (tokenData != nil) {
        LevelDB* cfg = [RgManager configDatabase];
        NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
        NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
        if (rgLogin != nil && rgPass != nil)
        {
            NSString* tokenString = [RgManager pushToken:tokenData];
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            NSDictionary *parameters = @{@"login": rgLogin, @"password": rgPass, @"voip_token": tokenString};
            NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/register_push", self.networkHost];
            [manager POST:postUrl parameters:parameters progress:nil success:^(NSURLSessionTask *operation, id responseObject) {
                NSDictionary* res = responseObject;
                NSString *ok = [res objectForKey:@"result"];
                if (! [ok isEqualToString:@"ok"])
                {
                    NSLog(@"RingMail API Error: %@", @"Register Push Token Failed");
                }
                else
                {
                    self.pushReady = [NSNumber numberWithBool:1];
                }
            } failure:^(NSURLSessionTask *operation, NSError *error) {
                NSLog(@"RingMail API Error: %@", error);
            }];
        }
    }
}

- (void)registerUser:(NSDictionary*)params callback:(RgNetworkCallback)callback
{
    NSString *rgLogin = [params objectForKey:@"email"];
    NSString *rgPass = [params objectForKey:@"password"];
    if (rgLogin != nil && rgPass != nil)
    {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSDictionary *parameters = @{
            @"first_name": params[@"first_name"],
            @"last_name": params[@"last_name"],
            @"email": rgLogin,
            @"phone": params[@"phone"],
            @"password": rgPass,
        };
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/register_user", self.networkHost];
        [manager POST:postUrl parameters:parameters progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"RingMail API Error: %@", error);
        }];
    }
}

- (void)resendVerify:(NSDictionary *)params callback:(RgNetworkCallback)callback
{
    if (params[@"email"] != nil || params[@"phone"] != nil)
    {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSDictionary *parameters = nil;
        if (params[@"email"])
        {
            parameters = @{@"email": params[@"email"]};
        }
        else if (params[@"phone"])
        {
            parameters = @{@"phone": params[@"phone"]};
        }
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/resend_verify", self.networkHost];
        [manager POST:postUrl parameters:parameters progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"RingMail API Error: %@", error);
        }];
    }
}

- (void)signOut
{
    LevelDB* cfg = [RgManager configDatabase];
    NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSDictionary *parameters = @{@"login": rgLogin, @"password": rgPass};
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/sign_out", self.networkHost];
        [manager POST:postUrl parameters:parameters progress:nil success:^(NSURLSessionTask *operation, id responseObject) {
            NSDictionary* res = responseObject;
            NSString *ok = [res objectForKey:@"result"];
            if (! (ok != nil && [ok isEqualToString:@"ok"]))
            {
                NSLog(@"RingMail API Error: %@", @"Sign Out Failed");
            }
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"RingMail API Error: %@", error);
        }];
    }
}

- (void)uploadImage:(NSData*)imageData uuid:(NSString*)uuid callback:(RgNetworkCallback)callback
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSDictionary *parameters = @{};
    [manager POST:[NSString stringWithFormat:@"https://%@/internal/app/chat_upload", self.networkHost] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"userfile" fileName:[NSString stringWithFormat:@"%@.png", uuid] mimeType:@"image/png"];
    } progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"RingMail - Chat Upload Error: %@", error);
    }];
}

- (void)downloadImage:(NSString*)url callback:(RgNetworkCallback)callback
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSDictionary *parameters = @{};
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"image/png"];
    [manager GET:url parameters:parameters progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"RingMail - Chat Download Error: %@", error);
    }];
}

- (void)updateContacts:(NSDictionary*)params callback:(RgNetworkCallback)callback
{
    LevelDB* cfg = [RgManager configDatabase];
    NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSDictionary *parameters = @{
                                     @"login": rgLogin,
                                     @"password": rgPass,
                                     @"contacts": [params objectForKey:@"contacts"],
                                     @"device": [cfg objectForKey:@"ringmail_device_uuid"],
                                     };
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/update_contacts", self.networkHost];
        [manager POST:postUrl parameters:parameters progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"RingMail API Error: %@", error);
        }];
    }
}

- (void)lookupHashtag:(NSDictionary*)params callback:(RgNetworkCallback)callback
{
    LevelDB* cfg = [RgManager configDatabase];
    NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
		parameters[@"login"] = rgLogin;
		parameters[@"password"] = rgPass;
		parameters[@"hashtag"] = params[@"hashtag"];
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/lookup_hashtag", self.networkHost];
        [manager POST:postUrl parameters:parameters progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"RingMail API Error: %@", error);
        }];
    }
}

- (void)hashtagDirectory:(NSDictionary*)params success:(RgNetworkCallback)okay failure:(RgNetworkError)fail
{
    LevelDB* cfg = [RgManager configDatabase];
    NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
		parameters[@"login"] = rgLogin;
		parameters[@"password"] = rgPass;
		parameters[@"category_id"] = params[@"category_id"];
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/hashtag_directory", self.networkHost];
        [manager POST:postUrl parameters:parameters progress:nil success:okay failure:fail];
    }
}

- (void)lookupConversation:(NSDictionary*)params callback:(RgNetworkCallback)callback
{
    LevelDB* cfg = [RgManager configDatabase];
    NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
		parameters[@"login"] = rgLogin;
		parameters[@"password"] = rgPass;
		parameters[@"to"] = params[@"to"];
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/conversation", self.networkHost];
        [manager POST:postUrl parameters:parameters progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"RingMail API Error: %@", error);
        }];
    }
}

@end
