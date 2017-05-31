//
//  RKMessage.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKMediaMessage.h"
#import "RKAddress.h"
#import "RKThread.h"

#import "RgManager.h"
#import "RgNetwork.h"
#import "Utils.h"
#import "NSXMLElement+XMPP.h"

@implementation RKMediaMessage

@synthesize mediaURL;
@synthesize mediaData;
@synthesize mediaType;

+ (instancetype)newWithData:(NSDictionary*)param
{
	return [[RKMediaMessage alloc] initWithData:param];
}

- (instancetype)initWithData:(NSDictionary*)param
{
	self = [super initWithData:param];
	if (self)
	{
		if (param[@"mediaURL"])
        {
            NSAssert([param[@"mediaURL"] isKindOfClass:[NSURL class]], @"mediaURL is not NSURL object");
            [self setMediaURL:param[@"mediaURL"]];
        }
		else
		{
			self->mediaURL = nil;
		}
		if (param[@"mediaData"])
        {
            NSAssert([param[@"mediaData"] isKindOfClass:[NSData class]], @"mediaData is not NSData object");
            [self setMediaData:param[@"mediaData"]];
        }
		else
		{
			self->mediaData = nil;
		}
		if (param[@"mediaType"])
        {
            NSAssert([param[@"mediaType"] isKindOfClass:[NSString class]], @"mediaType is not NSString object");
            [self setMediaType:param[@"mediaType"]];
        }
		else
		{
			self->mediaType = nil;
		}
	}
	return self;
}

- (NSString*)description
{
	NSDictionary* input = @{
		@"itemId": NULLIFNIL(self.itemId),
		@"messageId": NULLIFNIL(self.messageId),
		@"thread": [NSString stringWithFormat:@"<RKThread: %p>", self.thread],
		@"uuid": self.uuid,
		@"inbound": [NSNumber numberWithInteger:self.direction],
		@"timestamp": self.timestamp,
		@"body": self.body,
		@"deliveryStatus": self.deliveryStatus,
		@"mediaURL": NULLIFNIL(self.mediaURL),
		@"mediaData": NULLIFNIL(self.mediaData),
	};
    NSMutableString *data = [[NSMutableString alloc] init];
    for (NSString *k in input.allKeys)
	{
        [data appendFormat:@" %@:%@", k, input[k]];
	}
	return [NSString stringWithFormat:@"<RKMediaMessage:%p {%@ }>", self, data];
}

- (void)uploadMedia:(void (^)(BOOL success))complete
{
    [[RgNetwork instance] uploadImage:self.mediaData uuid:self.uuid callback:^(NSURLSessionTask *operation, id responseObject) {
        NSDictionary* res = responseObject;
        NSString *ok = res[@"result"];
        if ([ok isEqualToString:@"ok"])
        {
			self.mediaURL = [NSURL URLWithString:res[@"url"]];
			complete(TRUE);
		}
		else
		{
			complete(FALSE);
		}
	}];
}

- (void)downloadMedia:(void (^)(BOOL success))complete
{
}

- (void)prepareMessage:(void (^)(NSObject* xml))send
{
	NSString *msgTo = [RgManager addressToXMPP:self.thread.remoteAddress.address];
	
    __block NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:self.uuid];
    [message addAttributeWithName:@"conversation" stringValue:self.thread.uuid];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
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
            [attach addAttributeWithName:@"url" stringValue:self.mediaURL.absoluteString];
            [message addChild:attach];
			
        	send(message);
		}
	}];
}

@end
