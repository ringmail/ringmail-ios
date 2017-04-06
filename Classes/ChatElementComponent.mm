#import "ChatElement.h"
#import "ChatElementContext.h"
#import "ChatElementComponent.h"

#import "UIColor+Hex.h"

@implementation ChatElementComponent

+ (instancetype)newWithChatElement:(ChatElement *)elem context:(ChatElementContext *)context
{
	NSDictionary* data = elem.data;
	CKComponentScope scope(self, data[@"uuid"]);
	CGFloat width = [[UIScreen mainScreen] bounds].size.width;
	
	CGFloat scale = [UIScreen mainScreen].scale;
	
	int maxBubbleWidth = (int)((width - (12 * scale)) / 3) * 2;
	
	CKComponent* res;
	if ([data[@"direction"] isEqualToString:@"inbound"])
	{
	    NSDictionary *attrsDictionary = @{
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSForegroundColorAttributeName: [UIColor colorWithHex:@"#222222"],
        };
		NSString* msg = data[@"body"];
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:msg attributes:attrsDictionary];
		CGRect bounds = [msg boundingRectWithSize:CGSizeMake((maxBubbleWidth - 20), CGFLOAT_MAX)
			options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
			attributes:@{
				NSFontAttributeName: [UIFont systemFontOfSize:14],
			} context:nil];
		//NSLog(@"Bounds: %f %f", bounds.size.width, bounds.size.height);
		
		// Draw bubble
		CGSize size = CGSizeMake((int)bounds.size.width + 20, (int)bounds.size.height + 16 + 10);
		CGSize scaledSize = CGSizeMake((int)size.width * scale, (int)size.height * scale);
		
		CGSize boxSize = CGSizeMake((int)bounds.size.width + 20, (int)bounds.size.height + 16);
		CGSize boxScaledSize = CGSizeMake((int)boxSize.width * scale, (int)boxSize.height * scale);
		
        UIGraphicsBeginImageContext(scaledSize);
		CGContextRef context=UIGraphicsGetCurrentContext();
		
		// Main bubble
		UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, (int)10 * scale, boxScaledSize.width, boxScaledSize.height)
                                   byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerTopRight | UIRectCornerBottomRight)
                                         cornerRadii:CGSizeMake(15 * scale, 15 * scale)];
		CGContextSetFillColorWithColor(context, [UIColor colorWithHex:@"#E5E5EA"].CGColor);
		[bezierPath fill];
		
		// Top tail
		CGRect rectangle = CGRectMake(0, 0, (int)20 * scale, (int)10 * scale);
		CGContextFillRect(context, rectangle);
		UIBezierPath *tailPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(-1, (int)-20 * scale, 30 * scale, 30 * scale)
                                   byRoundingCorners:UIRectCornerBottomLeft
                                         cornerRadii:CGSizeMake(10 * scale, 10 * scale)];
		CGContextSetBlendMode(context, kCGBlendModeClear);
		CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
		[tailPath fill];
		
        UIImage *bubbleImage=UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
		
		int msgHeight = (int)(bounds.size.height + 0.5);
		int msgWidth = (int)(bounds.size.width + 0.5);
		msgHeight += 1;
		
		res = [CKStackLayoutComponent newWithView:{} size:{
			.width = width,
		} style: {
			.direction = CKStackLayoutDirectionHorizontal,
			.alignItems = CKStackLayoutAlignItemsStart,
		} children:{
    		{[CKInsetComponent newWithInsets:{.top = 3, .left = 12, .bottom = 3, .right = (width - maxBubbleWidth) + 12} component:
    			[CKStackLayoutComponent newWithView:{} size:{
    				.width = maxBubbleWidth,
    			} style: {
    				.direction = CKStackLayoutDirectionHorizontal,
    				.alignItems = CKStackLayoutAlignItemsStart,
    			} children:{
					{[CKBackgroundLayoutComponent newWithComponent:
						[CKInsetComponent newWithInsets:{.top = 8, .left = 10, .bottom = 8, .right = 10} component:
    						[CKTextComponent newWithTextAttributes:{
                                .attributedString = attrString,
                                .lineBreakMode = NSLineBreakByWordWrapping,
                            } viewAttributes:{
                                {@selector(setBackgroundColor:), [UIColor clearColor]},
                                {@selector(setUserInteractionEnabled:), @NO},
                            } options:{} size:{.width = msgWidth, .height = msgHeight}]
						]	
					background:
						[CKInsetComponent newWithInsets:{.top = -10, .left = 0, .bottom = 0, .right = 0} component:
							[CKImageComponent newWithImage:bubbleImage size:{.height = size.height, .width = size.width}]
						]
					]},
        		}]
    		]}
		}];
	}
	else
	{
	    NSDictionary *attrsDictionary = @{
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSForegroundColorAttributeName: [UIColor colorWithHex:@"#FFFFFF"],
        };
		NSString* msg = data[@"body"];
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:msg attributes:attrsDictionary];
		CGRect bounds = [msg boundingRectWithSize:CGSizeMake((maxBubbleWidth - 20), CGFLOAT_MAX)
			options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
			attributes:@{
				NSFontAttributeName: [UIFont systemFontOfSize:14],
			} context:nil];
		//NSLog(@"Bounds: %f %f", bounds.size.width, bounds.size.height);
		
		// Draw bubble
		CGSize size = CGSizeMake((int)bounds.size.width + 20, (int)bounds.size.height + 16 + 10);
		CGSize scaledSize = CGSizeMake((int)size.width * scale, (int)size.height * scale);
		
		CGSize boxSize = CGSizeMake((int)bounds.size.width + 20, (int)bounds.size.height + 16);
		CGSize boxScaledSize = CGSizeMake((int)boxSize.width * scale, (int)boxSize.height * scale);
		
        UIGraphicsBeginImageContext(scaledSize);
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		// Background
		CGContextSetFillColorWithColor(context, [UIColor colorWithHex:@"#FFFFFF"].CGColor);
		CGRect bg = CGRectMake(0, 0, scaledSize.width, scaledSize.height);
		CGContextFillRect(context, bg);
		
		// Main bubble
		CGContextSetFillColorWithColor(context, [UIColor colorWithHex:@"#000000"].CGColor);
		UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, boxScaledSize.width, (int)boxScaledSize.height)
                                   byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerTopRight | UIRectCornerBottomLeft)
                                         cornerRadii:CGSizeMake(15 * scale, 15 * scale)];
		[bezierPath fill];
		
		// Bottom tail
		CGRect rectangle = CGRectMake((int)scaledSize.width - (20 * scale), (int)scaledSize.height - (10 * scale), (int)20 * scale, (int)10 * scale);
		CGContextFillRect(context, rectangle);
		UIBezierPath *tailPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake((int)(scaledSize.width - (30 * scale)) + 1, (int)scaledSize.height - (10 * scale), 30 * scale, 30 * scale)
                                   byRoundingCorners:UIRectCornerTopRight
                                         cornerRadii:CGSizeMake(10 * scale, 10 * scale)];
		//CGContextSetBlendMode(context, kCGBlendModeClear);
		CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
		[tailPath fill];
		
		UIImage *bubbleMask = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
		
		// Gradient
		UIGraphicsBeginImageContext(scaledSize);
		context = UIGraphicsGetCurrentContext();
		
		CGFloat locations[2] = { 0, 1.0 };
		NSArray *colors = @[
			(id)[UIColor colorWithHex:@"#3549AC"].CGColor,
			(id)[UIColor colorWithHex:@"#6B97FF"].CGColor,
		];

        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(colorspace,(CFArrayRef)colors, locations);

        CGPoint startPoint, endPoint;
        startPoint.x = scaledSize.width;
        startPoint.y = 0;

        endPoint.x = 0;
        endPoint.y = scaledSize.height;

        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

        CGGradientRelease(gradient);
        CGColorSpaceRelease(colorspace);
		
        UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
		
		// Apply masking
		
		CGImageRef maskRef = bubbleMask.CGImage;
		CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
    		CGImageGetHeight(maskRef),
    		CGImageGetBitsPerComponent(maskRef),
    		CGImageGetBitsPerPixel(maskRef),
    		CGImageGetBytesPerRow(maskRef),
    		CGImageGetDataProvider(maskRef), NULL, false);
    	CGImageRef masked = CGImageCreateWithMask([gradientImage CGImage], mask);
    	UIImage *bubbleImage = [UIImage imageWithCGImage:masked];
		
		int msgHeight = (int)(bounds.size.height + 0.5);
		int msgWidth = (int)(bounds.size.width + 0.5);
		msgHeight += 1;
		
		res = [CKStackLayoutComponent newWithView:{} size:{
			.width = width,
		} style: {
			.direction = CKStackLayoutDirectionHorizontal,
			.alignItems = CKStackLayoutAlignItemsStretch,
		} children:{
			{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
    		{[CKInsetComponent newWithInsets:{.top = 3, .right = 12, .bottom = 3, .left = 0} component:
    			[CKStackLayoutComponent newWithView:{} size:{
    				.width = maxBubbleWidth,
    			} style: {
    				.direction = CKStackLayoutDirectionHorizontal,
    				.alignItems = CKStackLayoutAlignItemsStretch,
    			} children:{
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
					{[CKBackgroundLayoutComponent newWithComponent:
						[CKInsetComponent newWithInsets:{.top = 8, .left = 10, .bottom = 8, .right = 10} component:
    						[CKTextComponent newWithTextAttributes:{
                                .attributedString = attrString,
                                .lineBreakMode = NSLineBreakByWordWrapping,
                            } viewAttributes:{
                                {@selector(setBackgroundColor:), [UIColor clearColor]},
                                {@selector(setUserInteractionEnabled:), @NO},
                            } options:{} size:{.width = msgWidth, .height = msgHeight}]
						]	
					background:
						[CKInsetComponent newWithInsets:{.top = 0, .left = 0, .bottom = -10, .right = 0} component:
							[CKImageComponent newWithImage:bubbleImage size:{.height = size.height, .width = size.width}]
						]
					]},
        		}]
    		]}
		}];
	}
	ChatElementComponent* c = [super newWithComponent:res];
	if (c)
	{
		c->_element = elem;
	}
	return c;
}

@end
