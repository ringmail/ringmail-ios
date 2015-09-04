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

@end
