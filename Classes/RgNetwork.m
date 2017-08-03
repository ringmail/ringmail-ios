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
#import "RgLocationManager.h"

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

- (void)login:(NSString*)login password:(NSString*)password callback:(RgNetworkCallback)callback failure:(RgNetworkError)failure
{
    NSLog(@"RingMail: Login Request");
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager.requestSerializer setTimeoutInterval:15]; // mrkbxt
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
    [manager POST:postUrl parameters:parameters progress:nil success:callback failure:failure];
}

- (void)loginGoogle:(NSString*)login idToken:(NSString*)idToken accessToken:(NSString*)accessToken callback:(RgNetworkCallback)callback failure:(RgNetworkError)failure
{
    NSLog(@"RingMail: Google Login Request");
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager.requestSerializer setTimeoutInterval:15];
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    LevelDB* cfg = [RgManager configDatabase];
    NSDictionary *parameters = @{
                                 @"login": login,
                                 @"idToken": idToken,
                                 @"accessToken": accessToken,
                                 @"device": [cfg objectForKey:@"ringmail_device_uuid"],
                                 @"version": [info objectForKey:@"CFBundleShortVersionString"],
                                 @"build": [info objectForKey:@"CFBundleVersion"],
                                 @"timestamp": [NSString stringWithFormat:@"%s %s", __DATE__, __TIME__],
                                 };
    NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/login", self.networkHost];
    [manager POST:postUrl parameters:parameters progress:nil success:callback failure:failure];
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
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/register_user", self.networkHost];
        [manager POST:postUrl parameters:params progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
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

// Stream upload :)

- (void)uploadURL:(NSURL*)localUrl mimeType:(NSString*)ct extension:(NSString*)ext uuid:(NSString*)uuid callback:(RgNetworkCallback)callback
{
    NSError *attributesError = nil;
    __block NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[localUrl path] error:&attributesError];
    NSInputStream *fileStream = [NSInputStream inputStreamWithURL:localUrl];
    NSError *requestError;
    NSString *requestURI = [NSString stringWithFormat:@"https://%@/internal/app/chat_upload", self.networkHost];
    NSDictionary *parameters = @{
		@"mime_type": ct,
    };
    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString:requestURI parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        NSString *name = [NSString stringWithFormat:@"%@.%@", uuid, ext];
        [formData appendPartWithInputStream:fileStream name:@"userfile" fileName:name length:[fileAttributes fileSize] mimeType:ct];
    } error:&requestError];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    __block NSURLSessionUploadTask *uploadTask;
	NSLog(@"Begin Upload: %@", localUrl);
    uploadTask = [manager uploadTaskWithStreamedRequest:request progress:^(NSProgress* uploadProgress) {
        // This is not called back on the main queue.
        // You are responsible for dispatching to the main queue for UI updates
        NSLog(@"Upload: %f", uploadProgress.fractionCompleted);
    } completionHandler:^(NSURLResponse* response, id responseObject, NSError* error) {
        if (error) {
            NSLog(@"Upload Error: %@", [error userInfo]);
        } else {
			NSLog(@"Upload Success: %@ %@", response, responseObject);
            callback(uploadTask, responseObject);
        }
	}];
	[uploadTask resume];
}

- (void)downloadURL:(NSURL*)source destination:(NSURL*)dest callback:(RgNetworkCallback)callback
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    NSURLRequest *request = [NSURLRequest requestWithURL:source];
    __block NSURLSessionDownloadTask *downloadTask;
    downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
		NSLog(@"Download: %f", downloadProgress.fractionCompleted);
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return dest;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (error) {
            NSLog(@"Download Error: %@", [error userInfo]);
        } else {
			NSLog(@"Downlaod Success: %@", response);
			callback(downloadTask, @{@"result": @"ok"});
        }
    }];
    [downloadTask resume];
}

- (void)uploadData:(NSData*)imageData mimeType:(NSString*)ct extension:(NSString*)ext uuid:(NSString*)uuid callback:(RgNetworkCallback)callback
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSDictionary *parameters = @{
		@"mime_type": ct,
	};
    [manager POST:[NSString stringWithFormat:@"https://%@/internal/app/chat_upload", self.networkHost] parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:imageData name:@"userfile" fileName:[NSString stringWithFormat:@"%@.%@", uuid, ext] mimeType:ct];
    } progress:nil success:callback failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"RingMail - Chat Upload Error: %@", error);
    }];
}

- (void)downloadData:(NSString*)url callback:(RgNetworkCallback)callback
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
        NSString *lat = [NSString stringWithFormat:@"%f", [RgLocationManager sharedInstance].currentLocation.coordinate.latitude];
        NSString *lon = [NSString stringWithFormat:@"%f", [RgLocationManager sharedInstance].currentLocation.coordinate.longitude];
        
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
		parameters[@"login"] = rgLogin;
		parameters[@"password"] = rgPass;
		parameters[@"hashtag"] = params[@"hashtag"];
        parameters[@"lat"] = lat;
        parameters[@"lon"] = lon;
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
		/* Geo coordinates */
        NSString *lat = [NSString stringWithFormat:@"%f", [RgLocationManager sharedInstance].currentLocation.coordinate.latitude];
        NSString *lon = [NSString stringWithFormat:@"%f", [RgLocationManager sharedInstance].currentLocation.coordinate.longitude];
		
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
		parameters[@"login"] = rgLogin;
		parameters[@"password"] = rgPass;
		parameters[@"category_id"] = params[@"category_id"];
        parameters[@"lat"] = lat;
        parameters[@"lon"] = lon;
        parameters[@"width"] = params[@"screen_width"];
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


- (void)shareLocation:(NSDictionary*)params success:(RgNetworkCallback)okay failure:(RgNetworkError)fail
{
    LevelDB* cfg = [RgManager configDatabase];
    NSString *rgLogin = [cfg objectForKey:@"ringmail_login"];
    NSString *rgPass = [cfg objectForKey:@"ringmail_password"];
    if (rgLogin != nil && rgPass != nil)
    {
        NSString *lat = [NSString stringWithFormat:@"%f", [RgLocationManager sharedInstance].currentLocation.coordinate.latitude];
        NSString *lon = [NSString stringWithFormat:@"%f", [RgLocationManager sharedInstance].currentLocation.coordinate.longitude];
        
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"login"] = rgLogin;
        parameters[@"password"] = rgPass;
        parameters[@"lat"] = lat;
        parameters[@"lon"] = lon;
        parameters[@"to"] = params[@"to"];
        parameters[@"from"] = params[@"from"];
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/sharelocation", self.networkHost];
        [manager POST:postUrl parameters:parameters progress:nil success:okay failure:fail];
    }
}

- (void)shareContact:(NSDictionary*)params success:(RgNetworkCallback)okay failure:(RgNetworkError)fail
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
        parameters[@"from"] = params[@"from"];
        NSString *postUrl = [NSString stringWithFormat:@"https://%@/internal/app/sharecontact", self.networkHost];
        [manager POST:postUrl parameters:parameters progress:nil success:okay failure:fail];
    }
}


@end
