#import "UIImage+Scale.h"

#undef TMP_MIN
#define TMP_MIN(a,b)	((a)>(b) ? (b) : (a))
#undef TMP_MAX
#define TMP_MAX(a,b)	((a)>(b) ? (a) : (b))

@implementation UIImage (scale)

/**
 * Scales an image to fit within a bounds with a size governed by
 * the passed size. Also keeps the aspect ratio.
 *
 * Switch MIN to MAX for aspect fill instead of fit.
 *
 * @param newSize the size of the bounds the image must fit within.
 * @return a new scaled image.
 */
- (UIImage *)scaleImageToSize:(CGSize)maxSize
{
    CGRect scaledImageRect = CGRectZero;

    CGFloat aspectWidth = maxSize.width / self.size.width;
    CGFloat aspectHeight = maxSize.height / self.size.height;
    CGFloat aspectRatio = TMP_MIN(aspectWidth, aspectHeight);

    scaledImageRect.size.width = self.size.width * aspectRatio;
    scaledImageRect.size.height = self.size.height * aspectRatio;
    scaledImageRect.origin.x = 0;
    scaledImageRect.origin.y = 0;

    UIGraphicsBeginImageContextWithOptions( scaledImageRect.size, NO, 0 );
    [self drawInRect:scaledImageRect];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return scaledImage;
}

@end
