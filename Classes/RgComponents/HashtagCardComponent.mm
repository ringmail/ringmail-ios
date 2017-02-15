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

#import "HashtagCardComponent.h"
#import "Card.h"

#import "CardContext.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "UIColor+Hex.h"

@implementation HashtagCardComponent

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
    CKComponentScope scope(self, [data objectForKey:@"session_tag"]);
	//NSLog(@"Component Data: %@", data);
    UIImage *cardImage = [data objectForKey:@"image"];
    cardImage = [cardImage thumbnailImage:80 transparentBorder:0 cornerRadius:8 interpolationQuality:kCGInterpolationHigh];
	
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
	
	CKComponentViewConfiguration scfg;
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
	}
	
    HashtagCardComponent *c = [super newWithView:scfg component:
        [CKInsetComponent
        // Left and right inset of 30pts; centered vertically:
        newWithInsets:{.left = 0, .right = 0, .top = 0, .bottom = 0}
        component:
            [CKBackgroundLayoutComponent
            newWithComponent:
                [CKStackLayoutComponent newWithView:vcfg size:{} style:{
                    .direction = CKStackLayoutDirectionVertical,
                    .alignItems = CKStackLayoutAlignItemsStretch
                }
                children:{
                    {[CKInsetComponent
                      newWithInsets:{.left = 20, .right = 10, .top = 5, .bottom = 5}
                      component:
                          [CKStackLayoutComponent newWithView:{} size:{.height = 40} style:{
                            .direction = CKStackLayoutDirectionHorizontal,
                            .alignItems = CKStackLayoutAlignItemsStretch
                          }
                          children:{
                              {
                                  [CKButtonComponent newWithTitles:{} titleColors:{} images:{
                                      {UIControlStateNormal,cardImage},
                                      } backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionGo:) size:{.height = 40, .width = 40} attributes:{} accessibilityConfiguration:{}],
                              }, {
                                  .flexGrow = YES,
                                  .component = [CKInsetComponent
                                   newWithInsets:{.left = 7, .right = 5, .top = INFINITY, .bottom = INFINITY}
                                   component:
                                         [CKStackLayoutComponent newWithView:{
                                            [UIView class],
                                            {CKComponentTapGestureAttribute(@selector(actionGo:))}
                                         } size:{} style:{}
                                            children:{
                                              {
                                                 [CKInsetComponent
                                                     newWithInsets:{.left = 0, .right = 10, .top = 4, .bottom = 0}
                                                     component:
                                                          [CKLabelComponent
                                                          newWithLabelAttributes:{
                                                              .string = [data objectForKey:@"label"],
                                                              .font = [UIFont fontWithName:@"SFUIText-Medium" size:17],
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
                                      /*{
                                          [CKInsetComponent
                                           newWithInsets:{.left = 0, .right = 0, .top = INFINITY, .bottom = INFINITY}
                                           component:
                                              [CKButtonComponent newWithTitles:{} titleColors:{} images:{
                                                      {UIControlStateNormal,[context imageNamed:@"button_chat"]},
                                                  } backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionChat:) size:{.height = 30, .width = 30} attributes:{} accessibilityConfiguration:{}]
                                           ]
                                      },*/
                                      {
                                          [CKInsetComponent
                                           newWithInsets:{.left = 12, .right = 8, .top = INFINITY, .bottom = INFINITY}
                                           component:
                                              [CKButtonComponent newWithTitles:{} titleColors:{} images:{
                                                      {UIControlStateNormal,[UIImage imageNamed:@"explore_hashtag_categories_rm_icon@3x.png"]},
                                                  } backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionGo:) size:{.height = 30, .width = 30} attributes:{} accessibilityConfiguration:{}]
                                           ]
                                      },
                                  }]
                              }
                          }]
                      ]},
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

/*static CKComponent *lineComponent()
{
    return [CKComponent
            newWithView:{
                [UIView class],
                {
                    {@selector(setBackgroundColor:), [UIColor colorWithHex:@"#d4d5d7"]},
                }
            }
            size:{.height = 1 / [UIScreen mainScreen].scale}];
}*/

- (void)actionChat:(CKButtonComponent *)sender
{
    Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    [card showMessages];
}

- (void)actionGo:(CKButtonComponent *)sender
{
    Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    [card gotoHashtag];
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
