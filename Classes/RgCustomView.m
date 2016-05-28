//
//  RgCustomView.m
//  ringmail
//
//  Created by Mike Frager on 4/1/16.
//
//

#import "RgCustomView.h"
#import "UIImage+Filtering.h"
#import "UIColor+Name.h"

@implementation RgCustomView

- (void)setupView:(NSDictionary*)args
{
	UIImage *pattern = [UIImage imageNamed:[NSString stringWithFormat:@"pattern_%@.png", args[@"pattern"]]];
	pattern = [pattern grayscale];
	pattern = [self overlayImage:pattern withColor:[UIColor colour:args[@"color"]]];
	[self setBackgroundColor:[UIColor colorWithPatternImage:pattern]];
}

// From: http://stackoverflow.com/questions/845278/overlaying-a-uiimage-with-a-color

- (UIImage *)overlayImage:(UIImage *)source withColor:(UIColor *)color{

    // begin a new image context, to draw our colored image onto with the right scale
    UIGraphicsBeginImageContextWithOptions(source.size, NO, [UIScreen mainScreen].scale);

    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();

    // set the fill color
    [color setFill];

    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, source.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGRect rect = CGRectMake(0, 0, source.size.width, source.size.height);
    CGContextDrawImage(context, rect, source.CGImage);

    CGContextSetBlendMode(context, kCGBlendModeColor);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context, kCGPathFill);

    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //return the color-burned image
    return coloredImg;
}

@end
