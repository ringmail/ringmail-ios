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
        self.networkHost = @"staging.ringmail.com";
    }
    return self;
}

- (void)login:(NSString*)login password:(NSString*)password
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"login": login, @"password": password};
    NSString *postUrl = [NSString stringWithFormat:@"http://%@/internal/app/login", self.networkHost];
    [manager POST:postUrl parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary* res = responseObject;
        NSString *sip = [res objectForKey:@"sip_login"];
        if (sip != nil)
        {
            LinphoneManager *mgr = [LinphoneManager instance];
            [mgr rgUpdateCredentials:res];
        }
        else
        {
            NSLog(@"RingMail API Error: %@", @"Login Failed");
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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
           NSString *postUrl = [NSString stringWithFormat:@"http://%@/internal/app/register_push", self.networkHost];
           [manager POST:postUrl parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
               NSDictionary* res = responseObject;
               NSString *ok = [res objectForKey:@"result"];
               if (! [ok isEqualToString:@"ok"])
               {
                   NSLog(@"RingMail API Error: %@", @"Register Push Token Failed");
               }
           } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               NSLog(@"RingMail API Error: %@", error);
           }];
       }
   }
}

@end
