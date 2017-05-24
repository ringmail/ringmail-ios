/* This file provided by Facebook is for non-commercial testing and evaluation
 * purposes only.  Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "CKComponentSubclass.h"
#import "MessageThread.h"
#import "MessageThreadContext.h"
#import "MessageThreadComponent.h"
#import "RingKit.h"
#import "UIImage+Scale.h"
//#import "MessageThreadComponentController.h"

#import "UIColor+Hex.h"

@implementation MessageThreadComponent

@synthesize currentThread;

+ (instancetype)newWithMessageThread:(MessageThread *)msg context:(MessageThreadContext *)context
{
	NSLog(@"Component Data: %@", msg.data);
	NSDictionary* data = msg.data;
	RKThread* thread = data[@"thread"];
    CKComponentScope scope(self, thread.threadId);
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
	
	// TODO: Use correct image
    UIImage *cardImage = [context imageNamed:@"avatar_unknown_small.png"];
	cardImage = [cardImage scaleImageToSize:CGSizeMake(46.0f, 46.0f)];
    //cardImage = [cardImage thumbnailImage:92 transparentBorder:0 cornerRadius:46 interpolationQuality:kCGInterpolationHigh];

    NSString *latest;
    NSDate *dateLatest = [data objectForKey:@"timestamp"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *locale = [NSLocale currentLocale];
    [dateFormatter setLocale:locale];
    [dateFormatter setDoesRelativeDateFormatting:YES];
	
	BOOL today = [[NSCalendar currentCalendar] isDateInToday:dateLatest];
	if (today)
	{
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        latest = [dateFormatter stringFromDate:dateLatest];
	}
	else
	{
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        latest = [dateFormatter stringFromDate:dateLatest];
	}
	
	NSString *msg = @"";
	BOOL append_duration = NO;
	BOOL has_media = NO;
	if ([[data objectForKey:@"last_event"] isEqualToString:@"chat"] && (![[data objectForKey:@"last_message"] isEqual:[NSNull null]]))
	{
		msg = [data objectForKey:@"last_message"];
		if ([data[@"msg_type"] isEqualToString:@"image/png"])
		{
			NSLog(@"Image message: %@", data);
			has_media = YES;
		}
	}
	else if (! [[data objectForKey:@"call_time"] isEqual:[NSNull null]])
	{
		if ([[data objectForKey:@"call_inbound"] boolValue])
		{
			if ([[data objectForKey:@"call_status"] isEqualToString:@"missed"])
			{
				msg = @"Missed Call";
			}
			else
			{
				msg = @"Call ";
				append_duration = YES;
			}
		}
		else
		{
			msg = @"Call ";
			append_duration = YES;
		}
	}
	else
	{
		latest = @"";
		// blank
	}
	
	if (append_duration && [[data objectForKey:@"call_status"] isEqualToString:@"success"])
	{
		msg = [msg stringByAppendingString:[data objectForKey:@"call_duration"]];
	}
    
    NSDictionary *attrsDictionary = @{
        NSFontAttributeName: [UIFont systemFontOfSize:14],
        NSForegroundColorAttributeName: [UIColor colorWithHex:@"#353535"],
    };
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:msg attributes:attrsDictionary];

	
	
    CKComponent* body = nil;
	body = [CKStackLayoutComponent newWithView:{} size:{.width = width - (20/*margin*/ + 66/*icon*/ + 74/*actions*/), .height = 62} style:{
        .direction = CKStackLayoutDirectionVertical,
        .alignItems = CKStackLayoutAlignItemsStart
    } children:{
        {[CKInsetComponent newWithInsets:{.left = 0, .right = 4, .top = 4, .bottom = 0} component:
            [CKLabelComponent newWithLabelAttributes:{
				.string = [data objectForKey:@"label"],
				.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold],
				.alignment = NSTextAlignmentLeft,
                .color = [UIColor colorWithHex:@"#222222"],
			} viewAttributes:{
				{@selector(setBackgroundColor:), [UIColor clearColor]},
				{@selector(setUserInteractionEnabled:), @NO},
			} size:{.height = 18}]
        ]},
        {[CKInsetComponent newWithInsets:{.left = 0, .right = 4, .top = 0, .bottom = 0} component:
            [CKTextComponent newWithTextAttributes:{
                .attributedString = attrString,
                .lineBreakMode = NSLineBreakByWordWrapping,
            } viewAttributes:{
                {@selector(setBackgroundColor:), [UIColor clearColor]},
                {@selector(setUserInteractionEnabled:), @NO},
            } options:{} size:{.height = 34, .width = width - (20/*margin*/ + 66/*icon*/ + 74/*actions*/ + 4/*inset*/ )}]
        ]}
    }];
	
	NSNumber *st = scope.state();
    BOOL showActions = [st boolValue];
    CKComponent* card = nil;
    if (showActions)
    {
        card = [CKStackLayoutComponent newWithView:{} size:{.width = width - 20, .height = 128} style:{
            .direction = CKStackLayoutDirectionVertical,
            .alignItems = CKStackLayoutAlignItemsStart
        } children:{
        	{[CKStackLayoutComponent newWithView:{} size:{.width = width - 20, .height = 62} style:{
                .direction = CKStackLayoutDirectionHorizontal,
                .alignItems = CKStackLayoutAlignItemsStart
            } children:{
				{[CKStackLayoutComponent newWithView:{
					[UIView class],
					{CKComponentTapGestureAttribute(@selector(actionChat:))}
				} size:{.width = width - 94, .height = 62} style:{
					.direction = CKStackLayoutDirectionHorizontal,
					.alignItems = CKStackLayoutAlignItemsStart
				} children:{
					// Icon
					{[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 8, .bottom = 8} component:
						[CKImageComponent newWithImage:cardImage size:{.height = 46, .width = 46}]
					]},
					// Name & message
					{body},
				}]},
                {[CKComponent newWithView:{
                    [UIView class],
                    {
                        {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#D1D1D1"]},
                    }
                } size:{.height = 62, .width = 1 / [UIScreen mainScreen].scale}]},
                // Actions button
                {[CKStackLayoutComponent newWithView:{} size:{.width = 74, .height = 62} style:{
                    .direction = CKStackLayoutDirectionVertical,
                    .alignItems = CKStackLayoutAlignItemsStart
                } children:{
                    {[CKInsetComponent newWithInsets:{.left = 20, .right = INFINITY, .top = 16, .bottom = 0} component:
						[CKButtonComponent newWithTitles:{} titleColors:{} images:{
							{UIControlStateNormal, [context imageNamed:@"ringmail_triangle_grey.png"]},
						} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionButton:) size:{} attributes:{} accessibilityConfiguration:{}]
                    ]},
                    {[CKInsetComponent newWithInsets:{.left = 6, .right = 20, .top = 3, .bottom = 0} component:
                        [CKLabelComponent newWithLabelAttributes:{
    							.string = latest,
    							.font = [UIFont systemFontOfSize:9 weight:UIFontWeightBold],
    							.alignment = NSTextAlignmentLeft,
    						}
    						viewAttributes:{
    							{@selector(setBackgroundColor:), [UIColor clearColor]},
    							{@selector(setUserInteractionEnabled:), @NO},
    						}
    						size:{.height = 11, .width = 54}]
                    ]},
                }]}
			}]},
            {[CKComponent newWithView:{
                [UIView class],
                {
                    {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#D1D1D1"]},
                }
            } size:{.height = 1 / [UIScreen mainScreen].scale, .width = width - 20}]},
			{[CKInsetComponent newWithInsets:{.left = INFINITY, .right = INFINITY, .top = 13, .bottom = 13} component:
    		    [CKStackLayoutComponent newWithView:{} size:{.width = 281, .height = 65} style:{
                    .direction = CKStackLayoutDirectionHorizontal,
                    .alignItems = CKStackLayoutAlignItemsStart
                } children:{
					{[CKButtonComponent newWithTitles:{} titleColors:{} images:{
						{UIControlStateNormal, [context imageNamed:@"ringmail_action_call_normal.png"]},
					} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionCall:) size:{.height=39, .width=87} attributes:{} accessibilityConfiguration:{}]},
					{[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 0, .bottom = 0} component:
						[CKButtonComponent newWithTitles:{} titleColors:{} images:{
							{UIControlStateNormal, [context imageNamed:@"ringmail_action_video_normal.png"]},
						} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionVideo:) size:{.height=39, .width=87} attributes:{} accessibilityConfiguration:{}]
					]},
					{[CKButtonComponent newWithTitles:{} titleColors:{} images:{
						{UIControlStateNormal, [context imageNamed:@"ringmail_action_text_normal.png"]},
					} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionChat:) size:{.height=39, .width=87} attributes:{} accessibilityConfiguration:{}]},
				}]
			]},
        }];
    }
    else
    {
        card = [CKStackLayoutComponent newWithView:{} size:{.width = width - 20, .height = 62} style:{
            .direction = CKStackLayoutDirectionHorizontal,
            .alignItems = CKStackLayoutAlignItemsStart
        } children:{
			{[CKStackLayoutComponent newWithView:{
                [UIView class],
                {CKComponentTapGestureAttribute(@selector(actionChat:))}
			} size:{.width = width - 94, .height = 62} style:{
                .direction = CKStackLayoutDirectionHorizontal,
                .alignItems = CKStackLayoutAlignItemsStart
            } children:{
                // Icon
                {[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 8, .bottom = 8} component:
                    [CKImageComponent newWithImage:cardImage size:{.height = 46, .width = 46}]
                ]},
                // Name & message
                {body},
			}]},
            {[CKComponent newWithView:{
                [UIView class],
                {
                    {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#D1D1D1"]},
                }
            } size:{.height = 62, .width = 1 / [UIScreen mainScreen].scale}]},
            // Actions button
            {[CKStackLayoutComponent newWithView:{} size:{.width = 74, .height = 62} style:{
                .direction = CKStackLayoutDirectionVertical,
                .alignItems = CKStackLayoutAlignItemsStart
            } children:{
                {[CKInsetComponent newWithInsets:{.left = 20, .right = INFINITY, .top = 16, .bottom = 0} component:
					[CKButtonComponent newWithTitles:{} titleColors:{} images:{
							{UIControlStateNormal, [context imageNamed:@"ringmail_triangle_green.png"]},
						} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionButton:) size:{} attributes:{} accessibilityConfiguration:{}]
                ]},
                {[CKInsetComponent newWithInsets:{.left = 6, .right = 20, .top = 3, .bottom = 0} component:
                    [CKLabelComponent newWithLabelAttributes:{
							.string = latest,
							.font = [UIFont systemFontOfSize:9 weight:UIFontWeightBold],
							.alignment = NSTextAlignmentLeft,
						}
						viewAttributes:{
							{@selector(setBackgroundColor:), [UIColor clearColor]},
							{@selector(setUserInteractionEnabled:), @NO},
						}
						size:{.height = 11, .width = 54}]
                ]},
            }]}
        }];
    }

    MessageThreadComponent *c = [super newWithView:{} component:
        [CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 2, .bottom = 2} component:
            [CKBackgroundLayoutComponent newWithComponent:card background:
                [CKComponent newWithView:{
                    [UIView class],
                    {
                        {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#F7F7F7"]},
                        {@selector(setContentMode:), @(UIViewContentModeScaleAspectFill)},
                        {CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), @10.0},
                        {@selector(setClipsToBounds:), @YES}
                    }
                } size:{}]
            ]
        ]
    ];
    [c setCurrentThread:msg];
    return c;
}

+ (id)initialState
{
	return [NSNumber numberWithBool:NO];
}

- (void)actionButton:(CKButtonComponent *)sender
{
	//NSLog(@"Action Button 1");
	[self updateState:^(id oldState){
		//NSLog(@"Action Button 2");
		NSNumber* st = oldState;
		st = [NSNumber numberWithBool:(! [st boolValue])];
		return st;
	} mode:CKUpdateModeAsynchronous];
}

- (void)actionChat:(CKButtonComponent *)sender
{
/*
    Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    [card showMessages];
*/
}

- (void)actionCall:(CKButtonComponent *)sender
{
/*
    Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    [card startCall:NO];
*/
}

- (void)actionVideo:(CKButtonComponent *)sender
{
/*
    Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    [card startCall:YES];
*/
}

- (void)actionContact:(CKButtonComponent *)sender
{
/*
    Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    [card gotoContact];
*/
}

/*
static void setupSwipeLeftRecognizer(UIGestureRecognizer* recognizer)
{
    UISwipeGestureRecognizer* sw = (UISwipeGestureRecognizer*)recognizer;
    [sw setDirection:UISwipeGestureRecognizerDirectionLeft];
}

static void setupSwipeRightRecognizer(UIGestureRecognizer* recognizer)
{
    UISwipeGestureRecognizer* sw = (UISwipeGestureRecognizer*)recognizer;
    [sw setDirection:UISwipeGestureRecognizerDirectionRight];
}
*/

@end
