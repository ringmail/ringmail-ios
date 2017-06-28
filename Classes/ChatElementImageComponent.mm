#import "ChatElement.h"
#import "ChatElementContext.h"
#import "ChatElementImageComponent.h"

#import "RingKit.h"
#import "UIColor+Hex.h"
#import "UIImage+Scale.h"

@implementation ChatElementImageComponent

+ (instancetype)newWithChatElement:(ChatElement *)elem context:(ChatElementContext *)context
{
	NSDictionary* data = elem.data;
	CKComponentScope scope(self, data[@"uuid"]);
	CGFloat width = [[UIScreen mainScreen] bounds].size.width;
	CGFloat scale = [UIScreen mainScreen].scale;
	
	int maxBubbleWidth = (int)((width - (12 * scale)) / 3) * 2;
	//int maxBubbleHeight = (int)(maxBubbleWidth * 0.5862);
	int maxBubbleHeight = (int)(maxBubbleWidth * 1.2);
	
	CKComponent* res;
	
	//UIImage* mainImage = [context getImageByID:data[@"id"] key:@"msg_data" size:CGSizeMake(maxBubbleWidth, maxBubbleHeight)];
	RKPhotoMessage* message = data[@"item"];
	//NSLog(@"Chat Image Component - Message: %@", message);
	if (message.mediaData == nil)
	{
		message.mediaData = [NSData dataWithContentsOfURL:[message documentURL]];
	}
	UIImage* image = [UIImage imageWithData:message.mediaData];
	CGSize maxSize = CGSizeMake(maxBubbleWidth, maxBubbleHeight);
	if (image.size.height > maxSize.height || image.size.width > maxSize.width)
	{
		image = [image scaleImageToSize:maxSize];
	}

	if (message.direction == RKItemDirectionInbound)
	{
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
					{[CKCompositeComponent newWithView:{
						[UIView class],
						{
    						{CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), @15.0},
                            {@selector(setClipsToBounds:), @YES},
							{CKComponentTapGestureAttribute(@selector(didTapImage))},
						}
					} component:
						[CKImageComponent newWithImage:image]
					]}
        		}]
    		]}
		}];
	}
	else
	{
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
					{[CKCompositeComponent newWithView:{
						[UIView class],
						{
    						{CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), @15.0},
                            {@selector(setClipsToBounds:), @YES},
							{CKComponentTapGestureAttribute(@selector(didTapImage))},
						}
					} component:
						[CKImageComponent newWithImage:image]
					]}
        		}]
    		]}
		}];
		
		// Message status
		if (data[@"last_element"])
		{
			NSString* status = _RKMessageStatus(message.deliveryStatus);
			res = [CKStackLayoutComponent newWithView:{} size:{
    			.width = width,
    		} style: {
    			.direction = CKStackLayoutDirectionVertical,
    			.alignItems = CKStackLayoutAlignItemsStart,
    		} children:{
				{res},
				{[CKInsetComponent newWithInsets:{.top = 2, .bottom = 0, .left = 0, .right = 18} component:
					[CKStackLayoutComponent newWithView:{} size:{
        				.width = width,
        			} style: {
        				.direction = CKStackLayoutDirectionHorizontal,
        				.alignItems = CKStackLayoutAlignItemsStretch,
        			} children:{
    					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
						{[CKLabelComponent newWithLabelAttributes:{
                            .string = status,
                            .font = [UIFont systemFontOfSize:10.0f],
                            .color = [UIColor colorWithHex:@"#222222"],
							.alignment = NSTextAlignmentRight,
                            .maximumNumberOfLines = 1
                        }
                        viewAttributes:{
                            {@selector(setBackgroundColor:), [UIColor clearColor]},
                            {@selector(setUserInteractionEnabled:), @NO},
                        } size:{}]}
					}]
				]}
    		}];
		}
	}
	if (data[@"first_element"])
	{
		res = [CKInsetComponent newWithInsets:{.top = 20, .bottom = 0, .left = 0, .right = 0} component:res];
	}
	if (data[@"last_element"])
	{
		res = [CKInsetComponent newWithInsets:{.top = 0, .bottom = 20, .left = 0, .right = 0} component:res];
	}
	ChatElementImageComponent* c = [super newWithComponent:res];
	if (c)
	{
		c->_element = elem;
	}
	return c;
}

- (void)didTapImage
{
	[self.element showImageMedia];
}

@end
