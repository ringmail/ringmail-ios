//
//  RKCommunicator.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKCommunicator.h"
#import "RKThreadStore.h"
#import "RKAdapterXMPP.h"
#import "RKAddress.h"
#import "RKContact.h"
#import "RKCall.h"
#import "RKMessage.h"
#import "RKMomentMessage.h"
#import "RKThread.h"

#import "NSXMLElement+XMPP.h"
#import "RegexKitLite/RegexKitLite.h"

NSString *const kRKItemActivity = @"RKItemActivity";
NSString *const kRKMessageSent = @"RKMessageSent";
NSString *const kRKMessageReceived = @"RKMessageReceived";
NSString *const kRKMessageUpdated = @"RKMessageUpdated";
NSString *const kRKMessageRemoved = @"RKMessageRemoved";
NSString *const kRKCallBegin = @"RKCallBegin";
NSString *const kRKCallUpdated = @"RKCallUpdated";
NSString *const kRKCallEnd = @"RKCallEnd";
NSString *const kRKThreadSeen = @"RKThreadSeen";

@implementation RKCommunicator

@synthesize adapterXMPP;
@synthesize viewDelegate;

+ (instancetype)sharedInstance
{
    static RKCommunicator *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RKCommunicator alloc] init];
		sharedInstance.adapterXMPP = [[RKAdapterXMPP alloc] init];
    });
    return sharedInstance;
}

- (void)sendMessage:(RKMessage*)message
{
	if (! [message isKindOfClass:[RKMomentMessage class]]) // Do not store moments
	{
		RKThreadStore* store = [RKThreadStore sharedInstance];
		[store insertItem:message];
	}
	[message prepareMessage:^(NSObject* xml) {
		[adapterXMPP sendMessage:(NSXMLElement*)xml];
		[[NSNotificationCenter defaultCenter] postNotificationName:kRKItemActivity object:self userInfo:@{
			@"type": @"message",
			@"message": message,
			@"name": kRKMessageSent,
		}];
		[[NSNotificationCenter defaultCenter] postNotificationName:kRKMessageSent object:self userInfo:@{
			@"message": message,
		}];
	}];
}

- (void)didReceiveMessage:(RKMessage*)message
{
	RKThreadStore* store = [RKThreadStore sharedInstance];
	[store insertItem:message];
	if (self.viewDelegate && [self.viewDelegate respondsToSelector:@selector(showNewMessage:)])
	{
		[self.viewDelegate showNewMessage:message];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKItemActivity object:self userInfo:@{
		@"type": @"message",
		@"message": message,
		@"name": kRKMessageReceived,
	}];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKMessageReceived object:self userInfo:@{
		@"message": message,
	}];
}

- (void)didUpdateMessage:(RKMessage*)message
{
	RKThreadStore* store = [RKThreadStore sharedInstance];
	[store updateItem:message];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKItemActivity object:self userInfo:@{
		@"type": @"message",
		@"message": message,
		@"name": kRKMessageUpdated,
	}];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKMessageUpdated object:self userInfo:@{
		@"message": message,
	}];
}

- (void)startCall:(RKAddress*)dest video:(BOOL)video
{
	if (self.viewDelegate && [self.viewDelegate respondsToSelector:@selector(startCall:video:)])
	{
		[self.viewDelegate startCall:dest video:video];
	}
}

- (void)didBeginCall:(RKCall*)call
{
	RKThreadStore* store = [RKThreadStore sharedInstance];
	[store insertItem:call];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKItemActivity object:self userInfo:@{
		@"type": @"call",
		@"call": call,
		@"name": kRKCallBegin,
	}];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKCallBegin object:self userInfo:@{
		@"call": call,
	}];
}

- (void)didUpdateCall:(RKCall*)call
{
	RKThreadStore* store = [RKThreadStore sharedInstance];
	[store updateItem:call];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKItemActivity object:self userInfo:@{
		@"type": @"call",
		@"call": call,
		@"name": kRKCallUpdated,
	}];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKCallUpdated object:self userInfo:@{
		@"call": call,
	}];
}

- (void)didEndCall:(RKCall*)call
{
	RKThreadStore* store = [RKThreadStore sharedInstance];
	[store updateItem:call];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKItemActivity object:self userInfo:@{
		@"type": @"call",
		@"call": call,
		@"name": kRKCallEnd,
	}];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKCallEnd object:self userInfo:@{
		@"call": call,
	}];
}

- (NSArray*)listThreads
{
	return [[RKThreadStore sharedInstance] listThreads];
}

- (NSArray*)listThreadItems:(RKThread*)thread;
{
	return [[RKThreadStore sharedInstance] listThreadItems:thread];
}

- (NSArray*)listThreadItems:(RKThread*)thread lastItemId:(NSNumber*)lastItemId seen:(BOOL)seen
{
	return [[RKThreadStore sharedInstance] listThreadItems:thread lastItemId:lastItemId seen:seen];
}

- (RKThread*)getThreadById:(NSNumber*)lookupId
{
	return [[RKThreadStore sharedInstance] getThreadById:lookupId];
}

- (RKThread*)getThreadByMD5:(NSString*)lookupHash
{
	return [[RKThreadStore sharedInstance] getThreadByMD5:lookupHash];
}

- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress;
{
	RKContact* contact = [RKContact newByMatchingAddress:remoteAddress];
	return [[RKThreadStore sharedInstance] getThreadByAddress:remoteAddress orignalTo:nil contactId:contact.contactId uuid:nil];
}

- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress orignalTo:(RKAddress*)origTo contactId:(NSNumber*)ctid uuid:(NSString*)uuid;
{
	return [[RKThreadStore sharedInstance] getThreadByAddress:remoteAddress orignalTo:origTo contactId:ctid uuid:uuid];
}

- (RKCall*)getCallBySipId:(NSString*)sip
{
	return [[RKThreadStore sharedInstance] getCallBySipId:sip];
}

- (RKMessage*)getMessageByUUID:(NSString*)inputUUID;
{
	return [[RKThreadStore sharedInstance] getMessageByUUID:inputUUID];
}

- (void)startMessageView:(RKThread*)thread
{
	if (self.viewDelegate && [self.viewDelegate respondsToSelector:@selector(showMessageView:)])
	{
		[self.viewDelegate showMessageView:thread];
	}
}

- (void)startMomentView:(RKMomentMessage*)message
{
	message.mediaData = [NSData dataWithContentsOfURL:[message documentURL]];
	UIImage* image = [UIImage imageWithData:message.mediaData];
	if (self.viewDelegate && [self.viewDelegate respondsToSelector:@selector(showMomentView:parameters:complete:)])
	{
		[self.viewDelegate showMomentView:image parameters:@{} complete:^{
			[message onComplete];
		}];
	}
}

- (void)startContactView:(RKContact*)contact
{
	NSNumber* contactId = nil;
	contactId = contact.contactId;
	if (self.viewDelegate && [self.viewDelegate respondsToSelector:@selector(showContactView:)])
	{
		[self.viewDelegate showContactView:contactId];
	}
}

- (void)startHashtagView:(NSString*)hashtag
{
	if (self.viewDelegate && [self.viewDelegate respondsToSelector:@selector(showHashtagView:)])
	{
		[self.viewDelegate showHashtagView:hashtag];
	}
}

- (void)startImageView:(UIImage*)image parameters:(NSDictionary*)params
{
	if (self.viewDelegate && [self.viewDelegate respondsToSelector:@selector(showImageView:parameters:)])
	{
		[self.viewDelegate showImageView:image parameters:params];
	}
}

- (void)enableMessageNotifications:(BOOL)show
{
	if (self.viewDelegate && [self.viewDelegate respondsToSelector:@selector(enableMessageNotifications:)])
	{
		[self.viewDelegate enableMessageNotifications:show];
	}
}

@end
