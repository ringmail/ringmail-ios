//
//  RKAddress.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKAddress.h"
#import "RegexKitLite/RegexKitLite.h"

@implementation RKAddress

@synthesize address;
@synthesize displayName;
@synthesize avatarImage;
@synthesize contact;

+ (instancetype)newWithData:(NSDictionary*)param
{
	RKAddress *item = [[RKAddress alloc] init];
	item.address = param[@"address"];
	if (param[@"displayName"])
	{
		item.displayName = param[@"displayName"];
	}
	else
	{
		item.displayName = [item.address copy];
	}
	if (param[@"avatarImage"])
	{
		item.avatarImage = param[@"avatarImage"];
	}
	return item;
}

+ (BOOL)validEmailAddress:(NSString *)checkString
{
    // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

+ (BOOL)validAddress:(NSString*)address
{
    if ([address length] > 255)
    {
        return NO; // Too long, you're probably trying something fishy
    }
    NSString *lcAddress = [address lowercaseString];
    NSMutableString *numAddress = [address mutableCopy];
    [numAddress replaceOccurrencesOfRegex:@"[^0-9]" withString:@""];
    if ([address isMatchedByRegex:@"\\@"])
    {
        return [RKAddress validEmailAddress:address];
    }
    else if ([address isMatchedByRegex:@"\\."])
    {
        if ([address isMatchedByRegex:@"([A-Za-z0-9-]+\\.)+[A-Za-z]{1,}$"])
        {
            return YES;
        }
    }
    else if ([lcAddress isMatchedByRegex:@"^#[a-z0-9_]+$"]) // check hashtag
    {
        return YES;
    }
    else if ([numAddress length] >= 10 && [numAddress length] <= 20) // has a digit
    {
        return YES;
    }
    return NO;
}

- (RKAddressType)getAddressType
{
    NSString *lcAddress = [address lowercaseString];
    NSMutableString *numAddress = [address mutableCopy];
    [numAddress replaceOccurrencesOfRegex:@"[^0-9]" withString:@""];
    if ([address isMatchedByRegex:@"\\@"])
    {
        return RKAddressTypeEmail;
    }
    else if ([address isMatchedByRegex:@"\\."])
    {
		return RKAddressTypeDomain;
    }
    else if ([lcAddress isMatchedByRegex:@"^#[a-z0-9_]+$"])
    {
        return RKAddressTypeHashtag;
    }
    else if ([numAddress length] >= 10 && [numAddress length] <= 20) // has a digit
    {
        return RKAddressTypePhone;
    }
	NSAssert(NO, @"Invalid RingMail address: '%@'", address);
	return RKAddressTypeEmail;
}

- (BOOL)isEmail
{
	return ([self getAddressType] == RKAddressTypeEmail) ? YES : NO;
}

- (BOOL)isPhone;
{
	return ([self getAddressType] == RKAddressTypePhone) ? YES : NO;
}

- (BOOL)isDomain;
{
	return ([self getAddressType] == RKAddressTypeDomain) ? YES : NO;
}

- (BOOL)isHashtag;
{
	return ([self getAddressType] == RKAddressTypeHashtag) ? YES : NO;
}

- (BOOL)isEqual:(RKAddress*)object;
{
	return [address isEqualToString:[object address]];
}

@end
