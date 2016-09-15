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
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	CGFloat screenWidth = screenRect.size.width;
	CGFloat itemWidth = screenWidth / 2;
	CGFloat circleWidth = itemWidth - 30;
	CGFloat iconTop = (circleWidth / 4) - 15;
	CGFloat countTop = (3 * (circleWidth / 4)) - 10;
	
	UIImage *image;
	
   	// Get the size
    CGSize canvasSize = CGSizeMake(circleWidth, circleWidth);
    CGFloat scale = [UIScreen mainScreen].scale;

    // Resize for retina with the scale factor
    //canvasSize.width *= scale;
    //canvasSize.height *= scale;

    // Create the context
	//UIGraphicsBeginImageContext(canvasSize);
	UIGraphicsBeginImageContextWithOptions(canvasSize, NO, scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    // setup drawing attributes
    //CGContextSetLineWidth(ctx, 1.0 * scale);
    CGContextSetLineWidth(ctx, 1.0);
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithHex:@"#d4d5d7"].CGColor);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);

    // setup the circle size
    CGRect circleRect = CGRectMake( 2, 2, canvasSize.width - 4, canvasSize.height - 4 );
    circleRect = CGRectInset(circleRect, 0, 0);

    // Draw the Circle
    CGContextFillEllipseInRect(ctx, circleRect);
    CGContextStrokeEllipseInRect(ctx, circleRect);

	// Create Image
	image = UIGraphicsGetImageFromCurrentImageContext();
	
    HashtagCategoryCardComponent *c = [super newWithComponent:
        [CKStackLayoutComponent newWithView:{
            [UIView class],
            {CKComponentTapGestureAttribute(@selector(actionSelect:))}
		} size:{
			.width = itemWidth - 10,
			.height = itemWidth - 10,
		} style:{
            .direction = CKStackLayoutDirectionVertical,
            .alignItems = CKStackLayoutAlignItemsStretch
        }
        children:{
			{[CKInsetComponent
              newWithInsets:{.left = 10, .right = 10, .top = 10, .bottom = 10}
              component:
				 [CKBackgroundLayoutComponent newWithComponent:
					[CKBackgroundLayoutComponent newWithComponent:
                        [CKBackgroundLayoutComponent newWithComponent:
    						[CKStackLayoutComponent newWithView:{} size:{.height = itemWidth - 30} style:{
    							.direction = CKStackLayoutDirectionVertical,
    							.alignItems = CKStackLayoutAlignItemsStretch
    						}
    						children:{
    							{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
    							{[CKLabelComponent newWithLabelAttributes:{
    								  .string = [data objectForKey:@"name"],
    								  .font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16],
    								  .color = [UIColor colorWithHex:[data objectForKey:@"color"]],
    								  .alignment = NSTextAlignmentCenter,
    							  }
    							  viewAttributes:{
    								  {@selector(setBackgroundColor:), [UIColor clearColor]},
    								  {@selector(setUserInteractionEnabled:), @NO},
    							  }
    							  size:{.width = itemWidth - 30}]},
    							{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
    						}]
                        	background:
							[CKInsetComponent
								newWithInsets:{.left = INFINITY, .right = INFINITY, .top = iconTop, .bottom = INFINITY}
								component:
                                    [CKNetworkImageComponent newWithURL:data[@"image_url"]
                                        imageDownloader:context.imageDownloader
                                        scenePath:nil size:{ 40, 40 } options:{} attributes:{}]
							]
						]
						background:
							[CKInsetComponent
								newWithInsets:{.left = INFINITY, .right = INFINITY, .top = countTop, .bottom = INFINITY}
								component:
                                   [CKLabelComponent newWithLabelAttributes:{
        								  .string = [data objectForKey:@"count"],
        								  .font = [UIFont fontWithName:@"HelveticaNeue" size:13],
        								  .color = [UIColor colorWithHex:@"#999999"],
        								  .alignment = NSTextAlignmentCenter,
        							  }
        							  viewAttributes:{
        								  {@selector(setBackgroundColor:), [UIColor clearColor]},
        								  {@selector(setUserInteractionEnabled:), @NO},
        							  }
        							  size:{}]
							]
						]
					background:[CKImageComponent newWithImage:image]
				]
			]}
            /*{[CKInsetComponent
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
                                  .font = [UIFont fontWithName:@"HelveticaNeue" size:18],
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
			}]}*/
        }]
    ];
    [c setCardData:data];
    return c;
}

- (void)actionSelect:(CKButtonComponent *)sender
{
    //Card *card = [[Card alloc] initWithData:[self cardData] header:[NSNumber numberWithBool:NO]];
    //[card showMessages];
    NSLog(@"Selected: %@", [[self cardData] objectForKey:@"name"]);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RgHashtagDirectoryUpdatePath" object:self userInfo:@{
        @"category_id":[[self cardData] objectForKey:@"id"]
    }];
}

@end
