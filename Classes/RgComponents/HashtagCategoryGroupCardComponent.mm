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

#import "HashtagCategoryGroupCardComponent.h"
#import "HashtagCategoryCardComponent.h"
#import "Card.h"

#import "CardContext.h"

#import "UIColor+Name.h"
#import "UIColor+Hex.h"

#import "ComponentUtilities.h"
#import <stdlib.h>
#import <vector>
#import <algorithm>

@implementation HashtagCategoryGroupCardComponent

@synthesize cardData;

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	CGFloat screenWidth = screenRect.size.width;
	CGFloat itemWidth = screenWidth / 2;
	std::vector<CKStackLayoutComponentChild> children;
	NSArray *group = data[@"group"];
	for (HashtagCategoryGroupCardComponent* card in group)
	{
		children.push_back({
			//.flexGrow = NO,
			.component = card,
		});
	}
    HashtagCategoryGroupCardComponent *c = [super newWithComponent:
		[CKInsetComponent newWithInsets:{
			.left = 8,
			.right = 8,
			.top = 0,
			.bottom = 0,
		} component:
    		[CKStackLayoutComponent newWithView:{} size:{.height = itemWidth - 10} style:{
    			.direction = CKStackLayoutDirectionHorizontal,
    			.alignItems = CKStackLayoutAlignItemsStretch
    		} children:children]
		]
	];
	children.push_back({.flexGrow = YES, .component = [CKComponent newWithView:{} size:{}]});
	
//              {
//                  .flexGrow = YES,
//                  .component = [CKInsetComponent
//                   newWithInsets:{.left = 7, .right = 5, .top = INFINITY, .bottom = INFINITY}
//                   component:
// 	
    [c setCardData:data];
    return c;
}

@end
