//
//  RgViewDelegate.m
//  ringmail
//
//  Created by Mike Frager on 5/25/17.
//
//

#import "RgViewDelegate.h"
#import "PhoneMainView.h"

@implementation RgViewDelegate

+ (instancetype)sharedInstance
{
    static RgViewDelegate *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RgViewDelegate alloc] init];
		[[RKCommunicator sharedInstance] setViewDelegate:sharedInstance];
    });
    return sharedInstance;
}

- (void)showMessageView
{
	[[PhoneMainView instance] changeCurrentView:[MessageViewController compositeViewDescription] push:TRUE];
}

- (void)showImageView:(UIImage*)image parameters:(NSDictionary*)params
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	NSLog(@"Image: %f, %f", image.size.height, image.size.width);
	ImageViewController* ivc = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ImageViewController compositeViewDescription] push:TRUE], ImageViewController);
	[ivc setImage:image];
}

@end
