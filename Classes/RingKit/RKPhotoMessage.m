//
//  RKMessage.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKPhotoMessage.h"
#import "RKAddress.h"
#import "RKThread.h"

#import "RgManager.h"
#import "RgNetwork.h"
#import "Utils.h"
#import "NSXMLElement+XMPP.h"

@implementation RKPhotoMessage

+ (instancetype)newWithData:(NSDictionary*)param
{
	return [[RKPhotoMessage alloc] initWithData:param];
}

- (instancetype)initWithData:(NSDictionary*)param
{
	self = [super initWithData:param];
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
	[self uploadMedia:^(BOOL success) {
		if (success)
		{
            NSXMLElement *attach = [NSXMLElement elementWithName:@"attachment"];
            [attach addAttributeWithName:@"type" stringValue:self.mediaType];
            [attach addAttributeWithName:@"id" stringValue:self.uuid];
            [attach addAttributeWithName:@"url" stringValue:self.remoteURL.absoluteString];
            [message addChild:attach];
			
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

@end
