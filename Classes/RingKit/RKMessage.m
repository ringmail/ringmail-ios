//
//  RKMessage.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKMessage.h"
#import "RKThread.h"

@implementation RKMessage

@synthesize body;
@synthesize deliveryStatus;

- (instancetype)initWithData:(NSDictionary*)param
{
	self = [super initWithData:param];
	if (self)
	{
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

- (void)insertItem:(NoteDatabase*)ndb
{
	NSAssert(self.thread.threadId, @"thread id required");
	[ndb set:@{
		@"table": @"rk_message",
		@"insert": @{
			@"msg_type": @"text/plain",
			@"msg_time": [[self timestamp] strftime],
			@"msg_status": [self deliveryStatus],
			@"msg_uuid": [self uuid],
			@"msg_inbound": [NSNumber numberWithInteger:[self direction]],
			@"msg_body": [self body],
		},
	}];
	NSNumber* detailId = [ndb lastInsertId];
	[ndb set:@{
		@"table": @"rk_thread_item",
		@"insert": @{
			@"thread_id": self.thread.threadId,
			@"message_id": detailId,
			@"ts_created": [[self timestamp] strftime],
		},
	}];
}

@end
