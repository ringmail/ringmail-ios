//
//  ThumbnailFactory.m
//  ringmail
//
//  Created by Mike Frager on 6/8/17.
//
//

#import "ThumbnailFactory.h"

@implementation ThumbnailFactory

+ (UIImage*)thumbnailForVideoAsset:(AVAsset*)asset size:(CGSize)size
{
    AVAssetImageGenerator *generateImg = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    NSError *thumbError = NULL;
    CMTime time = CMTimeMake(1, 1);
    CGImageRef refImg = [generateImg copyCGImageAtTime:time actualTime:NULL error:&thumbError];
	CGFloat scale = [UIScreen mainScreen].scale;
	UIImage* thumb = [UIImage imageWithCGImage:refImg scale:scale orientation:UIImageOrientationRight];
	thumb = [ThumbnailFactory thumbnailForImage:thumb size:CGSizeMake(90 * scale, 90 * scale)];
	return thumb;
}

+ (UIImage*)thumbnailForImage:(UIImage*)inputImg size:(CGSize)size
{
    CGFloat scale = size.width/inputImg.size.width;
    if ((size.height/inputImg.size.height) > scale)
	{
		scale = size.height/inputImg.size.height;
	}
    CGFloat width = inputImg.size.width * scale;
    CGFloat height = inputImg.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [inputImg drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}

@end
