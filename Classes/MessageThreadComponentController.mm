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

#import "CKComponentSubclass.h"
#import "CKComponentInternal.h"
#import "MessageThread.h"
#import "MessageThreadContext.h"
#import "MessageThreadComponent.h"
#import "MessageThreadComponentController.h"
#import "RingKit.h"

#import "UIColor+Hex.h"

@implementation MessageThreadComponentController

- (void)didPan:(MessageThreadComponent *)component gesture:(UIPanGestureRecognizer*)gesture
{
    UIView* view = [component viewForAnimation];
    CGPoint pt = [gesture translationInView:view];
    NSLog(@"%@", NSStringFromCGPoint(pt));
    CGFloat x = pt.x;
    if (x <= 0 && x >= -66)
    {
        CGRect fr = view.frame;
        fr.origin.x = x;
        [view setFrame:fr];
    }
}

- (void)didSwipeLeft:(CKComponent *)component gesture:(UISwipeGestureRecognizer *)gesture
{
    UIView* view = [component viewForAnimation];
    CGRect fr = view.frame;
    //NSLog(@"swipe left, %f", fr.origin.y);
    fr.origin.x = -66;
    [view setFrame:fr];

//    if (self.removeButtons == nil)
//    {
//        self.removeButtons = [NSMutableDictionary dictionary];
//    }
    
    MessageThreadComponent* mc = (MessageThreadComponent*)component;
    RKThread* thread = mc.currentThread.data[@"thread"];
    NSLog(@"Button for threadId: %@", thread.threadId);
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = [thread.threadId integerValue];
    //[button addTarget:self action:@selector(removeRow:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"ringmail_delete"] forState:UIControlStateNormal];
    button.contentEdgeInsets = UIEdgeInsetsZero;
    button.imageEdgeInsets = UIEdgeInsetsZero;
    button.backgroundColor = [UIColor colorWithHex:@"#e76864"];
    button.frame = CGRectMake(fr.size.width - 60, 6.0, 54.0, 54.0);
    button.userInteractionEnabled = YES;
    [view.superview addSubview:button];
    //self.removeButtons[session] = button;
}
@end
