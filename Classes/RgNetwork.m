//
//  RgNetwork.m
//  ringmail
//
//  Created by Mike Frager on 9/4/15.
//
//

#import "RgNetwork.h"
#import "LinphoneManager.h"

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

- (void)login:(NSString*)login password:(NSString*)password callback:(RgNetworkCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"login": login, @"password": password, @"version": @"2.0.1", @"build_ts": [NSString stringWithFormat:@"%s %s", __DATE__, __TIME__]};
    NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/login", self.networkHost];
    [manager POST:postUrl parameters:parameters success:callback failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
       if (rgLogin != nil && rgPass != nil)
       {
           NSString* tokenString = [RgManager pushToken:tokenData];
           AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
           NSDictionary *parameters = @{@"login": rgLogin, @"password": rgPass, @"token": tokenString};
           NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/register_push", self.networkHost];
           [manager POST:postUrl parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSDictionary *parameters = @{@"email": rgLogin, @"password": rgPass};
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/register_user", self.networkHost];
        [manager POST:postUrl parameters:parameters success:callback failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"RingMail API Error: %@", error);
        }];
    }
}

- (void)resendVerify:(NSDictionary *)params callback:(RgNetworkCallback)callback
{
    NSString *rgLogin = [params objectForKey:@"email"];
    if (rgLogin != nil)
    {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSDictionary *parameters = @{@"email": rgLogin};
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/resend_verify", self.networkHost];
        [manager POST:postUrl parameters:parameters success:callback failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSDictionary *parameters = @{@"login": rgLogin, @"password": rgPass};
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/sign_out", self.networkHost];
        [manager POST:postUrl parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary* res = responseObject;
            NSString *ok = [res objectForKey:@"result"];
            if (! [ok isEqualToString:@"ok"])
            {
                NSLog(@"RingMail API Error: %@", @"Sign Out Failed");
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"RingMail API Error: %@", error);
        }];
    }
}

- (void)uploadImage:(NSData*)imageData uuid:(NSString*)uuid callback:(RgNetworkCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{};
    [manager POST:[NSString stringWithFormat:@"https://%@/internal/app/chat_upload", self.networkHost] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"userfile" fileName:[NSString stringWithFormat:@"%@.png", uuid] mimeType:@"image/png"];
    } success:callback failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"RingMail - Chat Upload Error: %@", error);
    }];
}

- (void)downloadImage:(NSString*)url callback:(RgNetworkCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{};
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"image/png"];
    [manager GET:url parameters:parameters success:callback failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"RingMail - Chat Download Error: %@", error);
    }];
}

@end
