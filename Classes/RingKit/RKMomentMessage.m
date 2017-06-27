//
//  RKMessage.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKCommunicator.h"
#import "RKMomentMessage.h"
#import "RKAddress.h"
#import "RKThread.h"
#import "RKThreadStore.h"

#import "RgManager.h"
#import "RgNetwork.h"
#import "Utils.h"
#import "NSXMLElement+XMPP.h"
#import "NSXMLElement+XEP_0335.h"

@implementation RKMomentMessage

@synthesize data;

+ (instancetype)newWithData:(NSDictionary*)param
{
	return [[RKMomentMessage alloc] initWithData:param];
}

- (instancetype)initWithData:(NSDictionary*)param
{
	self = [super initWithData:param];
	if (self)
	{
/*		if (param[@"data"])
        {
            NSAssert([param[@"data"] isKindOfClass:[NSDictionary class]], @"data is not NSDictionary object");
            [self setData:param[@"data"]];
        }
		else
		{*/
			self->data = @{};
//		}
	}
	return self;
}

- (void)prepareMessage:(void (^)(NSObject* xml))send
{
	NSString *msgTo = [RgManager addressToXMPP:self.thread.remoteAddress.address];
	
    __block NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:self.uuid];
    [message addAttributeWithName:@"conversation" stringValue:self.thread.uuid];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
	[message addAttributeWithName:@"class" stringValue:[NSString stringWithFormat:@"%s", object_getClassName(self)]];
    [message addAttributeWithName:@"timestamp" stringValue:[self.timestamp strftime]];
    [message addAttributeWithName:@"to" stringValue:msgTo];
	if (self.thread.originalTo != nil)
	{
		[message addAttributeWithName:@"reply-to" stringValue:self.thread.originalTo.address];
	}
	
    NSXMLElement *bodytag = [NSXMLElement elementWithName:@"body"];
	if (self.body != nil)
	{
        [bodytag setStringValue:self.body];
	}
	else
	{
        [bodytag setStringValue:@""];
	}
    [message addChild:bodytag];
	
	// Media attachment upload then send
	NSAssert(self.mediaData != nil, @"mediaData required");
	//NSAssert(self.data != nil, @"data required");
	[self uploadMedia:^(BOOL success) {
		if (success)
		{
            NSXMLElement *attach = [NSXMLElement elementWithName:@"attachment"];
            [attach addAttributeWithName:@"type" stringValue:self.mediaType];
            [attach addAttributeWithName:@"id" stringValue:self.uuid];
            [attach addAttributeWithName:@"url" stringValue:self.remoteURL.absoluteString];
            [message addChild:attach];
			[message addJSONContainerWithObject:self.data];
			
        	send(message);
		}
	}];
}

- (NSURL*)documentURL
{
	NSString* mainUuid = [self uuid];
	NSURL* url = [self applicationDocumentsDirectory];
	NSString* urlStr = [url absoluteString];
	urlStr = [urlStr stringByAppendingPathComponent:mainUuid];
	url = [NSURL URLWithString:urlStr];
	return url;
}

- (void)onComplete
{
	NSLog(@"Moment Complete");
	[[RKThreadStore sharedInstance] setHidden:YES forItemId:[self itemId]];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKMessageRemoved object:self userInfo:@{
		@"message": self,
	}];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKItemActivity object:self userInfo:@{
		@"type": @"message",
		@"message": self,
		@"name": kRKMessageUpdated,
	}];
}

@end
