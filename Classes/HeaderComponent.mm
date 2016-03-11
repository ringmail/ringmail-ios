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

#import "HeaderComponent.h"

#import "Card.h"
#import "CardContext.h"
#import "UIColor+Hex.h"

@implementation HeaderComponent

+ (instancetype)newWithHeader:(NSString *)header context:(CardContext *)context
{
  return [super newWithComponent:headerComponent(header, context)];
}

static CKComponent *headerComponent(NSString *header, CardContext *context)
{
    return [CKInsetComponent
    // Left and right inset of 30pts; centered vertically:
    newWithInsets:{.top = 10, .bottom = 6}
    component:
        [CKLabelComponent
         newWithLabelAttributes:{
             .string = header,
             .font = [UIFont fontWithName:@"KannadaSangamMN" size:14],
             .alignment = NSTextAlignmentCenter,
             .color = [UIColor colorWithHex:@"#33362f"],
             //.color = [UIColor whiteColor],
         }
         viewAttributes:{
             {@selector(setBackgroundColor:), [UIColor clearColor]},
             {@selector(setUserInteractionEnabled:), @NO},
         }
         size:{}]
    ];
}

@end
