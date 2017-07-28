#import "ChatElement.h"

#import "VideoPlayerViewController.h"
#import "PhoneMainView.h"
#import "RgViewDelegate.h"
#import "NSString_RemoveEmoji-Swift.h"

@implementation ChatElement

+ (BOOL)showingMessageThread
{
	return [[RgViewDelegate sharedInstance] showingMessageThread];
}

+ (BOOL)isAllEmojis:(NSString*)str
{
	if ([str length] > 0)
	{
		if ([str containsEmoji])
		{
			NSString *trim = [str stringByRemovingEmoji];
			if ([trim length] == 0)
			{
				return YES;
			}
		}
	}
	return NO;
}

- (instancetype)initWithData:(NSDictionary *)data
{
	if (self = [super init])
	{
		_data = [data copy];
	}
	return self;
}

- (void)showVideoMedia
{
	RKVideoMessage* media = self.data[@"item"];
	if ([media.mediaType isEqualToString:@"video/mp4"])
	{
		NSURL* fileUrl = [media documentURL];
        VideoPlayerViewController *vc = [[VideoPlayerViewController alloc] initWithVideoUrl:fileUrl];
        [[PhoneMainView instance] changeCurrentView:[VideoPlayerViewController compositeViewDescription] content:vc push:YES];
	}
}

- (void)showImageMedia
{
	RKPhotoMessage* media = self.data[@"item"];
	if (
		[media.mediaType isEqualToString:@"image/png"] ||
		[media.mediaType isEqualToString:@"image/jpg"] ||
		[media.mediaType isEqualToString:@"image/jpeg"]
	) {
    	if (media.mediaData == nil)
    	{
    		media.mediaData = [NSData dataWithContentsOfURL:[media documentURL]];
    	}	
		UIImage* image = [UIImage imageWithData:media.mediaData];
		[[RKCommunicator sharedInstance] startImageView:image parameters:@{}];
	}
}

- (void)showMomentMedia
{
	RKMomentMessage* mmsg = self.data[@"item"];
	[[RKCommunicator sharedInstance] startMomentView:mmsg];
}

@end
