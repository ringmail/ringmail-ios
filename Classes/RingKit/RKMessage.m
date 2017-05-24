//
//  RKMessage.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKMessage.h"
#import "RKThread.h"
#import "Utils.h"

@implementation RKMessage

@synthesize messageId;
@synthesize body;
@synthesize deliveryStatus;

+ (instancetype)newWithData:(NSDictionary*)param
{
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
    		NSAssert([param[@"deliveryStatus"] isKindOfClass:[NSString class]], @"deliveryStatus is not NSString object");
    		[self setDeliveryStatus:param[@"deliveryStatus"]];
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
			@"msg_status": [self deliveryStatus],
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

@end
