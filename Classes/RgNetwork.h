//
//  RgNetwork.h
//  ringmail
//
//  Created by Mike Frager on 9/4/15.
//
//

#import <Foundation/Foundation.h>
#import "AFNetworking/AFNetworking.h"

typedef void (^RgNetworkCallback)(AFHTTPRequestOperation *operation, id responseObject);

@interface RgNetwork : NSObject

@property (nonatomic, strong) NSString* networkHost;
@property (nonatomic, strong) NSNumber* pushReady;

+ (RgNetwork *)instance;
- (void)login:(NSString*)login password:(NSString*)password callback:(RgNetworkCallback)callback;
- (void)registerPushToken;

- (void)signOut;
- (void)log:(NSString*)logdata;
- (void)registerUser:(NSDictionary*)params callback:(RgNetworkCallback)callback;
- (void)registerPushTokenVoIP:(NSData*)tokenData;
- (void)resendVerify:(NSDictionary*)params callback:(RgNetworkCallback)callback;
- (void)uploadImage:(NSData*)imageData uuid:(NSString*)uuid callback:(RgNetworkCallback)callback;
- (void)downloadImage:(NSString*)url callback:(RgNetworkCallback)callback;

@end
