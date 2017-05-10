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

#import "HashtagDirectoryHeaderCardComponent.h"
#import "Card.h"

#import "CardContext.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "UIColor+Name.h"
#import "UIColor+Hex.h"

#import "RgCustomView.h"

#import "ComponentUtilities.h"
#import <stdlib.h>
#import <vector>
#import <algorithm>

@implementation HashtagDirectoryHeaderCardComponent

@synthesize cardData;

CKStackLayoutComponent* hashtagDirHeaderLabelComponent(float*, NSDictionary*);


+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    NSString* hdht = data[@"header_img_ht"];
    
    HashtagDirectoryHeaderCardComponent *c = [super newWithComponent:
        [CKStackLayoutComponent newWithView:{}
        size:{.width=screenWidth}
        style:{.direction = CKStackLayoutDirectionVertical,}
		children:{
            {[CKInsetComponent
                 newWithInsets:{.top = 0, .bottom = 0}
                 component:
                    [CKStackLayoutComponent newWithView:{} size:{.height = [hdht floatValue], .width=screenWidth} style:{
            			.direction = CKStackLayoutDirectionHorizontal,
            			.alignItems = CKStackLayoutAlignItemsStretch
            		}
            		children:{
            			{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
                        {[CKNetworkImageComponent newWithURL:data[@"header_img_url"]
                            imageDownloader:context.imageDownloader
                            scenePath:nil size:{ screenWidth, [hdht floatValue] } options:{} attributes:{}]},
            			{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
            		}]
            ]},
            {hashtagDirHeaderLabelComponent(&screenWidth,data)},
            {[CKInsetComponent
               newWithInsets:{.left = 20, .right = 20}
               component:
                    [CKLabelComponent
                     newWithLabelAttributes:{
                         .string = @"",
                         .font = [UIFont fontWithName:@"SFUIText-Bold" size:19],
                         .alignment = NSTextAlignmentLeft,
                         .color = [UIColor colorWithHex:@"#222222"],
                     }
                     viewAttributes:{
                         {@selector(setBackgroundColor:), [UIColor clearColor]},
                         {@selector(setUserInteractionEnabled:), @NO},
                     }
                     size:{.width=screenWidth}]
            ]}
        }]
	];
    
    [c setCardData:data];
    return c;
}


CKStackLayoutComponent* hashtagDirHeaderLabelComponent(float* wIn, NSDictionary * data)
{
    if (![[data objectForKey:@"parent_name"] isEqual: @""]  && ![[data objectForKey:@"category_name"] isEqual: @""] )
    {
        return
        [
            CKStackLayoutComponent newWithView:
            {
                 [UIView class],
                 {
                     {@selector(setBackgroundColor:), [UIColor whiteColor]},
                     {@selector(setContentMode:), @(UIViewContentModeScaleAspectFill)},
                     {@selector(setClipsToBounds:), @YES},
                 }
            }
            size:{.width=*wIn}
            style:{.direction = CKStackLayoutDirectionVertical,}
            children:{
                {[CKInsetComponent
                newWithInsets:{.left = 20, .right = 0, .top = 23, .bottom = 8}
                component:
                    [CKLabelComponent
                    newWithLabelAttributes:{
                       .string = [data objectForKey:@"category_name"],
                       .font = [UIFont fontWithName:@"SFUIText-SemiBold" size:24],
                       .alignment = NSTextAlignmentLeft,
                       .color = [UIColor colorWithHex:@"#213E87"],
                    }
                    viewAttributes:{
                       {@selector(setBackgroundColor:), [UIColor clearColor]},
                       {@selector(setUserInteractionEnabled:), @NO},
                    }
                    size:{.width=*wIn}]
                ]},
                {[CKInsetComponent
                  newWithInsets:{.left = 20, .right = 0, .top = 0, .bottom = 23}
                  component:
                    [CKLabelComponent newWithLabelAttributes:{
                        .string = [data objectForKey:@"parent_name"],
                        .color = [UIColor colorWithHex:@"#222222"],
                        .font = [UIFont fontWithName:@"SFUIText-Light" size:19],
                        .alignment = NSTextAlignmentLeft,
                    }
                    viewAttributes:{
                       {@selector(setBackgroundColor:), [UIColor clearColor]},
                       {@selector(setUserInteractionEnabled:), @NO},
                    }
                    size:{.width = *wIn}]
                ]},
            }
        ];
    }
    else if ([[data objectForKey:@"parent_name"] isEqual: @""] && ![[data objectForKey:@"category_name"] isEqual: @""])
        return
        [
         CKStackLayoutComponent newWithView:
         {
             [UIView class],
             {
                 {@selector(setBackgroundColor:), [UIColor whiteColor]},
                 {@selector(setContentMode:), @(UIViewContentModeScaleAspectFill)},
                 {@selector(setClipsToBounds:), @YES},
             }
         }
         size:{.width=*wIn}
         style:{.direction = CKStackLayoutDirectionVertical,}
         children:{
             {[CKInsetComponent
               newWithInsets:{.left = 20, .right = 0, .top = 23, .bottom = 8}
               component:
               [CKLabelComponent
                newWithLabelAttributes:{
                    .string = [data objectForKey:@"category_name"],
                    .font = [UIFont fontWithName:@"SFUIText-SemiBold" size:24],
                    .alignment = NSTextAlignmentLeft,
                    .color = [UIColor colorWithHex:@"#213E87"],
                }
                viewAttributes:{
                    {@selector(setBackgroundColor:), [UIColor clearColor]},
                    {@selector(setUserInteractionEnabled:), @NO},
                }
                size:{.width=*wIn}]
               ]},
             {[CKInsetComponent
               newWithInsets:{.left = 20, .right = 0, .top = 0, .bottom = 23}
               component:
               [CKLabelComponent newWithLabelAttributes:{
                 .string = @"",
                 .color = [UIColor colorWithHex:@"#222222"],
                 .font = [UIFont fontWithName:@"SFUIText-Light" size:19],
                 .alignment = NSTextAlignmentLeft,
             }
                                         viewAttributes:{
                                             {@selector(setBackgroundColor:), [UIColor clearColor]},
                                             {@selector(setUserInteractionEnabled:), @NO},
                                         }
                                                   size:{.width = *wIn}]
               ]},
         }
         ];
    else
        return 0;
}
    
@end
