//
//  RgModalButtonView.m
//  ringmail
//
//  Created by Mark Baxter on 5/4/17.
//
//

#import "RgModalButtonView.h"

@implementation RgModalButtonView


- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    
    CGContextSetLineWidth(context, 1.0f/[UIScreen mainScreen].scale);
    CGContextMoveToPoint(context, 0.0f, 0.0f);
    CGContextAddLineToPoint(context, rect.size.width, 0.0f);
    CGContextStrokePath(context);
}

@end
