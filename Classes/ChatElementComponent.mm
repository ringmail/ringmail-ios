#import "ChatElement.h"
#import "ChatElementContext.h"
#import "ChatElementComponent.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"

@implementation ChatElementComponent

+ (instancetype)newWithChatElement:(ChatElement *)elem context:(ChatElementContext *)context
{
	CKComponentScope scope(self, elem.data[@"uuid"]);
	CGFloat width = [[UIScreen mainScreen] bounds].size.width;
	ChatElementComponent* c = [super newWithComponent:
		[CKInsetComponent newWithInsets:{.top = 2, .left = 0, .bottom = 2, .right = 0} component:
			[CKLabelComponent newWithLabelAttributes:{
				.string = elem.data[@"body"],
				.font = [UIFont systemFontOfSize:12],
				.alignment = NSTextAlignmentLeft,
			}
			viewAttributes:{
				{@selector(setBackgroundColor:), [UIColor clearColor]},
				{@selector(setUserInteractionEnabled:), @NO},
			}
			size:{.width = width}]
		]
	];
	if (c)
	{
		c->_element = elem;
	}
	return c;
}

@end
