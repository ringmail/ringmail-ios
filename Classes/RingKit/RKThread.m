//
//  RKThread.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "Utils.h"
#import "RKAddress.h"
#import "RKContact.h"
#import "RKThread.h"

@implementation RKThread

@synthesize threadId;
@synthesize remoteAddress;
@synthesize originalTo;
@synthesize contact;
@synthesize uuid;

+ (instancetype)newWithData:(NSDictionary*)param
{
	RKThread *item = [[RKThread alloc] init];
	item.threadId = nil;
	item.remoteAddress = nil;
	item.originalTo = nil;
	item.contact = nil;
	item.uuid = nil;
	if (param[@"threadId"])
	{
		NSAssert([param[@"threadId"] isKindOfClass:[NSNumber class]], @"threadId is not NSNumber object");
		item.threadId = param[@"threadId"];
	}
	if (param[@"remoteAddress"])
	{
		NSAssert([param[@"remoteAddress"] isKindOfClass:[RKAddress class]], @"remoteAddress is not RKAddress object");
		item.remoteAddress = param[@"remoteAddress"];
	}
	if (param[@"originalTo"])
	{
		NSAssert([param[@"originalTo"] isKindOfClass:[RKAddress class]], @"originalTo is not RKAddress object");
		item.originalTo = param[@"originalTo"];
	}
	if (param[@"contact"])
	{
		NSAssert([param[@"contact"] isKindOfClass:[RKContact class]], @"contact is not RKContact object");
		item.contact = param[@"contact"];
	}
	if (param[@"uuid"])
	{
		NSAssert([param[@"uuid"] isKindOfClass:[NSString class]], @"uuid is not NSString object");
		item.uuid = param[@"uuid"];
	}
	else
	{
		item.uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
	}
	return item;
}

- (NSString*)description
{
	NSDictionary* input = @{
		@"threadId": NULLIFNIL(self.threadId),
		@"remoteAddress": self.remoteAddress,
		@"originalTo": NULLIFNIL(self.originalTo),
		@"contact": NULLIFNIL(self.contact),
		@"uuid": self.uuid
	};
    NSMutableString *data = [[NSMutableString alloc] init];
    for (NSString *k in input.allKeys)
	{
        [data appendFormat:@" %@:%@", k, input[k]];
	}
	return [NSString stringWithFormat:@"<RKThread:%p {%@ }>", self, data];
}

@end
