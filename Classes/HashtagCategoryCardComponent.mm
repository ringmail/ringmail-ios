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

#import "HashtagCategoryCardComponent.h"
#import "Card.h"

#import "CardContext.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "UIColor+Name.h"
#import "UIColor+Hex.h"

#import "RgCustomView.h"

@implementation HashtagCategoryCardComponent

@synthesize cardData;

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
    UIImage *cardImage = [context imageNamed:@"Card1"];
    cardImage = [cardImage thumbnailImage:80 transparentBorder:0 cornerRadius:40 interpolationQuality:kCGInterpolationHigh];
    
    CKComponentViewConfiguration vcfg = {
        [UIView class],
        {
            CKComponentTapGestureAttribute(@selector(actionSelect:)),
            {@selector(setBackgroundColor:), [UIColor whiteColor]},
            {CKComponentViewAttribute::LayerAttribute(@selector(setBorderColor:)), (id)[[UIColor colorWithHex:@"#d4d5d7"] CGColor]},
            {CKComponentViewAttribute::LayerAttribute(@selector(setBorderWidth:)), 1 / [UIScreen mainScreen].scale},
        }
    };
    HashtagCategoryCardComponent *c = [super newWithComponent:
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
                                  .flexGrow = YES,
                                  .component = [CKInsetComponent
                                   newWithInsets:{.left = 7, .right = 5, .top = INFINITY, .bottom = INFINITY}
                                   component:
                                      [CKLabelComponent
                                      newWithLabelAttributes:{
                                          .string = [data objectForKey:@"name"],
                                          .font = [UIFont fontWithName:@"Futura-CondensedMedium" size:20],
                                          .color = [UIColor colorWithHex:@"#33362f"],
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
                                           newWithInsets:{.left = 15, .right = 7, .top = INFINITY, .bottom = INFINITY}
                                           component:
                                               [CKImageComponent newWithImage:[UIImage imageNamed:@"ringmail_forward.png"] size:{
                                                  .height = 16,
                                                  .width = 9,
                                              }]
                                           ]
                                      },
                                  }]
                              }
                          }]
                      ]},
					{lineComponent()},
					{[CKComponent newWithView:{
						{[RgCustomView class]},
						{
							{@selector(setupView:), @{
								@"pattern": data[@"pattern"],
								@"color": data[@"color"],
							}},
						}
					} size:{
						.height = 15
					}]}
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

- (void)actionSelect:(CKButtonComponent *)sender
{
    //Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    //[card showMessages];
    NSLog(@"Selected: %@", [[self cardData] objectForKey:@"name"]);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RgHashtagDirectoryUpdatePath" object:self userInfo:@{
        @"path":[[self cardData] objectForKey:@"name"]
    }];
}

@end
