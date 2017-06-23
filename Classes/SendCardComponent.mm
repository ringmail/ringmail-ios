#import <objc/runtime.h>
#import <ComponentKit/ComponentKit.h>

#import "Send.h"
#import "SendContext.h"
#import "SendCardComponent.h"
#import "SendCardComponentController.h"
#import "SendViewController.h"
#import "TextInputComponent.h"
#import "SendToInputComponent.h"
#import "FavoritesBarComponent.h"

#import "UIColor+Hex.h"

@implementation SendCardComponent

+ (id)initialState
{
	return [NSMutableDictionary dictionaryWithDictionary:@{
		@"enable_send": @NO,
	}];
}

+ (instancetype)newWithSend:(Send *)item context:(SendContext *)context
{
	CKComponentScope scope(self);
	NSMutableDictionary* currentState = scope.state();
	CGFloat width = [[UIScreen mainScreen] bounds].size.width;
	
	// There is a copy of this check in the component controller
	BOOL enable = NO;
	if ((item.data[@"send_media"] != nil) && ([currentState[@"to"] length] > 0))
	{
		enable = YES;
	}
	else if (([currentState[@"message"] length] > 0) && ([currentState[@"to"] length] > 0))
	{
		enable = YES;
	}
  	currentState[@"enable_send"] = [NSNumber numberWithBool:enable];
	
	NSString *sendButtonImageName;
	if ([currentState[@"enable_send"] boolValue])
	{
		sendButtonImageName = @"arrow_pressed.png";
	}
	else
	{
		sendButtonImageName = @"arrow_normal.png";
	}
	
	std::vector<CKStackLayoutComponentChild> sendContent;
	if ([item data][@"send_media"] != nil)
	{
		NSDictionary* media = [item data][@"send_media"];
		CKComponent* mediaItem;
		if ([media[@"mediaType"] isEqualToString:@"video/mp4"])
		{
			mediaItem = [CKCompositeComponent newWithView:{} component:
				[CKBackgroundLayoutComponent newWithComponent:
					[CKInsetComponent newWithInsets:{.top = 69, .bottom = 4, .left = 4, .right = 69} component:
						[CKImageComponent newWithImage:[UIImage imageNamed:@"ringpanel_video_badge.png"] size:{.height = 17, .width = 17}]
					]
				background:
					[CKButtonComponent newWithTitles:{} titleColors:{} images:{
        				{UIControlStateNormal, media[@"thumbnail"]},
        			} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionMediaTap:) size:{.height = 90, .width = 90} attributes:{} accessibilityConfiguration:{}]
				]
			];
		}
		else
		{
	 		mediaItem = [CKButtonComponent newWithTitles:{} titleColors:{} images:{
				{UIControlStateNormal, media[@"thumbnail"]},
			} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionImageTap:) size:{.height = 90, .width = 90} attributes:{} accessibilityConfiguration:{}];
		}
		sendContent.push_back(
			{[CKInsetComponent newWithInsets:{.top = 5, .bottom = 0, .left = 15, .right = 0} component:
				[CKCompositeComponent newWithView:{
                    [UIView class],
                    {
                        {CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), @10.0},
						{@selector(setClipsToBounds:), @YES},
                    }
				} component:
					[CKBackgroundLayoutComponent newWithComponent:
						[CKInsetComponent newWithInsets:{.top = 2, .bottom = 64, .left = 64, .right = 2} component:
							[CKButtonComponent newWithTitles:{} titleColors:{} images:{
								{UIControlStateNormal,[UIImage imageNamed:@"ringpanel_media_remove.png"]},
							} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionMediaRemove:) size:{.height = 26, .width = 26} attributes:{} accessibilityConfiguration:{}]
						]
					 background:mediaItem]
				]
			]}
		);
		sendContent.push_back(
			{[CKInsetComponent newWithInsets:{.top = 5, .bottom = 0, .left = 0, .right = 5} component:
				[TextInputComponent newWithTag:[NSNumber numberWithInt:1] size:{.height = 95, .width = width - 170}]
			]}
		);
	}
	else
	{
		sendContent.push_back(
			{[CKInsetComponent newWithInsets:{.top = 5, .bottom = 0, .left = 35, .right = 5} component:
				[TextInputComponent newWithTag:[NSNumber numberWithInt:1] size:{.height = 95, .width = width - 100}]
			]}
		);
	}
	
    SendCardComponent *c = [super newWithView:{} component:
		[CKInsetComponent newWithInsets:{.top = 0, .bottom = 0, .left = 10, .right = 10} component:
			[CKStackLayoutComponent newWithView:{
				[UIView class],
				{
					{@selector(setBackgroundColor:), [UIColor colorWithHex:@"#F7F7F7"]},
					{CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), @20.0},
					{@selector(setClipsToBounds:), @YES}
				}
			} size:{.width = width, .height = 150} style:{
			   .direction = CKStackLayoutDirectionVertical,
			   .alignItems = CKStackLayoutAlignItemsStretch
			}
			children:{
				{[CKStackLayoutComponent newWithView:{} size:{.height = 40} style:{
				   .direction = CKStackLayoutDirectionHorizontal,
				   .alignItems = CKStackLayoutAlignItemsStart
				}
				children:{
                    {[CKButtonComponent newWithTitles:{} titleColors:{} images:{
                        {UIControlStateNormal,[UIImage imageNamed:@"plus_icon_normal.png"]},
                    } backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionAddContact:) size:{.height = 40, .width = 40} attributes:{} accessibilityConfiguration:{}]},
					{[CKInsetComponent newWithInsets:{.top = 10, .bottom = 10, .left = 0, .right = 0} component:
						[CKLabelComponent newWithLabelAttributes:{
							.string = @"To:",
							.font = [UIFont systemFontOfSize:18],
							.alignment = NSTextAlignmentLeft,
						}
						viewAttributes:{
							{@selector(setBackgroundColor:), [UIColor clearColor]},
							{@selector(setUserInteractionEnabled:), @NO},
						}
						size:{.height = 20, .width = 30}]
					]},
					{[CKInsetComponent newWithInsets:{.top = 11, .bottom = 9, .left = 0, .right = 0} component:
						[SendToInputComponent newWithTag:[NSNumber numberWithInt:0] size:{.height = 20, .width = width - 100}]
					]}
				}]},
				{[CKStackLayoutComponent newWithView:{
					[UIView class],
					{
						{@selector(setBackgroundColor:), [UIColor colorWithHex:@"#EDF0F4"]},
						{@selector(setClipsToBounds:), @YES}
					}
				} size:{.height = 110} style:{
				   .direction = CKStackLayoutDirectionHorizontal,
				   .alignItems = CKStackLayoutAlignItemsStretch
				}
				children:{
					{[CKStackLayoutComponent newWithView:{} size:{.height = 110, .width = width - 80} style:{
    				   .direction = CKStackLayoutDirectionHorizontal,
    				   .alignItems = CKStackLayoutAlignItemsStart
    				} children:sendContent]},
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
					{[CKInsetComponent newWithInsets:{.top = 70, .bottom = 0, .left = 0, .right = 0} component:
						[CKButtonComponent newWithTitles:{} titleColors:{} images:{
							{UIControlStateNormal,[UIImage imageNamed:sendButtonImageName]},
						} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionSend:) size:{.height = 40, .width = 40} attributes:{} accessibilityConfiguration:{}]
					]},
				}]}
			}]
		]
	];
	if (c)
	{
		c->_send = item;
	}
    return c;
}

@end
