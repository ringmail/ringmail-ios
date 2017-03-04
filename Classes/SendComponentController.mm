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

#import "CKComponentInternal.h"
#import "CKComponentSubclass.h"

#import "SendComponentController.h"
#import "SendComponent.h"
#import "SendToInputComponent.h"
#import "TextInputComponent.h"
#import "UIColor+Hex.h"

@implementation SendComponentController

@synthesize state;

- (void)didMount {
	[super didMount];
	[self setState:[NSMutableDictionary dictionaryWithDictionary:@{
		@"enable_send": @NO,
		@"message": @"",
	}]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)didUnmount {
	[super didUnmount];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
}

- (void)textFieldDidChange:(NSNotification *)notif {
	NSInteger tag = [((UIView*)notif.object) tag];
	NSString *text = [notif.object text];
	if (tag == 0) // To
	{
		[self state][@"to"] = text;
	}
	else if (tag == 1) // Message
	{
		[self state][@"message"] = text;
		__block NSMutableDictionary *st = [self state];
		BOOL changed = NO;
		if ([text length] > 0)
		{
			if (! [st[@"enable_send"] boolValue])
			{
				st[@"enable_send"] = @YES;
				changed = YES;
			}
		}
		else
		{
			if ([st[@"enable_send"] boolValue])
			{
				st[@"enable_send"] = @NO;
				changed = YES;
			}
		}
		if (changed)
		{
			[self.component updateState:^(id oldState){
				return st;
			} mode:CKUpdateModeAsynchronous];
		}
	}
	//NSLog(@"Tag: %@ - Text: %@", [NSNumber numberWithInteger:tag], text);
}

- (void)actionSend:(CKButtonComponent *)sender
{
	NSLog(@"Send: %@", [self state]);
}

@end

