#import "Send.h"

#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "RgManager.h"
#import "ChatRoomViewController.h"
#import "PhotoCameraViewController.h"
#import "VideoCameraViewController.h"
#import "MomentCameraViewController.h"

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
		NSDictionary *sessionData = [mgr dbGetSessionID:to to:nil contact:nil uuid:nil];
		[[LinphoneManager instance] setChatSession:sessionData[@"id"]];
		[[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE];
	}
}

- (void)showPhotoCamera
{
	[[PhoneMainView instance] changeCurrentView:[PhotoCameraViewController compositeViewDescription] push:TRUE];
}

- (void)showVideoCamera
{
	[[PhoneMainView instance] changeCurrentView:[VideoCameraViewController compositeViewDescription] push:TRUE];
}

- (void)showMomentCamera
{
	[[PhoneMainView instance] changeCurrentView:[MomentCameraViewController compositeViewDescription] push:TRUE];
}

@end
