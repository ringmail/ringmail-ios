//
//  RKMessage.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKAddress.h"
#import "RKCall.h"
#import "RKThread.h"
#import "Utils.h"
#import "RgManager.h"

@implementation RKCall

@synthesize callId;
@synthesize sipId;
@synthesize callStatus;
@synthesize callResult;
@synthesize duration;
@synthesize video;

+ (instancetype)newWithData:(NSDictionary*)param
{
	return [[RKCall alloc] initWithData:param];
}

- (instancetype)initWithData:(NSDictionary*)param
{
	self = [super initWithData:param];
	if (self)
	{
		if (param[@"callId"])
        {
            NSAssert([param[@"callId"] isKindOfClass:[NSNumber class]], @"callId is not NSNumber object");
            [self setCallId:param[@"callId"]];
        }
		else
		{
			self->callId = nil;
		}
		if (param[@"sipId"])
    	{
    		NSAssert([param[@"sipId"] isKindOfClass:[NSString class]], @"sipId is not NSString object");
    		[self setSipId:param[@"sipId"]];
    	}
		else
		{
			self->sipId = nil;
		}
		if (param[@"callStatus"])
    	{
    		NSAssert([param[@"callStatus"] isKindOfClass:[NSString class]], @"callStatus is not NSString object");
    		[self setCallStatus:param[@"callStatus"]];
    	}
		else
		{
			self->callStatus = nil;
		}
		if (param[@"callResult"])
    	{
    		NSAssert([param[@"callResult"] isKindOfClass:[NSString class]], @"callResult is not NSString object");
    		[self setCallResult:param[@"callResult"]];
    	}
		else
		{
			self->callResult = nil;
		}
		if (param[@"duration"])
        {
            NSAssert([param[@"duration"] isKindOfClass:[NSNumber class]], @"duration is not NSNumber object");
            [self setDuration:param[@"duration"]];
        }
		else
		{
			self->duration = nil;
		}
		if (param[@"video"])
        {
            NSAssert([param[@"video"] isKindOfClass:[NSNumber class]], @"video is not NSNumber object");
            [self setVideo:param[@"video"]];
        }
		else
		{
			self->video = @NO;
		}
	}
	return self;
}

- (NSString*)description
{
	NSDictionary* input = @{
		@"itemId": NULLIFNIL(self.itemId),
		@"callId": NULLIFNIL(self.callId),
		@"version": self.version,
		@"thread": [NSString stringWithFormat:@"<RKThread: %p>", self.thread],
		@"uuid": self.uuid,
		@"inbound": [NSNumber numberWithInteger:self.direction],
		@"timestamp": self.timestamp,
		@"video": self.video,
		@"sipId": NULLIFNIL(self.sipId),
		@"callStatus": NULLIFNIL(self.callStatus),
		@"callResult": NULLIFNIL(self.callResult),
		@"duration": NULLIFNIL(self.duration),
	};
    NSMutableString *data = [[NSMutableString alloc] init];
    for (NSString *k in input.allKeys)
	{
        [data appendFormat:@" %@:%@", k, input[k]];
	}
	return [NSString stringWithFormat:@"<%s: %p {%@ }>", object_getClassName(self), self, data];
}

- (void)insertItem:(NoteDatabase*)ndb
{
	NSAssert(self.thread.threadId, @"thread id required");
	[ndb set:@{
		@"table": @"rk_call",
		@"insert": @{
			@"thread_id": self.thread.threadId,
			@"call_duration": [self duration],
			@"call_inbound": [NSNumber numberWithInteger:[self direction]],
			@"call_sip": [self sipId],
			@"call_status": [self callStatus],
			@"call_result": [self callResult],
			@"call_time": [[self timestamp] strftime],
			@"call_uuid": [self uuid],
		},
	}];
	NSNumber* detailId = [ndb lastInsertId];
	self.callId = detailId;
	[ndb set:@{
		@"table": @"rk_thread_item",
		@"insert": @{
			@"thread_id": self.thread.threadId,
			@"call_id": detailId,
			@"ts_created": [[self timestamp] strftime],
			@"seen": @YES,
		},
	}];
	self.itemId = [ndb lastInsertId];
}

- (void)updateItem:(NoteDatabase*)ndb
{
	NSAssert(self.callId, @"call id required");
	[ndb set:@{
		@"table": @"rk_call",
		@"update": @{
			@"call_duration": [self duration],
			@"call_status": [self callStatus],
			@"call_result": [self callResult],
		},
		@"where": @{
			@"id": [self callId],
		},
	}];
}

@end
