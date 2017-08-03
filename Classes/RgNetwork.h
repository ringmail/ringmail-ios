//
//  RgNetwork.h
//  ringmail
//
//  Created by Mike Frager on 9/4/15.
//
//

#import <Foundation/Foundation.h>
#import "AFNetworking/AFNetworking.h"

typedef void (^RgNetworkCallback)(NSURLSessionTask *operation, id responseObject);
typedef void (^RgNetworkError)(NSURLSessionTask *operation, NSError *error);
typedef void (^RgConversation)(NSString *to);

@interface RgNetwork : NSObject

@property (nonatomic, strong) NSString* networkHost;
@property (nonatomic, strong) NSNumber* pushReady;

+ (RgNetwork *)instance;
- (void)login:(NSString*)login password:(NSString*)password callback:(RgNetworkCallback)callback failure:(RgNetworkError)failure;
- (void)loginGoogle:(NSString*)login idToken:(NSString*)idToken accessToken:(NSString*)accessToken callback:(RgNetworkCallback)callback failure:(RgNetworkError)failure;
- (void)verifyPhone:(NSString*)code callback:(RgNetworkCallback)callback;
- (void)registerPushToken;

- (void)signOut;
- (void)log:(NSString*)logdata;
- (void)registerUser:(NSDictionary*)params callback:(RgNetworkCallback)callback;
- (void)registerPushTokenVoIP:(NSData*)tokenData;
- (void)resendVerify:(NSDictionary*)params callback:(RgNetworkCallback)callback;
- (void)uploadURL:(NSURL*)localUrl mimeType:(NSString*)ct extension:(NSString*)ext uuid:(NSString*)uuid callback:(RgNetworkCallback)callback;
- (void)downloadURL:(NSURL*)source destination:(NSURL*)dest callback:(RgNetworkCallback)callback;
- (void)uploadData:(NSData*)imageData mimeType:(NSString*)ct extension:(NSString*)ext uuid:(NSString*)uuid callback:(RgNetworkCallback)callback;
- (void)downloadData:(NSString*)url callback:(RgNetworkCallback)callback;
- (void)updateContacts:(NSDictionary*)params callback:(RgNetworkCallback)callback;
- (void)lookupHashtag:(NSDictionary*)params callback:(RgNetworkCallback)callback;
- (void)hashtagDirectory:(NSDictionary*)params success:(RgNetworkCallback)okay failure:(RgNetworkError)fail;
- (void)lookupConversation:(NSDictionary*)params callback:(RgNetworkCallback)callback;
//- (void)shareLocation:(NSDictionary*)params success:(RgNetworkCallback)okay failure:(RgNetworkError)fail;
//- (void)shareContact:(NSDictionary*)params success:(RgNetworkCallback)okay failure:(RgNetworkError)fail;

@end
