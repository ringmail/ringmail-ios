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
#import "UIColor+Hex.h"

@implementation MainCardComponentController

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
	
    MainCardComponent* mc = (MainCardComponent*)component;
	NSNumber *index = [[mc cardData] objectForKey:@"index"];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.tag = [index integerValue];
    [button addTarget:self action:@selector(removeRow:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"ringmail_edit-cancel"] forState:UIControlStateNormal];
    button.contentEdgeInsets = UIEdgeInsetsZero;
    button.imageEdgeInsets = UIEdgeInsetsZero;
    button.backgroundColor = [UIColor colorWithHex:@"#e76864"];
    button.frame = CGRectMake(fr.size.width - 60, 0.0, 60.0, fr.size.height - 10);
    button.userInteractionEnabled = YES;
    [view.superview addSubview:button];
	self.removeButtons[index] = button;
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
		
        MainCardComponent* mc = (MainCardComponent*)component;
    	NSNumber *index = [[mc cardData] objectForKey:@"index"];
		if (self.removeButtons[index] != nil)
		{
			UIButton *btn = self.removeButtons[index];
			[btn removeFromSuperview];
			[self.removeButtons removeObjectForKey:index];
			//NSLog(@"Remove button A: %@", index);
		}
	}
}

- (void)willRemount
{
	[super willRemount];
	MainCardComponent* mc = (MainCardComponent*)[self component];
	NSNumber *index = [[mc cardData] objectForKey:@"index"];
	//NSLog(@"willRemount: %@", index);
	if (self.removeButtons[index] != nil)
	{
		UIButton *btn = self.removeButtons[index];
		[btn removeFromSuperview];
		[self.removeButtons removeObjectForKey:index];
		//NSLog(@"Remove button B: %@", index);
	}
}

- (void)willUnmount
{
	[super willUnmount];
	MainCardComponent* mc = (MainCardComponent*)[self component];
	NSNumber *index = [[mc cardData] objectForKey:@"index"];
	//NSLog(@"willUnmount: %@", index);
	if (self.removeButtons[index] != nil)
	{
		UIButton *btn = self.removeButtons[index];
		[btn removeFromSuperview];
		[self.removeButtons removeObjectForKey:index];
		//NSLog(@"Remove button C: %@", index);
	}
}

- (void)removeRow:(id)sender
{
	UIButton *btn = sender;
	NSLog(@"Delete: %@", [NSNumber numberWithInteger:btn.tag]);
}

@end

