#import "ChatElement.h"
#import "ChatElementContext.h"
#import "ChatElementMomentComponent.h"

#import "RingKit.h"
#import "UIColor+Hex.h"
#import "UIImage+Scale.h"

@implementation ChatElementMomentComponent

+ (instancetype)newWithChatElement:(ChatElement *)elem context:(ChatElementContext *)context
{
	NSDictionary* data = elem.data;
	CKComponentScope scope(self, data[@"uuid"]);
	CGFloat width = [[UIScreen mainScreen] bounds].size.width;
	
	CKComponent* res;
	
	UIImage* image = [context imageNamed:@"message_summary_moment_normal.png"];

	res = [CKStackLayoutComponent newWithView:{} size:{
		.width = width,
	} style: {
		.direction = CKStackLayoutDirectionVertical,
		.alignItems = CKStackLayoutAlignItemsStart,
	} children:{
		{[CKComponent newWithView:{
            [UIView class],
            {
                {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#D1D1D1"]},
            }
        } size:{.width = width, .height = 1 / [UIScreen mainScreen].scale}]},
		{[CKBackgroundLayoutComponent newWithComponent:
			[CKCompositeComponent newWithView:{
				[UIView class],
				{
					{CKComponentTapGestureAttribute(@selector(didTapMoment))},
				}
			} component:
                [CKStackLayoutComponent newWithView:{} size:{
                	.width = width,
                } style: {
                	.direction = CKStackLayoutDirectionHorizontal,
                	.alignItems = CKStackLayoutAlignItemsStretch,
                } children:{
                	{
                		.component = [CKComponent new],
                		.flexGrow = @YES,
                	},
                	{[CKInsetComponent newWithInsets:{.top = 20, .left = 0, .bottom = 20, .right = 0} component:
                		[CKImageComponent newWithImage:image]
                	]},
                	{
                		.component = [CKComponent new],
                		.flexGrow = @YES,
                	}
                }]
			]
		background:
			[CKComponent newWithView:{
                [UIView class],
                {
                    {@selector(setBackgroundColor:), [UIColor colorWithWhite:1.0f alpha:0.5f]},
                }
			} size:{}]
		]},
		{[CKComponent newWithView:{
            [UIView class],
            {
                {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#D1D1D1"]},
            }
        } size:{.width = width, .height = 1 / [UIScreen mainScreen].scale}]},
	}];
	
	res = [CKInsetComponent newWithInsets:{.top = 10, .left = 0, .bottom = 10, .right = 0} component:res];

	if (data[@"first_element"])
	{
		res = [CKInsetComponent newWithInsets:{.top = 20, .bottom = 0, .left = 0, .right = 0} component:res];
	}
	if (data[@"last_element"])
	{
		res = [CKInsetComponent newWithInsets:{.top = 0, .bottom = 20, .left = 0, .right = 0} component:res];
	}
	ChatElementMomentComponent* c = [super newWithComponent:res];
	if (c)
	{
		c->_element = elem;
	}
	return c;
}

- (void)didTapMoment
{
	[self.element showMomentMedia];
}

@end
