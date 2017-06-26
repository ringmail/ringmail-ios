#import "ChatElement.h"

#import "VideoViewController.h"
#import "PhoneMainView.h"

@implementation ChatElement

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
        VideoViewController *vc = [[VideoViewController alloc] initWithVideoUrl:fileUrl];
        [[PhoneMainView instance] changeCurrentView:[VideoViewController compositeViewDescription] content:vc push:YES];
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
