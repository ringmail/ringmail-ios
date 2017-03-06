#import <objc/runtime.h>
#import <ComponentKit/ComponentKit.h>

#import "Send.h"
#import "SendContext.h"
#import "SendComponent.h"
#import "SendComponentController.h"
#import "SendCardComponent.h"
#import "SendViewController.h"
#import "TextInputComponent.h"
#import "SendToInputComponent.h"
#import "FavoritesBarComponent.h"

#import "UIColor+Hex.h"

@implementation SendComponent

+ (id)initialState
{
	return [NSMutableDictionary dictionaryWithDictionary:@{
		@"enable_send": @NO,
	}];
}

+ (instancetype)newWithSend:(Send *)send context:(SendContext *)context
{
	NSLog(@"Send Data: %@", [send data]);
	CKComponentScope scope(self);
	CGFloat width = [[UIScreen mainScreen] bounds].size.width;
	
	NSMutableDictionary* currentState = scope.state();
	NSString *sendButtonImageName;
	if ([currentState[@"enable_send"] boolValue])
	{
		sendButtonImageName = @"arrow_pressed.png";
	}
	else
	{
		sendButtonImageName = @"arrow_normal.png";
	}
	NSLog(@"State: %@", currentState);
    SendComponent *c = [super newWithView:{} component:
		[CKInsetComponent newWithInsets:{.top = 12, .bottom = 0, .left = 0, .right = 0} component:
			[CKStackLayoutComponent newWithView:{} size:{} style:{
				.direction = CKStackLayoutDirectionVertical,
				.alignItems = CKStackLayoutAlignItemsStart,
			}
			children:{
				// Message composer
				{[SendCardComponent newWithSend:send context:context]},
				// Action bar
				{[CKInsetComponent newWithInsets:{.top = 17, .bottom = 22, .left = 20, .right = 20} component:
					[CKStackLayoutComponent newWithView:{
						[UIView class],
						{
							{@selector(setBackgroundColor:), [UIColor clearColor]},
						}
					} size:{.height = 47, .width = width - 40} style:{
					   .direction = CKStackLayoutDirectionHorizontal,
					   .alignItems = CKStackLayoutAlignItemsStretch
					}
					children:{
						{[CKImageComponent newWithImage:[UIImage imageNamed:@"ringpanel_button1_camera.png"]]},
						{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
						{[CKImageComponent newWithImage:[UIImage imageNamed:@"ringpanel_button2_video.png"]]},
						{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
						{[CKImageComponent newWithImage:[UIImage imageNamed:@"ringpanel_button3_moments.png"]]},
					}]
				]},
				// Favorites
				{[CKStackLayoutComponent newWithView:{} size:{.width = width} style:{
					.direction = CKStackLayoutDirectionVertical,
					.alignItems = CKStackLayoutAlignItemsStart,
				}
				children:{
					{[CKComponent newWithView:{
						[UIView class],
						{
							{@selector(setBackgroundColor:), [UIColor colorWithHex:@"#D1D1D1"]},
						}
					} size:{.height = 1 / [UIScreen mainScreen].scale, .width = width}]},
					{[CKBackgroundLayoutComponent newWithComponent:
						[CKInsetComponent newWithInsets:{.top = 0, .bottom = 0, .left = 20, .right = 0} component:
							[CKCenterLayoutComponent newWithCenteringOptions:CKCenterLayoutComponentCenteringY sizingOptions:CKCenterLayoutComponentSizingOptionDefault child:
								[CKLabelComponent newWithLabelAttributes:{
									.string = @"Favorites",
									.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold],
									.alignment = NSTextAlignmentLeft,
								}
								viewAttributes:{
									{@selector(setBackgroundColor:), [UIColor clearColor]},
									{@selector(setUserInteractionEnabled:), @NO},
								}
								size:{.width = width - 20}]
							size:{.width = width - 20, .height = 27}]
						]
					background:
						[CKImageComponent newWithImage:[UIImage imageNamed:@"background_favorites.png"]]
					]},
					{[CKComponent newWithView:{
						[UIView class],
						{
							{@selector(setBackgroundColor:), [UIColor colorWithHex:@"#D1D1D1"]},
						}
					} size:{.height = 1 / [UIScreen mainScreen].scale, .width = width}]},
					{[FavoritesBarComponent newWithSize:{.height = 76, .width = width}]},
				}]},
				// Media library
				{
					.flexGrow = YES,
					.component = [CKStackLayoutComponent newWithView:{} size:{.width = width} style:{
						.direction = CKStackLayoutDirectionVertical,
						.alignItems = CKStackLayoutAlignItemsStart,
					}
					children:{
						{[CKInsetComponent newWithInsets:{.top = 12, .bottom = 10, .left = 0, .right = 0} component:
							[CKLabelComponent newWithLabelAttributes:{
								.string = @"LIBRARY",
								.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold],
								.alignment = NSTextAlignmentCenter,
							}
							viewAttributes:{
								{@selector(setBackgroundColor:), [UIColor clearColor]},
								{@selector(setUserInteractionEnabled:), @NO},
							}
							size:{.height = 15, .width = width}]
						]},
						{[CKComponent newWithView:{
							[UIView class],
							{
								{@selector(setBackgroundColor:), [UIColor colorWithHex:@"#CCCCCC"]},
							}
						} size:{.height = 71, .width = width}]},
						{[CKInsetComponent newWithInsets:{.top = 5, .bottom = 0, .left = 0, .right = 0} component:
							[CKLabelComponent newWithLabelAttributes:{
								.string = @"10 Photos, 5 Videos",
								.font = [UIFont systemFontOfSize:9],
								.alignment = NSTextAlignmentCenter,
							}
							viewAttributes:{
								{@selector(setBackgroundColor:), [UIColor clearColor]},
								{@selector(setUserInteractionEnabled:), @NO},
							}
							size:{.width = width}]
						]},
					}]
				},
			}]
		]
	];

    return c;
}

@end
