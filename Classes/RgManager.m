//
//  RgManager.m
//  ringmail
//
//  Created by Mike Frager on 9/1/15.
//
//

#import "RgManager.h"

/* RingMail */

NSString *const kRgTextReceived = @"RgTextReceived";

NSString *const kRgSelf = @"self";
NSString *const kRgSelfName = @"Self";

static LevelDB* theConfigDatabase = nil;

@implementation RgManager

+ (NSString*)addressToSIP:(NSString*)addr
{
    return [addr stringByReplacingOccurrencesOfString:@"@" withString:@"\\"];
}

+ (NSString*)addressFromSIP:(NSString*)addr
{
    NSString *res = [addr stringByMatching:@"^\\w+:(.*?)\\@" capture:1];
    res = [res stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [res stringByReplacingOccurrencesOfString:@"\\" withString:@"@"];
}

+ (NSString*)addressToXMPP:(NSString*)addr
{
    addr = [addr stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLUserAllowedCharacterSet];
    return [NSString stringWithFormat:@"%@@staging.ringmail.com", addr];
}

+ (NSString*)addressFromXMPP:(NSString*)addr
{
    NSString *res = [addr stringByMatching:@"^(.*?)\\@" capture:1];
    return [res stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (LevelDB*)configDatabase
{
    if (theConfigDatabase == nil)
    {
        theConfigDatabase = [LevelDB databaseInLibraryWithName:@"ringmail_config.ldb"];
    }
    return theConfigDatabase;
}

+ (void)closeConfigDatabase
{
    theConfigDatabase = nil;
}

@end