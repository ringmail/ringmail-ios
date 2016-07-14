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
    cardImage = [cardImage thumbnailImage:80 transparentBorder:0 cornerRadius:40 interpolationQuality:kCGInterpolationHigh];

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
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIFont fontWithName:@"HelveticaNeue" size:16] forKey:NSFontAttributeName];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:msg attributes:attrsDictionary];

    // Cheat and get a width constraint for the card text box
    CGFloat textWidth = [[UIScreen mainScreen] bounds].size.width - 100;
    
    CKComponentViewConfiguration vcfg;
    if ([[data objectForKey:@"unread"] integerValue] > 0)
    {
        vcfg = {
            [UIView class],
            {
                {@selector(setBackgroundColor:), [UIColor whiteColor]},
                {CKComponentViewAttribute::LayerAttribute(@selector(setShadowOpacity:)),0.8f},
                {CKComponentViewAttribute::LayerAttribute(@selector(setShadowRadius:)),@3},
                {CKComponentViewAttribute::LayerAttribute(@selector(setShadowColor:)),(id)[[UIColor colorWithHex:@"#0077c3"] CGColor]},
                {CKComponentViewAttribute::LayerAttribute(@selector(setShadowOffset:)),[NSValue valueWithCGSize:CGSizeMake(2, 2)]},
            }
        };
    }
    else
    {
        vcfg = {
            [UIView class],
            {
                {@selector(setBackgroundColor:), [UIColor whiteColor]},
                {CKComponentViewAttribute::LayerAttribute(@selector(setBorderColor:)), (id)[[UIColor colorWithHex:@"#d4d5d7"] CGColor]},
                {CKComponentViewAttribute::LayerAttribute(@selector(setBorderWidth:)), 1 / [UIScreen mainScreen].scale},
                
            }
        };
    }
	
	std::vector<CKStackLayoutComponentChild> body = {};
	if (! [latest isEqualToString:@""])
	{
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
			 component:
			 [CKTextComponent
			  newWithTextAttributes:{
				  .attributedString = attrString,
				  .lineBreakMode = NSLineBreakByWordWrapping,
			  }
			  viewAttributes:{
				  {@selector(setBackgroundColor:), [UIColor clearColor]},
				  {@selector(setUserInteractionEnabled:), @NO},
			  }
			  accessibilityContext:{}
			  size:{.width = textWidth}]
			 ]}
		};
	}
	
    MainCardComponent *c = [super newWithView:{
        [UIView class],
        {
            //{CKComponentGestureAttribute([UISwipeGestureRecognizer class], &setupSwipeLeftRecognizer, NSSelectorFromString(@"didSwipeLeft:gesture:"), {})},
            //{CKComponentGestureAttribute([UISwipeGestureRecognizer class], &setupSwipeRightRecognizer, NSSelectorFromString(@"didSwipeRight:gesture:"), {})},
        }
    } component:
        [CKInsetComponent
        // Left and right inset of 30pts; centered vertically:
        newWithInsets:{.left = 10, .right = 10, .top = 0, .bottom = 10}
        component:
            [CKBackgroundLayoutComponent
            newWithComponent:
                [CKStackLayoutComponent newWithView:vcfg size:{} style:{
                    .direction = CKStackLayoutDirectionVertical,
                    .alignItems = CKStackLayoutAlignItemsStretch
                }
                children:{
                    {[CKInsetComponent
                      newWithInsets:{.left = 5, .right = 5, .top = 5, .bottom = 5}
                      component:
                          [CKStackLayoutComponent newWithView:{} size:{.height = 40} style:{
                            .direction = CKStackLayoutDirectionHorizontal,
                            .alignItems = CKStackLayoutAlignItemsStretch
                          }
                          children:{
                              {
                                  [CKButtonComponent newWithTitles:{} titleColors:{} images:{
                                      {UIControlStateNormal,cardImage},
                                      } backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionContact:) size:{.height = 40, .width = 40} attributes:{} accessibilityConfiguration:{}],
                              }, {
                                  .flexGrow = YES,
                                  .component = [CKInsetComponent
                                   newWithInsets:{.left = 7, .right = 5, .top = INFINITY, .bottom = INFINITY}
                                   component:
                                         [CKStackLayoutComponent newWithView:{
                                            [UIView class],
                                            {CKComponentTapGestureAttribute(@selector(actionContact:))}
                                         } size:{} style:{}
                                            children:{
                                              {
                                                 [CKInsetComponent
                                                     newWithInsets:{.left = 0, .right = 0, .top = 4, .bottom = 0}
                                                     component:
                                                          [CKLabelComponent
                                                          newWithLabelAttributes:{
                                                              .string = [data objectForKey:@"label"],
                                                              .font = [UIFont fontWithName:@"HelveticaNeueLTStd-Cn" size:18],
                                                              .color = [UIColor colorWithHex:@"#33362f"],
                                                          }
                                                          viewAttributes:{
                                                              {@selector(setBackgroundColor:), [UIColor clearColor]},
                                                              {@selector(setUserInteractionEnabled:), @NO},
                                                          }
                                                          size:{}]
                                                ]
                                            }
                                         }]
                                   ]
                              }, {
                                  .alignSelf = CKStackLayoutAlignSelfEnd,
                                  .component = [CKStackLayoutComponent newWithView:{} size:{.height = 40} style:{
                                      .direction = CKStackLayoutDirectionHorizontal,
                                      .alignItems = CKStackLayoutAlignItemsStretch
                                  }
                                  children:{
                                      {
                                          [CKInsetComponent
                                           newWithInsets:{.left = 0, .right = 0, .top = INFINITY, .bottom = INFINITY}
                                           component:
                                              [CKButtonComponent newWithTitles:{} titleColors:{} images:{
                                                      {UIControlStateNormal,[context imageNamed:@"button_video"]},
                                                  } backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionVideo:) size:{.height = 30, .width = 30} attributes:{} accessibilityConfiguration:{}]
                                           ]
                                      }, {
                                          [CKInsetComponent
                                           newWithInsets:{.left = 12, .right = 7, .top = INFINITY, .bottom = INFINITY}
                                           component:
                                              [CKButtonComponent newWithTitles:{} titleColors:{} images:{
                                                      {UIControlStateNormal,[context imageNamed:@"button_call"]},
                                                  } backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionCall:) size:{.height = 30, .width = 30} attributes:{} accessibilityConfiguration:{}]
                                           ]
                                      },
                                  }]
                              }
                          }]
                      ]},
                    {lineComponent()},
                    {
                        [CKStackLayoutComponent newWithView:{
                            [UIView class],
                            {CKComponentTapGestureAttribute(@selector(actionChat:))}
                        } size:{} style:{
                            .direction = CKStackLayoutDirectionHorizontal,
                            .alignItems = CKStackLayoutAlignItemsStretch
                        }
                       children:{
                           {
                               .flexGrow = YES,
                               .component = [CKStackLayoutComponent newWithView:{} size:{} style:{
                                   .direction = CKStackLayoutDirectionVertical,
                                   .alignItems = CKStackLayoutAlignItemsStretch
                               }
                               children:body] // timestamp & content
                           }, {
                               [CKStackLayoutComponent newWithView:{} size:{} style:{
                                   .direction = CKStackLayoutDirectionVertical,
                                   .alignItems = CKStackLayoutAlignItemsStretch
                               }
                               children:{
                                   {[CKInsetComponent
                                     newWithInsets:{.left = 0, .right = 12, .top = 7, .bottom = 12}
                                     component:
                                         [CKImageComponent newWithImage:[context imageNamed:@"button_chat"] size:{
                                           .height = 30,
                                           .width = 30,
                                       }]
                                     ]},
                                   {
                                        .flexGrow = YES,
                                       .component = [CKComponent newWithView:{} size:{}],
                                   }
                               }]
                           }
                       }]
                    }
                }]
             background:
                [CKComponent
                newWithView:{
                    [UIView class],
                    {
                        {@selector(setBackgroundColor:), [UIColor whiteColor]},
                        {@selector(setContentMode:), @(UIViewContentModeScaleAspectFill)},
                        {@selector(setClipsToBounds:), @YES},
                    }
                }
                size:{}]
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
