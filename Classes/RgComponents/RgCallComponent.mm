#import "RgCallComponent.h"

#import <objc/runtime.h>
#import <ComponentKit/ComponentKit.h>

#import "UIColor+Hex.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"

#import "RgCall.h"
#import "RgCallContext.h"
#import "RgCallDuration.h"
#import "RgCallViewController.h"

@implementation RgCallComponent

static RgCallDuration* globalDuration = nil;

+ (instancetype)newWithCall:(RgCall *)call context:(RgCallContext *)context
{
	CKComponentScope scope(self);
	if (! [call.data objectForKey:@"address"])
	{
		RgCallComponent *c = [super newWithView:{} component:[CKComponent newWithView:{} size:{}]];
		return c;
	}
    UIImage *avatarImage = [context imageNamed:[call.data objectForKey:@"address"]];
    avatarImage = [avatarImage thumbnailImage:320 transparentBorder:0 cornerRadius:160 interpolationQuality:kCGInterpolationHigh];
    RgCallComponent *c = [super newWithView:{} component:
		[CKBackgroundLayoutComponent newWithComponent:
			[CKStackLayoutComponent newWithView:{} size:{
				.height = [[call.data objectForKey:@"height"] floatValue],
			} style:{
				.direction = CKStackLayoutDirectionVertical,
				.alignItems = CKStackLayoutAlignItemsStretch
			}
			children:{
				// Header
				{[CKStackLayoutComponent newWithView:{
					[UIView class],
					{
						{@selector(setBackgroundColor:), [UIColor colorWithHex:@"#F4F4F4"]},
					}
				} size:{
					.height = 50
				} style:{
					.direction = CKStackLayoutDirectionHorizontal,
					.alignItems = CKStackLayoutAlignItemsStretch
				}
				children:{
					{[CKInsetComponent newWithInsets:{.top = INFINITY, .left = 8, .bottom = INFINITY} component:
						[CKImageComponent newWithImage:[UIImage imageNamed:@"ringmail_incall-arrow"]]
					]},
					{
						.flexGrow = YES,
						.component = [CKInsetComponent newWithInsets:{.top = INFINITY, .left = 4, .bottom = INFINITY} component:
							[CKInsetComponent newWithInsets:{.top = 4} component:
								[CKLabelComponent newWithLabelAttributes:{
									.string = [call.data objectForKey:@"address"],
									.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Cn" size:18],
								}
								viewAttributes:{
									{@selector(setBackgroundColor:), [UIColor clearColor]},
									{@selector(setUserInteractionEnabled:), @NO},
								}
								size:{}]
							]
						]
					},
					{[CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY, .right = 16} component:
                        [CKLabelComponent newWithLabelAttributes:{
							.string = ([call.data[@"video"] boolValue]) ? @"Video" : @"Call",
							.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Cn" size:20],
							.alignment = NSTextAlignmentRight,
						}
						viewAttributes:{
							{@selector(setBackgroundColor:), [UIColor clearColor]},
							{@selector(setUserInteractionEnabled:), @NO},
						}
						size:{}]
					]},
				}]},
				// Call Details
				{[CKStackLayoutComponent newWithView:{} size:{
					.height = 50
				} style:{
					.direction = CKStackLayoutDirectionHorizontal,
					.alignItems = CKStackLayoutAlignItemsStretch
				}
				children:{
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
					{[CKInsetComponent newWithInsets:{.right = 6, .top = INFINITY, .bottom = INFINITY} component:
						[CKImageComponent newWithImage:[UIImage imageNamed:@"ringmail_incall-dialpad"]]
					]},
				}]},
				{[CKStackLayoutComponent newWithView:{} size:{
					.height = 40,
				} style:{
					.direction = CKStackLayoutDirectionHorizontal,
					.alignItems = CKStackLayoutAlignItemsStretch
				}
				children:{
					{.flexGrow = YES, .component = [CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component:
						[CKLabelComponent newWithLabelAttributes:{
							.string = [call.data objectForKey:@"label"],
							.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Cn" size:24],
							.alignment = NSTextAlignmentCenter,
						}
						viewAttributes:{
							{@selector(setBackgroundColor:), [UIColor clearColor]},
							{@selector(setUserInteractionEnabled:), @NO},
						}
						size:{}]
					]},
				}]},
				{[CKStackLayoutComponent newWithView:{} size:{
					.height = 24,
				} style:{
					.direction = CKStackLayoutDirectionHorizontal,
					.alignItems = CKStackLayoutAlignItemsStretch
				}
				children:{
					{.flexGrow = YES, .component = [CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component:
						[CKComponent newWithView:{&buildDuration} size:{.height = 20, .width = 200}]
					]},
				}]},
				{[CKStackLayoutComponent newWithView:{} size:{
					.height = 180
				} style:{
					.direction = CKStackLayoutDirectionHorizontal,
					.alignItems = CKStackLayoutAlignItemsStretch
				}
				children:{
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
					{[CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component:
						[CKImageComponent newWithImage:avatarImage size:{.height = 160, .width = 160}]
					]},
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
				}]},
				// Control Buttons
				{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
				{[CKStackLayoutComponent newWithView:{} size:{
					.height = 75
				} style:{
					.direction = CKStackLayoutDirectionHorizontal,
					.alignItems = CKStackLayoutAlignItemsStretch
				}
				children:{
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
					{[CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component:
						[CKButtonComponent newWithTitles:{} titleColors:{} images:{
							{UIControlStateNormal,[UIImage imageNamed:(
								[[call.data objectForKey:@"mute"] boolValue]
							) ? @"ringmail_mic-x.png" : @"ringmail_mic.png"]},
						} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(onMutePressed:) size:{} attributes:{} accessibilityConfiguration:{}]
					]},
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
					{[CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component:
						[CKButtonComponent newWithTitles:{} titleColors:{} images:{
							{UIControlStateNormal,[UIImage imageNamed:(
								[[call.data objectForKey:@"speaker"] boolValue]
							) ? @"ringmail_speaker.png" : @"ringmail_speaker-x.png"]},
						} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(onSpeakerPressed:) size:{} attributes:{} accessibilityConfiguration:{}]
					]},
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
				}]},
				{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
				{[CKStackLayoutComponent newWithView:{} size:{
					.height = 100
				} style:{
					.direction = CKStackLayoutDirectionHorizontal,
					.alignItems = CKStackLayoutAlignItemsStretch
				}
				children:{
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
					{[CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component:
						[CKButtonComponent newWithTitles:{} titleColors:{} images:{
							{UIControlStateNormal,[UIImage imageNamed:@"ringmail_endcall.png"]},
						} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(onHangupPressed:) size:{} attributes:{} accessibilityConfiguration:{}]
					]},
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
				}]},
			}]
			background:[CKComponent newWithView:{
				[UIView class],
				{
					{@selector(setBackgroundColor:), [UIColor colorWithHex:@"#e2e4e7"]},
				}
			} size:{}]
		]
	];
    return c;
}

- (void)onHangupPressed:(CKButtonComponent *)sender
{
	[RgCall requestHangup];
}

- (void)onSpeakerPressed:(CKButtonComponent *)sender
{
	[RgCall toggleSpeaker];
}

- (void)onMutePressed:(CKButtonComponent *)sender
{
	[RgCall toggleMute];
}

static UIView *buildDuration(void)
{
	globalDuration = [[RgCallDuration alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
	[RgCallViewController setDurationLabel:globalDuration];
	return globalDuration;
}

@end
