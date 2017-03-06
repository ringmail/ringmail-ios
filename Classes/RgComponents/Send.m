#import "Send.h"

#import "LinphoneManager.h"
#import "RgManager.h"

@implementation Send

- (instancetype)initWithData:(NSDictionary *)data
{
	if (self = [super init])
	{
		_data = [data copy];
	}
	return self;
}

#pragma mark - Action Functions

- (void)sendMessage:(NSDictionary *)msgdata
{
	if ([msgdata[@"to"] length] > 0)
	{
		NSLog(@"sendMessage:%@", msgdata);
        RgChatManager* mgr = [[LinphoneManager instance] chatManager];
    	NSString* to = msgdata[@"to"];
    	NSString* body = msgdata[@"message"];
        NSString* uuid = [mgr sendMessageTo:to from:nil body:body contact:nil];
    	NSLog(@"Sent Message UUID: %@", uuid);
		
    	[[NSNotificationCenter defaultCenter] postNotificationName:@"kRgSendComponentReset" object:nil];
	}
}

@end
