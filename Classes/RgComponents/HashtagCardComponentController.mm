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

#import "HashtagCardComponentController.h"
#import "HashtagCardComponent.h"
#import "CKComponentInternal.h"
#import "UIColor+Hex.h"
#import "RgManager.h"

@implementation HashtagCardComponentController

- (void)didSwipeLeft:(CKComponent *)component gesture:(UISwipeGestureRecognizer *)gesture
{
    UIView* view = [component viewForAnimation];
    CGRect fr = view.frame;
    //NSLog(@"swipe left, %f", fr.origin.y);
    fr.origin.x = -60;
    [view setFrame:fr];
	
	if (self.removeButtons == nil)
	{
		self.removeButtons = [NSMutableDictionary dictionary];
	}
	
    HashtagCardComponent* mc = (HashtagCardComponent*)component;
	NSNumber *session = [[mc cardData] objectForKey:@"id"];
	//NSLog(@"Button for session id: %@", session);
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.tag = [session integerValue];
    [button addTarget:self action:@selector(removeRow:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"ringmail_delete"] forState:UIControlStateNormal];
    button.contentEdgeInsets = UIEdgeInsetsZero;
    button.imageEdgeInsets = UIEdgeInsetsZero;
    button.backgroundColor = [UIColor colorWithHex:@"#e76864"];
    button.frame = CGRectMake(fr.size.width - 60, 0.0, 60.0, fr.size.height - 10);
    button.userInteractionEnabled = YES;
    [view.superview addSubview:button];
	self.removeButtons[session] = button;
}

- (void)didSwipeRight:(CKComponent *)component gesture:(UISwipeGestureRecognizer *)gesture
{
    //NSLog(@"swipe right");
    UIView* view = [component viewForAnimation];
    CGRect fr = view.frame;
    if (fr.origin.x != 0)
	{
        fr.origin.x = 0;
        [view setFrame:fr];
		
        HashtagCardComponent* mc = (HashtagCardComponent*)component;
    	NSNumber *session = [[mc cardData] objectForKey:@"id"];
		if (self.removeButtons[session] != nil)
		{
			UIButton *btn = self.removeButtons[session];
			[btn removeFromSuperview];
			[self.removeButtons removeObjectForKey:session];
			//NSLog(@"Remove button A: %@", session);
		}
	}
}

- (void)willRemount
{
	[super willRemount];
	HashtagCardComponent* mc = (HashtagCardComponent*)[self component];
	NSNumber *session = [[mc cardData] objectForKey:@"session"];
	//NSLog(@"willRemount: %@", session);
	if (self.removeButtons[session] != nil)
	{
		UIButton *btn = self.removeButtons[session];
		[btn removeFromSuperview];
		[self.removeButtons removeObjectForKey:session];
		//NSLog(@"Remove button B: %@", session);
	}
}

- (void)willUnmount
{
	[super willUnmount];
	HashtagCardComponent* mc = (HashtagCardComponent*)[self component];
	NSNumber *session = [[mc cardData] objectForKey:@"id"];
	//NSLog(@"willUnmount: %@", session);
	if (self.removeButtons[session] != nil)
	{
		UIButton *btn = self.removeButtons[session];
		[btn removeFromSuperview];
		[self.removeButtons removeObjectForKey:session];
		//NSLog(@"Remove button C: %@", session);
	}
}

- (void)removeRow:(id)sender
{
	UIButton *btn = sender;
	//NSLog(@"Delete: %@", [NSNumber numberWithInteger:btn.tag]);
	[[NSNotificationCenter defaultCenter] postNotificationName:kRgMainRemove object:self userInfo:@{
		@"id":[NSNumber numberWithInteger:btn.tag],
	}];
}

@end

