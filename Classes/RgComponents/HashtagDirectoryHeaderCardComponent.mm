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

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
    float screenWidth = [[UIScreen mainScreen] bounds].size.width;
    HashtagDirectoryHeaderCardComponent *c = [super newWithComponent:
        [CKStackLayoutComponent newWithView:{} size:{.width=screenWidth} style:{
			.direction = CKStackLayoutDirectionVertical,
		}
		children:{
            {[CKInsetComponent
                 newWithInsets:{.top = 20, .bottom = 5}
                 component:
                    [CKStackLayoutComponent newWithView:{} size:{.height = 171, .width=screenWidth} style:{
            			.direction = CKStackLayoutDirectionHorizontal,
            			.alignItems = CKStackLayoutAlignItemsStretch
            		}
            		children:{
            			{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
            			{[CKImageComponent newWithImage:[UIImage imageNamed:@"ringmail_astronaut.png"] size:{.width=175, .height=171}]},
            			{.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]},
            		}]
            ]},
            {[CKLabelComponent
                 newWithLabelAttributes:{
                     .string = data[@"text"],
                     .font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16],
                     .alignment = NSTextAlignmentCenter,
                     .color = [UIColor colorWithHex:@"#33362f"],
                 }
                 viewAttributes:{
                     {@selector(setBackgroundColor:), [UIColor clearColor]},
                     {@selector(setUserInteractionEnabled:), @NO},
                 }
                 size:{.width=screenWidth}]}
        }]
	];
    [c setCardData:data];
    return c;
}

@end
