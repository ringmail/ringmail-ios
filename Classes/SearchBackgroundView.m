//
//  RgSearchBackgroundView.m
//  ringmail
//
//  Created by Mark Baxter on 2/6/17.
//
//

#import "RgSearchBackgroundView.h"


#define UIColorFromRGB(rgbValue) [UIColor \
    colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
    green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
    blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


@implementation RgSearchBackgroundView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
        NSLog(@"drawRect!");
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGGradientRef gradient;
        CGColorSpaceRef colorspace;
    
        // base colors
        // UIColor* c1 = UIColorFromRGB(0x927283);
        // UIColor* c2 = UIColorFromRGB(0xCAEAFF);
    
        //  pre-computed lighter colors
        UIColor* c1 = UIColorFromRGB(0xA58A99);
        UIColor* c2 = UIColorFromRGB(0xD3EEFF);
        
    //    CGRect rectangle = CGRectMake(0, 0, rect.size.width, 100);
    //    CGContextSetFillColorWithColor(context,c1.CGColor);
    //    CGContextFillRect(context, rectangle);
    
        CGFloat locations[2] = { 0, 0.89 };
        NSArray *colors = @[(id)c1.CGColor,
                            (id)c2.CGColor];
    
        colorspace = CGColorSpaceCreateDeviceRGB();
    
        gradient = CGGradientCreateWithColors(colorspace,(CFArrayRef)colors, locations);
    
        CGPoint startPoint, endPoint;
        startPoint.x = 0.0;
        startPoint.y = 0.0;
    
        endPoint.x = rect.size.width;
        endPoint.y = 0.0;
    
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorspace);
    

        UIColor* strokefillColor = UIColorFromRGB(0x222222);
        // create path
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, rect.size.height, 10.0);
        CGPathAddLineToPoint(path, NULL, rect.size.height, rect.size.height - 10.0);
        CGPathCloseSubpath(path);
        CGContextSetStrokeColor(context, CGColorGetComponents(strokefillColor.CGColor));
        CGContextSetFillColor(context, CGColorGetComponents(strokefillColor.CGColor));
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGContextSetLineWidth(context, 0.5f);
        CGContextSetShouldAntialias(context, NO);
        // draw path
        CGContextAddPath(context, path);
        CGContextDrawPath(context, kCGPathFillStroke);
    
        CGPathRelease(path);
}


@end
