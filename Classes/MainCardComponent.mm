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

#import "CardContext.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "UIColor+Hex.h"

@implementation MainCardComponent

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
    UIImage *cardImage = [context imageNamed:@"Card1"];
    cardImage = [cardImage thumbnailImage:40 transparentBorder:0 cornerRadius:20 interpolationQuality:kCGInterpolationHigh];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIFont fontWithName:@"KannadaSangamMN" size:14] forKey:NSFontAttributeName];
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:[data objectForKey:@"last_message"] attributes:attrsDictionary];
    
    NSNumber *timeCall = [data objectForKey:@"call_time"];
    NSNumber *timeChat = [data objectForKey:@"last_time"];
    NSNumber *timeLatest = nil;
    if (timeCall != nil && ! [timeCall isEqual:[NSNull null]])
    {
        if (timeChat != nil && ! [timeChat isEqual:[NSNull null]])
        {
            if (timeChat > timeCall)
            {
                timeLatest = timeChat;
            }
            else
            {
                timeLatest = timeCall;
            }
        }
        else
        {
            timeLatest = timeCall;
        }
    }
    else if (timeChat != nil && ! [timeChat isEqual:[NSNull null]])
    {
        timeLatest = timeChat;
    }
    NSString *latest = @"";
    if ([timeLatest boolValue])
    {
        //NSDate *dateLatest = [NSDate dateWithTimeIntervalSince1970:[timeLatest doubleValue]];
        NSDate *dateLatest;
        dateLatest = [data objectForKey:@"timestamp"]; // replace with session timestamp
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
    }
    
    // Cheat and get a width constraint for the card text box
    CGFloat textWidth = [[UIScreen mainScreen] bounds].size.width - 100;
    
    return [super newWithComponent:
        [CKInsetComponent
        // Left and right inset of 30pts; centered vertically:
        newWithInsets:{.left = 10, .right = 10, .top = 0, .bottom = 10}
        component:
            [CKBackgroundLayoutComponent
            newWithComponent:
                [CKStackLayoutComponent newWithView:{
                    [UIView class],
                    {
                        {@selector(setBackgroundColor:), [UIColor whiteColor]},
                        {CKComponentViewAttribute::LayerAttribute(@selector(setShadowOpacity:)),0.8f},
                        {CKComponentViewAttribute::LayerAttribute(@selector(setShadowRadius:)),@3},
                        {CKComponentViewAttribute::LayerAttribute(@selector(setShadowColor:)),(id)[[UIColor colorWithHex:@"#0077c3"] CGColor]},
                        {CKComponentViewAttribute::LayerAttribute(@selector(setShadowOffset:)),[NSValue valueWithCGSize:CGSizeMake(2, 2)]}
                    }
                } size:{} style:{
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
                                  [CKImageComponent newWithImage:cardImage size:{
                                      .height = 40,
                                      .width = 40,
                                  }],
                              }, {
                                  .flexGrow = YES,
                                  .component = [CKInsetComponent
                                   newWithInsets:{.left = 7, .right = 5, .top = INFINITY, .bottom = INFINITY}
                                   component:
                                      [CKLabelComponent
                                      newWithLabelAttributes:{
                                          .string = [data objectForKey:@"session_tag"],
                                          .font = [UIFont fontWithName:@"Futura-CondensedMedium" size:16],
                                      }
                                      viewAttributes:{
                                          {@selector(setBackgroundColor:), [UIColor clearColor]},
                                          {@selector(setUserInteractionEnabled:), @NO},
                                      }
                                      size:{}]
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
                                              [CKImageComponent newWithImage:[context imageNamed:@"button_video"] size:{
                                                  .height = 27,
                                                  .width = 27,
                                              }]
                                           ]
                                      }, {
                                          [CKInsetComponent
                                           newWithInsets:{.left = 10, .right = 0, .top = INFINITY, .bottom = INFINITY}
                                           component:
                                              [CKImageComponent newWithImage:[context imageNamed:@"button_call"] size:{
                                                  .height = 27,
                                                  .width = 27,
                                              }]
                                           ]
                                      }, {
                                          [CKInsetComponent
                                           newWithInsets:{.left = 10, .right = 5, .top = INFINITY, .bottom = INFINITY}
                                           component:
                                              [CKImageComponent newWithImage:[context imageNamed:@"button_chat"] size:{
                                                  .height = 27,
                                                  .width = 27,
                                              }]
                                           ]
                                      },
                                  }]
                              }
                          }]
                      ]},
                    {lineComponent()},
                    {
                        [CKStackLayoutComponent newWithView:{} size:{} style:{
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
                               children:{
                                   {[CKInsetComponent
                                     newWithInsets:{.left = 20, .right = 0, .top = 15, .bottom = 0}
                                     component:
                                     [CKLabelComponent
                                      newWithLabelAttributes:{
                                          .string = latest,
                                          .font = [UIFont fontWithName:@"Futura-CondensedMedium" size:12],
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
                               }]
                           }, {
                               [CKStackLayoutComponent newWithView:{} size:{} style:{
                                   .direction = CKStackLayoutDirectionVertical,
                                   .alignItems = CKStackLayoutAlignItemsStretch
                               }
                               children:{
                                   {[CKInsetComponent
                                     newWithInsets:{.left = 0, .right = 10, .top = 10, .bottom = 0}
                                     component:
                                       [CKImageComponent newWithImage:[context imageNamed:@"image_quote"] size:{
                                           .height = 27,
                                           .width = 27,
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
}

static CKComponent *lineComponent()
{
    return [CKComponent
            newWithView:{
                [UIView class],
                {
                    {@selector(setBackgroundColor:), [UIColor blackColor]},
                }
            }
            size:{.height = 1 / [UIScreen mainScreen].scale}];
}

@end
