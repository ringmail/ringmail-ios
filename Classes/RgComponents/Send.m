#import "Send.h"

#import "RingKit.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "RgManager.h"
#import "MessageViewController.h"
#import "PhotoCameraViewController.h"
#import "VideoCameraViewController.h"
#import "MomentCameraViewController.h"
#import "VideoViewController.h"
#import "PhoneMainView.h"

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
		RKCommunicator* comm = [RKCommunicator sharedInstance];
		RKAddress* address = [RKAddress newWithString:msgdata[@"to"]];
		RKThread* thread = [comm getThreadByAddress:address];
		if (self.data[@"send_media"] != nil)
		{
			NSDictionary* media = self.data[@"send_media"];
			__block NSString* file = media[@"file"];
			__block PHAsset* asset = media[@"asset"];
   			__block NSString *mediaType = media[@"mediaType"];
   			__block NSData *imgData = nil;
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				BOOL msg_image = NO;
				BOOL msg_video = NO;
    			if (file != nil)
    			{
					if ([mediaType isEqualToString:@"video/mp4"])
					{
						msg_video = YES;
					}
					else
					{
						msg_image = YES;
    					imgData = [NSData dataWithContentsOfFile:file];
					}
    			}
    			else if (asset != nil)
    			{
                	PHImageManager* imageManager = [PHImageManager defaultManager];
                	PHImageRequestOptions* opts = [PHImageRequestOptions new];
                	opts.resizeMode = PHImageRequestOptionsResizeModeExact;
                	opts.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
                	opts.synchronous = YES;
            		[imageManager requestImageDataForAsset:asset options:opts resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
    					imgData = imageData;
            		}];
					mediaType = @"image/png"; // TODO: customize
					msg_image = YES;
    			}
				if (msg_image)
				{
      				RKMediaMessage* pmsg;
					if (media[@"moment"] != nil)
					{
				        pmsg = [RKMomentMessage newWithData:@{
                			@"thread": thread,
                			@"direction": [NSNumber numberWithInteger:RKItemDirectionOutbound],
                			@"body": msgdata[@"message"],
                			@"deliveryStatus": @(RKMessageStatusSending),
            				@"mediaData": imgData,
            				@"mediaType": mediaType,
            			}];	
					}
					else
					{
        				pmsg = [RKPhotoMessage newWithData:@{
                			@"thread": thread,
                			@"direction": [NSNumber numberWithInteger:RKItemDirectionOutbound],
                			@"body": msgdata[@"message"],
                			@"deliveryStatus": @(RKMessageStatusSending),
            				@"mediaData": imgData,
            				@"mediaType": mediaType,
            			}];
					}
        			if (file != nil)
        			{
    				    if ([[NSFileManager defaultManager] copyItemAtPath:file toPath:[[pmsg documentURL] path] error:NULL] == NO)
                        {
    						NSAssert(FALSE, @"File copy failure");
                        }
                        else
                        {
                            [[NSFileManager defaultManager] removeItemAtPath:file error:NULL];
                        }
    				}
    				else if (asset != nil)
        			{
    					UIImage *img = [UIImage imageWithData:imgData];
    					NSData *pngData = UIImagePNGRepresentation(img);
    					[pngData writeToURL:[pmsg documentURL] atomically:YES];
    				}
        			NSLog(@"Photo Message: %@", pmsg);
					[comm sendMessage:pmsg];
				}
				else
				{
			    	RKVideoMessage* vmsg = [RKVideoMessage newWithData:@{
            			@"thread": thread,
            			@"direction": [NSNumber numberWithInteger:RKItemDirectionOutbound],
            			@"body": msgdata[@"message"],
            			@"deliveryStatus": @(RKMessageStatusSending),
        				@"localPath": media[@"localPath"],
        				@"mediaType": mediaType,
        			}];
        			NSLog(@"Video Message: %@", vmsg);
					[comm sendMessage:vmsg];
				}
			});
		}
		else
		{
			RKMessage* message = [RKMessage newWithData:@{
    			@"thread": thread,
    			@"direction": [NSNumber numberWithInteger:RKItemDirectionOutbound],
    			@"body": msgdata[@"message"],
       			@"deliveryStatus": @(RKMessageStatusSending),
    		}];
    		[comm sendMessage:message];
		}
   		[comm startMessageView:thread];
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

- (void)showVideoMedia
{
	NSDictionary* media = self.data[@"send_media"];
	if ([media[@"mediaType"] isEqualToString:@"video/mp4"])
	{
		NSURL* fileUrl = [NSURL fileURLWithPath:media[@"file"]];
        VideoViewController *vc = [[VideoViewController alloc] initWithVideoUrl:fileUrl];
        [[PhoneMainView instance] changeCurrentView:[VideoViewController compositeViewDescription] content:vc push:YES];
	}
}

@end
