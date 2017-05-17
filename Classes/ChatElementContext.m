#import "ChatElementContext.h"
#import "LinphoneManager.h"
#import "UIImage+Scale.h"

@implementation ChatElementContext

- (UIImage*)getImageByID:(NSNumber*)imageID key:(NSString*)key size:(CGSize)maxSize
{
    UIImage* image = nil;
    NSData* imageData = nil;
	if (key == nil)
	{
		key = @"msg_data";
	}
    imageData = [[[LinphoneManager instance] chatManager] dbGetMessageData:imageID key:key];
    if (imageData != nil)
    {
        image = [UIImage imageWithData:imageData];
		if (image.size.height > maxSize.height || image.size.width > maxSize.width)
		{
			image = [image scaleImageToSize:maxSize];
		}
	}
	return image;
}

@end
