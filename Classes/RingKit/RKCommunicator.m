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
#import "RKContact.h"
#import "RKMessage.h"
#import "RKThread.h"

@implementation RKCommunicator

@synthesize adapterXMPP;
@synthesize currentThread;
@synthesize viewDelegate;

+ (instancetype)sharedInstance
{
    static RKCommunicator *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RKCommunicator alloc] init];
		sharedInstance.adapterXMPP = [[RKAdapterXMPP alloc] init];
		sharedInstance.currentThread = nil;
    });
    return sharedInstance;
}

- (void)sendMessage:(RKMessage*)message
{
	RKThreadStore* store = [RKThreadStore sharedInstance];
	[store insertItem:message];
	// TODO: Deliver message
	// TODO: Notify observers
}

- (void)didReceiveMessage:(RKMessage*)message
{
	RKThreadStore* store = [RKThreadStore sharedInstance];
	[store insertItem:message];
	// TODO: Notify observers
}

- (NSArray*)listThreads
{
	return [[RKThreadStore sharedInstance] listThreads];
}

- (NSArray*)listThreadItems:(RKThread*)thread;
{
	return [[RKThreadStore sharedInstance] listThreadItems:thread];
}

- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress orignalTo:(RKAddress*)origTo contactId:(NSNumber*)ctid uuid:(NSString*)uuid;
{
	return [[RKThreadStore sharedInstance] getThreadByAddress:remoteAddress orignalTo:origTo contactId:ctid uuid:uuid];
}

- (void)startMessageView:(RKThread*)thread
{
	[self setCurrentThread:thread];
	if (self.viewDelegate && [self.viewDelegate respondsToSelector:@selector(showMessageView)])
	{
		[self.viewDelegate showMessageView];
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

@end
