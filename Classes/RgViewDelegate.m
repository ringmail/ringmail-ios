//
//  RgViewDelegate.m
//  ringmail
//
//  Created by Mike Frager on 5/25/17.
//
//

#import "RgViewDelegate.h"
#import "PhoneMainView.h"
#import "ImageCountdownViewController.h"
#import "LNNotificationsUI.h"

@implementation RgViewDelegate

@synthesize lastThreadId;
@synthesize messageView;
@synthesize enableMessageNotify;

+ (instancetype)sharedInstance
{
    static RgViewDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RgViewDelegate alloc] init];
		[sharedInstance setLastThreadId:@0];
		sharedInstance.messageView = nil;
		sharedInstance.enableMessageNotify = NO;
		[sharedInstance registerForNotifications];
		[[RKCommunicator sharedInstance] setViewDelegate:sharedInstance];
    });
    return sharedInstance;
}

- (void)registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reset:) name:kRgReset object:nil];
}

- (void)reset:(NSNotification*)notif
{
	lastThreadId = @0;
	messageView = nil;
}

- (void)showMessageView:(RKThread*)thread
{
	MessageViewController* mv;
	if ([lastThreadId isEqualToNumber:thread.threadId])
	{
		mv = messageView;
	}
	else
	{
		lastThreadId = thread.threadId;
		mv = [[MessageViewController alloc] initWithThread:thread];
		messageView = mv;
	}
	[[PhoneMainView instance] changeCurrentView:[MessageViewController compositeViewDescription] content:mv push:TRUE];
}

- (void)showImageView:(UIImage*)image parameters:(NSDictionary*)params
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	NSLog(@"Show Image: %f, %f", image.size.height, image.size.width);
	ImageViewController* ivc = [[ImageViewController alloc] initWithImage:image];
	[[PhoneMainView instance] changeCurrentView:[ImageViewController compositeViewDescription] content:ivc push:TRUE];
	//ImageViewController* ivc = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ImageViewController compositeViewDescription] push:TRUE], ImageViewController);
	//[ivc setImage:image];
}

- (void)showMomentView:(UIImage*)image parameters:(NSDictionary*)params complete:(void(^)(void))complete
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	NSLog(@"Show Moment Image: %f, %f", image.size.height, image.size.width);
	ImageCountdownViewController* ivc = [[ImageCountdownViewController alloc] initWithImage:image complete:complete];
	[[PhoneMainView instance] changeCurrentView:[ImageCountdownViewController compositeViewDescription] content:ivc push:TRUE];
}

- (void)startCall:(RKAddress*)dest video:(BOOL)video
{
	NSLog(@"%s: Video:%d %@", __PRETTY_FUNCTION__, video, dest);
    NSString* displayName = dest.displayName;
	NSString* address = dest.address;
    if ([address rangeOfString:@"@"].location != NSNotFound)
    {
        address = [RgManager addressToSIP:address];
    }
	[[LinphoneManager instance] call:address contact:dest.contact.contactId displayName:displayName transfer:FALSE video:video];
}

- (void)showNewMessage:(RKMessage*)msg
{
	UICompositeViewDescription* top = [[PhoneMainView instance] topView];
	if (top != nil && ! [top equal:[MessageViewController compositeViewDescription]])
	{
		[self showMessageNotification:msg];
	}
}

- (void)enableMessageNotifications:(BOOL)show
{
   	dispatch_async(dispatch_get_main_queue(), ^{
		self.enableMessageNotify = show;
	});
}

- (void)showMessageNotification:(RKMessage*)msg
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
   	dispatch_async(dispatch_get_main_queue(), ^{
    	if (self.enableMessageNotify)
    	{
        	LNNotification* notification = [LNNotification notificationWithMessage:msg.body title:msg.thread.remoteAddress.displayName];
        	notification.defaultAction = [LNNotificationAction actionWithTitle:@"Default Action" handler:^(LNNotificationAction *action) {
        		[[RKCommunicator sharedInstance] startMessageView:msg.thread];
        	}];
        	[[LNNotificationCenter defaultCenter] clearAllPendingNotifications];
        	[[LNNotificationCenter defaultCenter] presentNotification:notification forApplicationIdentifier:@"message_event"];
    	}
   	});
}

- (BOOL)showingMessageThread
{
	UICompositeViewDescription* top = [[PhoneMainView instance] topView];
	if (top != nil && [top equal:[MessageViewController compositeViewDescription]])
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

@end
