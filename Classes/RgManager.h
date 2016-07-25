//
//  RgManager.h
//  ringmail
//
//  Created by Mike Frager on 9/1/15.
//
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <ObjectiveSugar/ObjectiveSugar.h>
#import "RegexKitLite/RegexKitLite.h"
#import "LevelDB.h"
#import "RgNetwork.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"

/* RingMail */
extern NSString *const kRgTextReceived;
extern NSString *const kRgTextSent;
extern NSString *const kRgTextUpdate;
extern NSString *const kRgContactsUpdated;
extern NSString *const kRgSetAddress;
extern NSString *const kRgMainRefresh;
extern NSString *const kRgFavoriteRefresh;
extern NSString *const kRgAttemptVerify;
extern NSString *const kRgLaunchBrowser;
extern NSString *const kRgToggleNumberPad;
extern NSString *const kRgCallRefresh;
extern NSString *const kRgContactRefresh;

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
+ (BOOL)hasContactId:(NSNumber*)contact;
+ (NSString*)formatPhoneNumber:(NSString*)addr;
+ (NSString*)pushToken:(NSData*)tokenData;
+ (void)setupPushToken;
+ (void)processRingURI:(NSString*)uri;
+ (BOOL)checkEmailAddress:(NSString *)checkString;
+ (BOOL)checkRingMailAddress:(NSString *)checkString;
+ (NSString*)filterRingMailAddress:(NSString*)address;
+ (void)startCall:(NSString*)address contact:(ABRecordRef)contact video:(BOOL)video;
+ (void)startMessage:(NSString*)address contact:(ABRecordRef)contact;
+ (void)startMessageMD5;
+ (void)startHashtag:(NSString*)address;

+ (LevelDB*)configDatabase;
+ (void)closeConfigDatabase;
+ (NSDictionary *)getCredentials;

+ (void)configReset;
+ (BOOL)configReady;
+ (BOOL)configEmailVerified;
+ (BOOL)configPhoneVerified;
+ (BOOL)configReadyAndVerified;

+ (void)updateCredentials:(NSDictionary*)cred;
+ (void)chatConnect;
+ (void)chatEnsureConnection;
+ (void)initialLogin;
+ (void)verifyLogin:(RgNetworkCallback)callback;

@end
