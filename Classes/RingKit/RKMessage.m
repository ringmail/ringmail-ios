//
//  RKMessage.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKAddress.h"
#import "RKMessage.h"
#import "RKPhotoMessage.h"
#import "RKThread.h"
#import "Utils.h"
#import "NSXMLElement+XMPP.h"
#import "RgManager.h"

@implementation RKMessage

@synthesize messageId;
@synthesize body;
@synthesize deliveryStatus;

+ (instancetype)newWithData:(NSDictionary*)param
{
	if (param[@"class"] != nil && ! [param[@"class"] isEqualToString:@""])
	{
		if ([param[@"class"] isEqualToString:@"RKPhotoMessage"])
		{
			return [[RKPhotoMessage alloc] initWithData:param];
		}
		else
		{
			NSAssert(FALSE, @"Invalid message class");
		}
	}
	return [[RKMessage alloc] initWithData:param];
}

- (instancetype)initWithData:(NSDictionary*)param
{
	self = [super initWithData:param];
	if (self)
	{
		if (param[@"messageId"])
        {
            NSAssert([param[@"messageId"] isKindOfClass:[NSNumber class]], @"messageId is not NSNumber object");
            [self setMessageId:param[@"messageId"]];
        }
		else
		{
			self->messageId = nil;
		}
		if (param[@"body"])
    	{
    		NSAssert([param[@"body"] isKindOfClass:[NSString class]], @"body is not NSString object");
    		[self setBody:param[@"body"]];
    	}
		if (param[@"deliveryStatus"])
    	{
    		NSAssert([param[@"deliveryStatus"] isKindOfClass:[NSNumber class]], @"deliveryStatus is not NSNumber object");
    		[self setDeliveryStatus:[param[@"deliveryStatus"] integerValue]];
    	}
	}
	return self;
}

- (NSString*)description
{
	NSDictionary* input = @{
		@"itemId": NULLIFNIL(self.itemId),
		@"messageId": NULLIFNIL(self.messageId),
		@"version": self.version,
		@"thread": [NSString stringWithFormat:@"<RKThread: %p>", self.thread],
		@"uuid": self.uuid,
		@"inbound": [NSNumber numberWithInteger:self.direction],
		@"timestamp": self.timestamp,
		@"body": self.body,
		@"deliveryStatus": _RKMessageStatus(self.deliveryStatus),
	};
    NSMutableString *data = [[NSMutableString alloc] init];
    for (NSString *k in input.allKeys)
	{
        [data appendFormat:@" %@:%@", k, input[k]];
	}
	return [NSString stringWithFormat:@"<RKMessage:%p {%@ }>", self, data];
}

- (void)insertItem:(NoteDatabase*)ndb
{
	NSAssert(self.thread.threadId, @"thread id required");
	[ndb set:@{
		@"table": @"rk_message",
		@"insert": @{
			@"thread_id": self.thread.threadId,
			@"msg_type": @"text/plain",
			@"msg_time": [[self timestamp] strftime],
			@"msg_status": [NSNumber numberWithInteger:[self deliveryStatus]],
			@"msg_uuid": [self uuid],
			@"msg_inbound": [NSNumber numberWithInteger:[self direction]],
			@"msg_body": [self body],
		},
	}];
	NSNumber* detailId = [ndb lastInsertId];
	self.messageId = detailId;
	[ndb set:@{
		@"table": @"rk_thread_item",
		@"insert": @{
			@"thread_id": self.thread.threadId,
			@"message_id": detailId,
			@"ts_created": [[self timestamp] strftime],
		},
	}];
	self.itemId = [ndb lastInsertId];
}

- (void)updateItem:(NoteDatabase*)ndb
{
	NSAssert(self.messageId, @"message id required");
	[ndb set:@{
		@"table": @"rk_message",
		@"update": @{
			@"msg_status": [NSNumber numberWithInteger:[self deliveryStatus]],
		},
		@"where": @{
			@"id": [self messageId],
		},
	}];
}

- (void)prepareMessage:(void (^)(NSObject* xml))send
{
	NSString *msgTo = [RgManager addressToXMPP:self.thread.remoteAddress.address];
    NSXMLElement *bodytag = [NSXMLElement elementWithName:@"body"];
    [bodytag setStringValue:self.body];
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"id" stringValue:self.uuid];
    [message addAttributeWithName:@"conversation" stringValue:self.thread.uuid];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    [message addAttributeWithName:@"timestamp" stringValue:[self.timestamp strftime]];
    [message addAttributeWithName:@"to" stringValue:msgTo];
	if (self.thread.originalTo != nil)
	{
		[message addAttributeWithName:@"reply-to" stringValue:self.thread.originalTo.address];
	}
	/*if (contact != nil)
	{
		// TODO: something different than a "reply-to" attribute
		[message addAttributeWithName:@"reply-to" stringValue:self.replyTo];
	}*/
    /*if (reply)
    {
       [message addAttributeWithName:@"reply" stringValue:reply];
    }*/
    [message addChild:bodytag];
	send(message);
}

@end
