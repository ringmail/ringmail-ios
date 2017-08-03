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
extern NSString *const kRgTextReceived; // deprec
extern NSString *const kRgTextSent; // deprec
extern NSString *const kRgTextUpdate; // deprec
extern NSString *const kRgSetAddress;
extern NSString *const kRgMainRemove;
extern NSString *const kRgFavoriteRefresh;
extern NSString *const kRgAttemptVerify;
extern NSString *const kRgLaunchBrowser;
extern NSString *const kRgToggleNumberPad;
extern NSString *const kRgCallRefresh;
extern NSString *const kRgContactsUpdated;
extern NSString *const kRgNavBarViewChange;
extern NSString *const kRgHashtagDirectoryUpdatePath;
extern NSString *const kRgHashtagDirectoryRefreshPath;
extern NSString *const kRgSegmentControl;
extern NSString *const kRgCurrentLocation;
extern NSString *const kRgGoogleSignInStart;
extern NSString *const kRgGoogleSignInComplete;
extern NSString *const kRgGoogleSignInVerifed;
extern NSString *const kRgGoogleSignInError;
extern NSString *const kRgUserUnauthorized;
extern NSString *const kRgSendComponentReset;
extern NSString *const kRgSendComponentUpdateTo;
extern NSString *const kRgSendComponentAddMedia;
extern NSString *const kRgSendComponentRemoveMedia;
extern NSString *const kRgSendContactSelectDone;
extern NSString *const kRgAddContact;
extern NSString *const kRgPresentOptionsModal;
extern NSString *const kRgDismissOptionsModal;
extern NSString *const kRgAddMessageMedia;
extern NSString *const kRgReset;

typedef NS_ENUM(NSInteger, RgSendMediaEditMode) {
        RgSendMediaEditModeSendPanel,
        RgSendMediaEditModeMoment,
        RgSendMediaEditModeMessage
};

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
+ (void)startHashtag:(NSString*)address;

+ (LevelDB*)configDatabase;
+ (void)closeConfigDatabase;
+ (NSDictionary *)getCredentials;

+ (void)reset;
+ (void)configReset;
+ (BOOL)configReady;
+ (BOOL)configEmailVerified;
+ (BOOL)configPhoneVerified;
+ (BOOL)configReadyAndVerified;

+ (void)updateCredentials:(NSDictionary*)cred;
+ (void)updateContacts:(NSDictionary*)res;
+ (void)chatConnect;
+ (void)chatEnsureConnection;
+ (void)initialLogin;
+ (void)verifyLogin:(RgNetworkCallback)callback failure:(RgNetworkError)failure;

@end
