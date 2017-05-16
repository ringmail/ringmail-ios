#import "RgIncomingCallComponent.h"

#import <ComponentKit/ComponentKit.h>
#import "UIColor+Hex.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"

#import "RgCall.h"
#import "RgCallContext.h"
#import "RgCallDuration.h"

@implementation RgIncomingCallComponent

+ (instancetype)newWithCall:(RgCall *)call context:(RgCallContext *)context
{
	CKComponentScope scope(self);
	if (! [call.data objectForKey:@"address"])
	{
		RgIncomingCallComponent *c = [super newWithView:{} component:[CKComponent newWithView:{} size:{}]];
		return c;
	}
    UIImage *avatarImage = [context imageNamed:[call.data objectForKey:@"address"]];
    avatarImage = [avatarImage thumbnailImage:320 transparentBorder:0 cornerRadius:160 interpolationQuality:kCGInterpolationHigh];
    RgIncomingCallComponent *c = [super newWithView:{} component:
		[CKBackgroundLayoutComponent newWithComponent:
			[CKStackLayoutComponent newWithView:{} size:{
				.height = [[call.data objectForKey:@"height"] floatValue],
			} style:{
				.direction = CKStackLayoutDirectionVertical,
				.alignItems = CKStackLayoutAlignItemsStretch
			}
			children:{
				// Header
//				{[CKStackLayoutComponent newWithView:{
//					[UIView class],
//					{
//						{@selector(setBackgroundColor:), [UIColor colorWithHex:@"#F4F4F4"]},
//					}
//				} size:{
//					.height = 50
//				} style:{
//					.direction = CKStackLayoutDirectionHorizontal,
//					.alignItems = CKStackLayoutAlignItemsStretch
//				}
//				children:{
//					{[CKInsetComponent newWithInsets:{.top = INFINITY, .left = 8, .bottom = INFINITY} component:
//						[CKImageComponent newWithImage:[UIImage imageNamed:@"ringmail_incall-arrow"]]
//					]},
//					{
//						.flexGrow = YES,
//						.component = [CKInsetComponent newWithInsets:{.top = INFINITY, .left = 4, .bottom = INFINITY} component:
//							[CKInsetComponent newWithInsets:{.top = 4} component:
//								[CKLabelComponent newWithLabelAttributes:{
//									.string = [call.data objectForKey:@"address"],
//									.font = [UIFont fontWithName:@"SFUIText-Regular" size:18],
//								}
//								viewAttributes:{
//									{@selector(setBackgroundColor:), [UIColor clearColor]},
//									{@selector(setUserInteractionEnabled:), @NO},
//								}
//								size:{}]
//							]
//						]
//					},
//                    {[CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY, .right = 16} component:
//                        [CKLabelComponent newWithLabelAttributes:{
//							.string = ([call.data[@"video"] boolValue]) ? @"Video" : @"Call",
//							.font = [UIFont fontWithName:@"HelveticaNeueLTStd-Cn" size:20],
//							.alignment = NSTextAlignmentRight,
//						}
//						viewAttributes:{
//							{@selector(setBackgroundColor:), [UIColor clearColor]},
//							{@selector(setUserInteractionEnabled:), @NO},
//						}
//						size:{}]
//					]},
//				}]},
				// Call Details
                {[CKStackLayoutComponent newWithView:{} size:{
                    .height = 70
                } style:{
                    .direction = CKStackLayoutDirectionHorizontal,
                    .alignItems = CKStackLayoutAlignItemsStretch
                }
                                            children:{}]},
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
                        .font = [UIFont fontWithName:@"SFUIText-Regular" size:33],
                        .color = [UIColor colorWithHex:@"#ffffff"],
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
                    .height = 50,
                } style:{
                    .direction = CKStackLayoutDirectionHorizontal,
                    .alignItems = CKStackLayoutAlignItemsStretch
                }
                children:{
                    {.flexGrow = YES, .component = [CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component:
                        [CKLabelComponent newWithLabelAttributes:{
                        .string = @"Calling",
                        .font = [UIFont fontWithName:@"SFUIText-Regular" size:22],
                        .color = [UIColor colorWithHex:@"#ffffff"],
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
                    .height = 200
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
                {[CKStackLayoutComponent newWithView:{} size:{
                    .height = 40,
                } style:{
                    .direction = CKStackLayoutDirectionHorizontal,
                    .alignItems = CKStackLayoutAlignItemsStretch
                }
                children:{
                    {.flexGrow = YES, .component = [CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component: [CKLabelComponent newWithLabelAttributes:{
                        .string = [call.data objectForKey:@"address"],
                        .font = [UIFont fontWithName:@"SFUIText-Regular" size:20],
                        .color = [UIColor colorWithHex:@"#ffffff"],
                        .alignment = NSTextAlignmentCenter,
                    }
                  viewAttributes:{
                      {@selector(setBackgroundColor:), [UIColor clearColor]},
                      {@selector(setUserInteractionEnabled:), @NO},
                  }
                size:{}]
                ]},
                }]},
				// Control Buttons
                {[CKStackLayoutComponent newWithView:{} size:{
                    .height = 60
                } style:{
                    .direction = CKStackLayoutDirectionHorizontal,
                    .alignItems = CKStackLayoutAlignItemsStretch
                }
                children:{}]},
				{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
				{[CKStackLayoutComponent newWithView:{} size:{
					.height = 60
				} style:{
					.direction = CKStackLayoutDirectionHorizontal,
					.alignItems = CKStackLayoutAlignItemsStretch
				}
				children:{
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
					{[CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component:
						[CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Decline"}} titleColors:{{UIControlStateNormal,[UIColor colorWithHex:@"#ffffff"]}} images:{} backgroundImages:{{UIControlStateNormal,[UIImage imageNamed:@"decline_button_incoming_screen.png"]},} titleFont:[UIFont fontWithName:@"SFUIText-Medium" size:18] selected:NO enabled:YES action:@selector(onRejectPressed:) size:{} attributes:{} accessibilityConfiguration:{}]
					]},
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
					{[CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component:
						[CKButtonComponent newWithTitles:{{UIControlStateNormal, @"Answer"}} titleColors:{{UIControlStateNormal,[UIColor colorWithHex:@"#ffffff"]}} images:{} backgroundImages:{{UIControlStateNormal,[UIImage imageNamed:@"answer_button_Incoming_call.png"]},} titleFont:[UIFont fontWithName:@"SFUIText-Medium" size:18] selected:NO enabled:YES action:@selector(onAnswerPressed:) size:{} attributes:{} accessibilityConfiguration:{}]
					]},
					{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
				}]},
                {.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
                {[CKStackLayoutComponent newWithView:{} size:{
                    .height = 60
                } style:{
                    .direction = CKStackLayoutDirectionHorizontal,
                    .alignItems = CKStackLayoutAlignItemsStretch
                }
                children:{}]},
			}]
			background:
            [CKInsetComponent newWithInsets:{.top = INFINITY, .bottom = INFINITY} component:
             [CKImageComponent newWithImage:[UIImage imageNamed:@"background_call.png"]]
            ]
		]
	];
    return c;
}

- (void)onRejectPressed:(CKButtonComponent *)sender
{
	[RgCall incomingReject];
}

- (void)onAnswerPressed:(CKButtonComponent *)sender
{
	[RgCall incomingAnswer];
}

@end
