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
		if ([msgdata[@"message"] length] > 0)
		{
        	NSString* body = msgdata[@"message"];
            NSString* uuid = [mgr sendMessageTo:to from:nil body:body contact:nil];
        	NSLog(@"Sent Text Message UUID: %@", uuid);
		}
		if (self.data[@"send_media"] != nil)
		{
			__block NSString* file = self.data[@"send_file"];
			__block PHAsset* asset = self.data[@"send_asset"];
           	NSLog(@"Sending Image Message");
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    			__block UIImage *img;
    			if (file != nil)
    			{
    				img = [UIImage imageWithContentsOfFile:file];
    			}
    			else if (asset != nil)
    			{
                	PHImageManager* imageManager = [PHImageManager defaultManager];
                	PHImageRequestOptions* opts = [PHImageRequestOptions new];
                	opts.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                	opts.synchronous = YES;
            		[imageManager requestImageDataForAsset:asset options:opts resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
    					img = [UIImage imageWithData:imageData];
            		}];
    			}
                NSString* uuid = [mgr sendMessageTo:to from:nil image:img contact:nil];
            	NSLog(@"Sent Image Message UUID: %@", uuid);
			});
		}
    	[[NSNotificationCenter defaultCenter] postNotificationName:kRgSendComponentReset object:nil];
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
