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
	
	int maxBubbleWidth = (int)(((2 * width) / 3) + 0.5);
	maxBubbleWidth -= 24;
	
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
		NSLog(@"Bounds: %f %f", bounds.size.width, bounds.size.height);
		int msgHeight = (int)(bounds.size.height + 0.5);
		int msgWidth = (int)(bounds.size.width + 0.5);
		msgHeight += 1;
		
		res = [CKStackLayoutComponent newWithView:{} size:{
			.width = width,
		} style: {
			.direction = CKStackLayoutDirectionHorizontal,
			.alignItems = CKStackLayoutAlignItemsStart,
		} children:{
    		{[CKInsetComponent newWithInsets:{.top = 3, .left = 12, .bottom = 3, .right = width - (maxBubbleWidth + 12)} component:
    			[CKStackLayoutComponent newWithView:{} size:{
    				.width = maxBubbleWidth,
    			} style: {
    				.direction = CKStackLayoutDirectionHorizontal,
    				.alignItems = CKStackLayoutAlignItemsStart,
    			} children:{
    				{[CKCompositeComponent newWithView:{
    					[UIView class],
    					{
        					{@selector(setBackgroundColor:), [UIColor colorWithHex:@"#E5E5EA"]},
        					{CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), @15.0},
    						{@selector(setClipsToBounds:), @YES},
    					}
    				} component:
    					[CKInsetComponent newWithInsets:{.top = 8, .left = 10, .bottom = 8, .right = 10} component:
    						[CKTextComponent newWithTextAttributes:{
                                .attributedString = attrString,
                                .lineBreakMode = NSLineBreakByWordWrapping,
                            } viewAttributes:{
                                {@selector(setBackgroundColor:), [UIColor clearColor]},
                                {@selector(setUserInteractionEnabled:), @NO},
                            } options:{} size:{.width = msgWidth, .height = msgHeight}]
						]
    				]}
        		}]
    		]}
		}];
		NSLog(@"res: %@", res);
	}
	ChatElementComponent* c = [super newWithComponent:res];
	if (c)
	{
		c->_element = elem;
	}
	return c;
}

@end
