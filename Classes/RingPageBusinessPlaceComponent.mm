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

#import "RingPageBusinessPlaceComponent.h"
#import "Card.h"

#import "CardContext.h"

#import "UIColor+Name.h"
#import "UIColor+Hex.h"

#import "RgManager.h"

@implementation RingPageBusinessPlaceComponent

@synthesize data;

+ (instancetype)newWithData:(NSDictionary *)data context:(CardContext *)context
{
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	CGFloat screenWidth = screenRect.size.width;
	NSDictionary *place = data[@"place"];
    
    RingPageBusinessPlaceComponent *c = [super newWithComponent:
        [CKStackLayoutComponent newWithView:{
            [UIView class], {}
        } size:{.width = screenWidth}
        style:{
            .direction = CKStackLayoutDirectionVertical
        }
        children:{
            {[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 5, .bottom = 5} component:
                [CKLabelComponent newWithLabelAttributes:{
                    .string = place[@"name"],
                    .font = [UIFont fontWithName:@"SFUIText-Regular" size:24],
                    .color = [UIColor blackColor],
                    .alignment = NSTextAlignmentLeft,
                }
                viewAttributes:{
                    {@selector(setBackgroundColor:), [UIColor clearColor]},
                    {@selector(setUserInteractionEnabled:), @NO},
                } size:{}]
             ]},
             {[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 5, .bottom = 5} component:
                [CKLabelComponent newWithLabelAttributes:{
                    .string = place[@"address"],
                    .font = [UIFont fontWithName:@"SFUIText-Regular" size:24],
                    .color = [UIColor blackColor],
                    .alignment = NSTextAlignmentLeft,
                }
                viewAttributes:{
                    {@selector(setBackgroundColor:), [UIColor clearColor]},
                    {@selector(setUserInteractionEnabled:), @NO},
                } size:{}]
             ]},
             {[CKInsetComponent newWithInsets:{.left = 10, .right = 10, .top = 5, .bottom = 5} component:
                [CKLabelComponent newWithLabelAttributes:{
                    .string = place[@"locality"],
                    .font = [UIFont fontWithName:@"SFUIText-Regular" size:24],
                    .color = [UIColor blackColor],
                    .alignment = NSTextAlignmentLeft,
                }
                viewAttributes:{
                    {@selector(setBackgroundColor:), [UIColor clearColor]},
                    {@selector(setUserInteractionEnabled:), @NO},
                } size:{}]
             ]},
        }]
    ];
    [c setData:data];
    return c;
}

- (void)actionSelect:(CKButtonComponent *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kRgHashtagDirectoryUpdatePath object:self userInfo:@{
        @"category_id":[[self data] objectForKey:@"id"]
    }];
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"header"] = @"Hashtag Card";
    dict[@"lSeg"] = @"Categories";
    dict[@"rSeg"] = @"My Activity";
    [[NSNotificationCenter defaultCenter] postNotificationName:kRgNavBarViewChange object:nil userInfo:dict];
}


@end
