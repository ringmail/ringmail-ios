//
//  RKMessage.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKVideoMessage.h"
#import "RKAddress.h"
#import "RKThread.h"

#import "RgManager.h"
#import "RgNetwork.h"
#import "Utils.h"
#import "NSXMLElement+XMPP.h"

@implementation RKVideoMessage

+ (instancetype)newWithData:(NSDictionary*)param
{
	return [[RKVideoMessage alloc] initWithData:param];
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
	NSAssert(self.localPath != nil, @"localPath required");
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
	NSString* otherPath = [self localPath];
	NSURL* url = [self applicationDocumentsDirectory];
	NSString* urlStr = [url absoluteString];
	if (otherPath != nil)
	{
		urlStr = [urlStr stringByAppendingPathComponent:otherPath];
	}
	else
	{
		urlStr = [urlStr stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov", mainUuid]];
	}
	url = [NSURL URLWithString:urlStr];
	return url;
}

// TODO: add error handlers
- (void)downloadMedia:(void (^)(BOOL success))complete
{
	NSAssert(self.remoteURL, @"Remote URL required");
    [[RgNetwork instance] downloadURL:[self remoteURL] destination:[self documentURL] callback:^(NSURLSessionTask *operation, id responseObject) {
        NSLog(@"%s: Download Complete", __PRETTY_FUNCTION__);
		self.mediaType = @"video/mp4";
		complete(TRUE);
    }];
}

@end
