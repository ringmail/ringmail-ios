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

#import "MainCardComponent.h"
#import "MainCardComponentController.h"
#import "CKComponentInternal.h"

@implementation MainCardComponentController

- (void)didSwipeLeft:(CKComponent *)component gesture:(UISwipeGestureRecognizer *)gesture
{
    NSLog(@"swipe left");
    
    /*UIView* view = [component viewForAnimation];
    CGRect fr = view.frame;
    fr.origin.x = -50;
    [view setFrame:fr];*/
    
    MainCardComponent* mc = (MainCardComponent*)component;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RgMainCardRemove" object:self userInfo:@{@"index": [[mc cardData] objectForKey:@"index"]}];

    //frame.origin.x += [gesture translationInView:gesture.view.superview].x;
    //gesture.view.frame = frame;
    //[gesture setTranslation:CGPointZero inView:gesture.view.superview];
    
}

- (void)didSwipeRight:(CKComponent *)component gesture:(UISwipeGestureRecognizer *)gesture
{
    NSLog(@"swipe right");
    
    UIView* view = [component viewForAnimation];
    CGRect fr = view.frame;
    fr.origin.x = 0;
    [view setFrame:fr];
    
    //frame.origin.x += [gesture translationInView:gesture.view.superview].x;
    //gesture.view.frame = frame;
    //[gesture setTranslation:CGPointZero inView:gesture.view.superview];
    
}

@end

