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

#import "MainCardComponent.h"
#import "MainCardComponentController.h"
#import "Card.h"
#import "CardContext.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "UIColor+Hex.h"

@implementation MainCardComponent

@synthesize cardData;

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
    CKComponentScope scope(self, [data objectForKey:@"session_tag"]);
	//NSLog(@"Component Data: %@", data);
    UIImage *cardImage = [data objectForKey:@"image"];
    cardImage = [cardImage thumbnailImage:92 transparentBorder:0 cornerRadius:46 interpolationQuality:kCGInterpolationHigh];

    NSString *latest;
    NSDate *dateLatest = [data objectForKey:@"timestamp"];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *locale = [NSLocale currentLocale];
    [dateFormatter setLocale:locale];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    latest = [dateFormatter stringFromDate:dateLatest];
    
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    latest = [latest stringByAppendingString:@": "];
    latest = [latest stringByAppendingString:[dateFormatter stringFromDate:dateLatest]];
	
	NSString *msg = @"";
	BOOL append_duration = NO;
	BOOL has_media = NO;
	if ([[data objectForKey:@"last_event"] isEqualToString:@"chat"] && (![[data objectForKey:@"last_message"] isEqual:[NSNull null]]))
	{
		msg = [data objectForKey:@"last_message"];
		if ([[data objectForKey:@"msg_inbound"] boolValue])
		{
			latest = [NSString stringWithFormat:@"Received %@", latest];
		}
		else
		{
			latest = [NSString stringWithFormat:@"Sent %@", latest];
		}
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
			latest = [NSString stringWithFormat:@"Inbound %@", latest];
		}
		else
		{
			msg = @"Call ";
			append_duration = YES;
			latest = [NSString stringWithFormat:@"Outbound %@", latest];
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

    // Cheat and get a width constraint for the card text box
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    
    //if ([[data objectForKey:@"unread"] integerValue] > 0)
	
	/*CKComponentViewConfiguration scfg;
	if (data[@"removable"])
	{
		scfg = {
    	    [UIView class],
            {
                {CKComponentGestureAttribute([UISwipeGestureRecognizer class], &setupSwipeLeftRecognizer, NSSelectorFromString(@"didSwipeLeft:gesture:"), {})},
                {CKComponentGestureAttribute([UISwipeGestureRecognizer class], &setupSwipeRightRecognizer, NSSelectorFromString(@"didSwipeRight:gesture:"), {})},
            }
	 	};
	}
	else
	{
		scfg = {
			[UIView class],
			{}
		};
	}*/
    
	/*std::vector<CKStackLayoutComponentChild> body = {};
	if (! [latest isEqualToString:@""])
	{
		CKComponent *bodyItem;
		if (has_media)
		{
			UIImage *thumb = [context chatImage:data[@"msg_uuid"] key:@"msg_thumbnail"];
			bodyItem = [CKStackLayoutComponent newWithView:{} size:{} style:{
                .direction = CKStackLayoutDirectionHorizontal,
                .alignItems = CKStackLayoutAlignItemsStretch
            } children:{
                {[CKImageComponent newWithImage:thumb size:{.height=thumb.size.height, .width=thumb.size.width}]},
                {
					.flexGrow = YES,
                }
            }];
		}
		else
		{
			bodyItem = [CKTextComponent
			  newWithTextAttributes:{
				  .attributedString = attrString,
				  .lineBreakMode = NSLineBreakByWordWrapping,
			  }
			  viewAttributes:{
				  {@selector(setBackgroundColor:), [UIColor clearColor]},
				  {@selector(setUserInteractionEnabled:), @NO},
			  }
			  options:{}
			  size:{.width = textWidth}];
		}
		body = {
		   {[CKInsetComponent
			 newWithInsets:{.left = 20, .right = 0, .top = 15, .bottom = 0}
			 component:
			 [CKLabelComponent
			  newWithLabelAttributes:{
				  .string = latest,
				  .font = [UIFont fontWithName:@"HelveticaNeueLTStd-Cn" size:14],
				  .color = [UIColor colorWithHex:@"#70726d"],
			  }
			  viewAttributes:{
				  {@selector(setBackgroundColor:), [UIColor clearColor]},
				  {@selector(setUserInteractionEnabled:), @NO},
			  }
			  size:{}]
			 ]},
		   {[CKInsetComponent
			 newWithInsets:{.left = 20, .right = 0, .top = 12, .bottom = 15}
			 component:bodyItem]
			 }
		};
	}*/
    
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
    
    BOOL showActions = YES;
    CKComponent* card = nil;
    if (showActions)
    {
        card = [CKStackLayoutComponent newWithView:{} size:{.width = width - 20, .height = 62} style:{
            .direction = CKStackLayoutDirectionHorizontal,
            .alignItems = CKStackLayoutAlignItemsStart
        } children:{
            // Icon
            {[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 8, .bottom = 8} component:
                [CKImageComponent newWithImage:cardImage size:{.height = 46, .width = 46}]
            ]},
            // Name & message
            {body},
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
                    [CKImageComponent newWithImage:[UIImage imageNamed:@"ringmail_triangle_grey.png"]]
                ]},
                {[CKInsetComponent newWithInsets:{.left = 6, .right = 20, .top = 3, .bottom = 0} component:
                    [CKLabelComponent newWithLabelAttributes:{
							.string = @"TODAY >",
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
    else
    {
        card = [CKStackLayoutComponent newWithView:{} size:{.width = width - 20, .height = 62} style:{
            .direction = CKStackLayoutDirectionHorizontal,
            .alignItems = CKStackLayoutAlignItemsStart
        } children:{
            // Icon
            {[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 8, .bottom = 8} component:
                [CKImageComponent newWithImage:cardImage size:{.height = 46, .width = 46}]
            ]},
            // Name & message
            {body},
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
                    [CKImageComponent newWithImage:[UIImage imageNamed:@"ringmail_triangle_green.png"]]
                ]},
                {[CKInsetComponent newWithInsets:{.left = 6, .right = 20, .top = 3, .bottom = 0} component:
                    [CKLabelComponent newWithLabelAttributes:{
							.string = @"TODAY >",
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

    MainCardComponent *c = [super newWithView:{} component:
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
    [c setCardData:data];
    return c;
}

static CKComponent *lineComponent()
{
    return [CKComponent
            newWithView:{
                [UIView class],
                {
                    {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#d4d5d7"]},
                }
            }
            size:{.height = 1 / [UIScreen mainScreen].scale}];
}

- (void)actionChat:(CKButtonComponent *)sender
{
    Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    [card showMessages];
}

- (void)actionCall:(CKButtonComponent *)sender
{
    Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    [card startCall:NO];
}

- (void)actionVideo:(CKButtonComponent *)sender
{
    Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    [card startCall:YES];
}

- (void)actionContact:(CKButtonComponent *)sender
{
    Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    [card gotoContact];
}

static void setupSwipeLeftRecognizer(UIGestureRecognizer* recognizer) {
    UISwipeGestureRecognizer* sw = (UISwipeGestureRecognizer*)recognizer;
    [sw setDirection:UISwipeGestureRecognizerDirectionLeft];
}

static void setupSwipeRightRecognizer(UIGestureRecognizer* recognizer) {
    UISwipeGestureRecognizer* sw = (UISwipeGestureRecognizer*)recognizer;
    [sw setDirection:UISwipeGestureRecognizerDirectionRight];
}

@end
