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

@implementation RgViewDelegate

@synthesize lastThreadId;
@synthesize messageView;

+ (instancetype)sharedInstance
{
    static RgViewDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RgViewDelegate alloc] init];
		[sharedInstance setLastThreadId:@0];
		sharedInstance.messageView = nil;
		[[RKCommunicator sharedInstance] setViewDelegate:sharedInstance];
    });
    return sharedInstance;
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
	ImageViewController* ivc = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ImageViewController compositeViewDescription] push:TRUE], ImageViewController);
	[ivc setImage:image];
}

- (void)showMomentView:(UIImage*)image parameters:(NSDictionary*)params complete:(void(^)(void))complete
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	NSLog(@"Show Moment Image: %f, %f", image.size.height, image.size.width);
	ImageCountdownViewController* ivc = [[ImageCountdownViewController alloc] initWithImage:image complete:complete];
	[[PhoneMainView instance] changeCurrentView:[ImageCountdownViewController compositeViewDescription] content:ivc push:TRUE];
}

@end
