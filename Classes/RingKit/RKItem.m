//
//  RKItem.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKThread.h"
#import "RKItem.h"
#import "RKCommunicator.h"

@implementation RKItem

@synthesize thread;
@synthesize itemId;
@synthesize uuid;
@synthesize timestamp;
@synthesize direction;
@synthesize version;

- (instancetype)initWithData:(NSDictionary*)param
{
	self = [super init];
	if (self)
	{
        if (param[@"thread"])
        {
            NSAssert([param[@"thread"] isKindOfClass:[RKThread class]], @"thread is not RKThread object");
            [self setThread:param[@"thread"]];
        }
		if (param[@"itemId"])
        {
            NSAssert([param[@"itemId"] isKindOfClass:[NSNumber class]], @"itemId is not NSNumber object");
            [self setItemId:param[@"itemId"]];
        }
		else
		{
			self->itemId = nil;
		}
		if (param[@"uuid"])
    	{
    		NSAssert([param[@"uuid"] isKindOfClass:[NSString class]], @"uuid is not NSString object");
    		[self setUuid:param[@"uuid"]];
    	}
    	else
    	{
    		[self setUuid:[[[NSUUID UUID] UUIDString] lowercaseString]];
    	}
		if (param[@"timestamp"])
    	{
    		NSAssert([param[@"timestamp"] isKindOfClass:[NSDate class]], @"timestamp is not NSDate object");
    		[self setTimestamp:param[@"timestamp"]];
    	}
    	else
    	{
    		[self setTimestamp:[NSDate date]];
    	}
		if (param[@"direction"])
		{
    		NSAssert([param[@"direction"] isKindOfClass:[NSNumber class]], @"direction is not NSNumber object");
			[self setDirection:[param[@"direction"] integerValue]];
		}
		else
		{
			[self setDirection:RKItemDirectionOutbound];
		}
		if (param[@"version"])
        {
            NSAssert([param[@"version"] isKindOfClass:[NSNumber class]], @"veresion is not NSNumber object");
            [self setVersion:param[@"version"]];
        }
		else
		{
			[self setVersion:@(1)];
		}
	}
	return self;
}

- (void)insertItem:(NoteDatabase*)ndb
{
    NSAssert(FALSE, @"Override this method: %s", __PRETTY_FUNCTION__);
}

- (void)updateItem:(NoteDatabase*)ndb
{
    NSAssert(FALSE, @"Override this method: %s", __PRETTY_FUNCTION__);
}

- (void)updateItem:(NoteDatabase*)ndb seen:(BOOL)seen
{
	[[ndb database] executeUpdate:@"UPDATE rk_thread_item SET seen = ? WHERE id = ?" withArgumentsInArray:@[@(seen), self.itemId]];
	if (self.thread)
	{
    	[[NSNotificationCenter defaultCenter] postNotificationName:kRKThreadSeen object:self userInfo:@{
       		@"thread": self.thread,
       	}];
	}
}

- (void)updateVersion:(NoteDatabase*)ndb
{
	[[ndb database] executeUpdate:@"UPDATE rk_thread_item SET version = version + 1 WHERE id = ?" withArgumentsInArray:@[self.itemId]];
}

@end
