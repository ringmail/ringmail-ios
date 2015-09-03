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
    return [NSString stringWithFormat:@""];
}

+ (NSString*)addressFromXMPP:(NSString*)addr
{
    return [NSString stringWithFormat:@""];
}

+ (LevelDB*)configDatabase
{
    return [LevelDB databaseInLibraryWithName:@"ringmail_config.ldb"];
}

@end