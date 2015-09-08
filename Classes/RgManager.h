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

/* RingMail */
extern NSString *const kRgTextReceived;

extern NSString *const kRgSelf;
extern NSString *const kRgSelfName;


@interface RgManager : NSObject

+ (NSString*)addressToSIP:(NSString*)addr;
+ (NSString*)addressFromSIP:(NSString*)addr;
+ (NSString*)addressToXMPP:(NSString*)addr;
+ (NSString*)addressFromXMPP:(NSString*)addr;
+ (NSString*)pushToken:(NSData*)tokenData;

+ (LevelDB*)configDatabase;
+ (void)closeConfigDatabase;

@end
