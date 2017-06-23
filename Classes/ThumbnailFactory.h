//
//  VideoThumbnailFactory.h
//  ringmail
//
//  Created by Mike Frager on 6/8/17.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ThumbnailFactory : NSObject

+ (UIImage*)thumbnailForVideoAsset:(AVAsset*)asset size:(CGSize)size;
+ (UIImage*)thumbnailForImage:(UIImage*)inputImg size:(CGSize)size;

@end
