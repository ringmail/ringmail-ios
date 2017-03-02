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

UIImage* getImageDir(float*);
CKComponent* hashtagDirHeaderImgComponent(float*, UIImage*);


+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    
    if ([[data objectForKey:@"text"] isEqual:@"blankTopInset"])
    {
        HashtagDirectoryHeaderCardComponent *c = [super newWithComponent:
        [CKStackLayoutComponent newWithView:{} size:{.width=screenWidth, .height=12} style:{
            .direction = CKStackLayoutDirectionVertical,
        }
        children:{}]
        ];
        
        [c setCardData:data];
         return c;
    }

    UIImage* headerImg = getImageDir(&screenWidth);
    
    HashtagDirectoryHeaderCardComponent *c = [super newWithComponent:
        [CKStackLayoutComponent newWithView:{} size:{.width=screenWidth} style:{
			.direction = CKStackLayoutDirectionVertical,
		}
		children:{
            {[CKInsetComponent
                 newWithInsets:{.top = 0, .bottom = 0}
                 component:
                    [CKStackLayoutComponent newWithView:{} size:{.height = headerImg.size.height, .width=screenWidth} style:{
            			.direction = CKStackLayoutDirectionHorizontal,
            			.alignItems = CKStackLayoutAlignItemsStretch
            		}
            		children:{
            			{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
                        {hashtagDirHeaderImgComponent(&screenWidth,headerImg)},
            			{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
            		}]
            ]},
            {[CKInsetComponent
               newWithInsets:{.left = 20, .right = 20}
               component:
                    [CKLabelComponent
                     newWithLabelAttributes:{
                         .string = data[@"text"],
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


UIImage* getImageDir(float* wIn)
{
    UIImage* tmpImg;
    
    if (*wIn == 320)
        tmpImg = [UIImage imageNamed:@"explore_banner_ip5p@2x.png"];
    else if (*wIn == 375)
        tmpImg = [UIImage imageNamed:@"explore_banner_ip6-7s@2x.png"];
    else if (*wIn == 414)
        tmpImg = [UIImage imageNamed:@"explore_banner_ip6-7p@3x.png"];
    
    return tmpImg;
}


CKComponent* hashtagDirHeaderImgComponent(float* wIn, UIImage* iIn)
{
    return
    [
     CKComponent newWithView:{
         [UIImageView class],
         {
             {@selector(setImage:), iIn},
             {@selector(setContentMode:), @(UIViewContentModeScaleAspectFill)},
         }
     }
     size:{*wIn, *wIn / (iIn.size.width/iIn.size.height)}
     ];
}

@end
