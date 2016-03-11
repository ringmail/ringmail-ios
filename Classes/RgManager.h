//
//  RgManager.h
//  ringmail
//
//  Created by Mike Frager on 9/1/15.
//
//

#import <Foundation/Foundation.h>
#import "RegexKitLite/RegexKitLite.h"
#import "LevelDB.h"
#import "RgNetwork.h"

/* RingMail */
extern NSString *const kRgTextReceived;
extern NSString *const kRgTextSent;
extern NSString *const kRgTextUpdate;
extern NSString *const kRgContactsUpdated;
extern NSString *const kRgSetAddress;
extern NSString *const kRgMainRefresh;

extern NSString *const kRgSelf;
extern NSString *const kRgSelfName;


@interface RgManager : NSObject

+ (NSString*)ringmailHost;
+ (NSString*)ringmailHostSIP;
+ (NSString*)addressToSIP:(NSString*)addr;
+ (NSString*)addressFromSIP:(NSString*)addr;
+ (NSString*)addressFromSIPUser:(NSString*)addr;
+ (NSString*)addressToXMPP:(NSString*)addr;
+ (NSString*)addressFromXMPP:(NSString*)addr;
+ (NSString*)pushToken:(NSData*)tokenData;
+ (void)setupPushToken;
+ (void)processRingURI:(NSString*)uri;
+ (BOOL)checkEmailAddress:(NSString *)checkString;
+ (BOOL)checkRingMailAddress:(NSString *)checkString;
+ (NSString*)filterRingMailAddress:(NSString*)address;
+ (void)startCall:(NSString*)address;
+ (void)startMessage:(NSString*)address;
+ (void)startMessageMD5;

+ (LevelDB*)configDatabase;
+ (void)closeConfigDatabase;
+ (NSDictionary *)getCredentials;

+ (void)configReset;
+ (BOOL)configReady;
+ (BOOL)configVerified;
+ (BOOL)configReadyAndVerified;

+ (void)updateCredentials:(NSDictionary*)cred;
+ (void)chatConnect;
+ (void)chatEnsureConnection;
+ (void)initialLogin;
+ (void)verifyLogin:(RgNetworkCallback)callback;

@end
