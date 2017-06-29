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

#import "Send.h"
#import "SendCardComponentController.h"
#import "SendCardComponent.h"
#import "SendToInputComponent.h"
#import "TextInputComponent.h"
#import "UIColor+Hex.h"
#import "RgManager.h"
#import "RingKit.h"



@implementation SendCardComponentController

@synthesize state;

- (void)didMount {
	[super didMount];
	[self setState:[NSMutableDictionary dictionaryWithDictionary:@{
		@"enable_send": @NO,
		@"message": @"",
		@"to": @"",
	}]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextViewTextDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetSend:) name:kRgSendComponentReset object:nil];
}

- (void)didUnmount {
	[super didUnmount];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSendComponentReset object:nil];
}

- (BOOL)enableSend
{
	SendCardComponent* sc = (SendCardComponent*)self.component;
	Send* send = sc.send;
	NSDictionary* data = send.data;
	NSMutableDictionary* st = [self state];
	//NSLog(@"Current: %ld %ld", [st[@"message"] length], [st[@"to"] length]);
	
	// This code is copied into the actual component
	BOOL enable = NO;
	if ((data[@"send_media"] != nil) && ([st[@"to"] length] > 0))
	{
		enable = YES;
	}
	else if (([st[@"message"] length] > 0) && ([st[@"to"] length] > 0))
	{
		enable = YES;
	}
	st[@"enable_send"] = [NSNumber numberWithBool:enable];
	//NSLog(@"Send enabled: %@", st);
	return enable;
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
	}
	BOOL is_enabled = [[self state][@"enable_send"] boolValue];
	BOOL now_enabled = [self enableSend];
	BOOL changed = ((! is_enabled) && now_enabled) || ((! now_enabled) && is_enabled);
	__block NSMutableDictionary *st = [self state];
	if (changed)
	{
		NSLog(@"Enabled Send Changed 1: %@", [self state]);
		[self.component updateState:^(id oldState){
			return st;
		} mode:CKUpdateModeAsynchronous];
	}
	//NSLog(@"Tag: %@ - Text: %@", [NSNumber numberWithInteger:tag], text);
}

/*- (void)updateToState:(NSNotification *)notif {
    [self state][@"to"] = notif.userInfo[@"to"];
    BOOL is_enabled = [[self state][@"enable_send"] boolValue];
    BOOL now_enabled = [self enableSend];
    BOOL changed = ((! is_enabled) && now_enabled) || ((! now_enabled) && is_enabled);
    __block NSMutableDictionary *st = [self state];
    if (changed)
    {
        [self.component updateState:^(id oldState){
            return st;
        } mode:CKUpdateModeAsynchronous];
    }
}*/

- (void)resetSend:(NSNotification *)notif
{
	[self setState:[NSMutableDictionary dictionaryWithDictionary:@{
		@"enable_send": @NO,
		@"message": @"",
		@"to": @"",
	}]];
	__block NSMutableDictionary *st = [self state];
	[self.component updateState:^(id oldState){
		return st;
	} mode:CKUpdateModeAsynchronous];
}

- (void)actionSend:(CKButtonComponent *)sender
{
	//NSLog(@"Send: %@", [self state]);
	SendCardComponent* sc = (SendCardComponent*)self.component;
	Send* obj = sc.send;
	NSDictionary *msgdata = [self state];
	if ([msgdata[@"enable_send"] boolValue])
	{
        if ([RKAddress validAddress:msgdata[@"to"]])
        {
            [obj sendMessage:msgdata];
        }
        else
        {
            [self resetSend:nil];
//          [[NSNotificationCenter defaultCenter] postNotificationName:kRgSendComponentReset object:nil];
        }
	}
}

- (void)actionAddContact:(CKButtonComponent *)sender
{
	SendCardComponent* sc = (SendCardComponent*)self.component;
	Send* obj = sc.send;
	[obj showContactSelect];
}

- (void)actionMediaRemove:(CKButtonComponent *)sender
{
	//NSLog(@"%s", __PRETTY_FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:kRgSendComponentRemoveMedia object:nil];
}

- (void)actionMediaTap:(CKButtonComponent *)sender
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	SendCardComponent* sc = (SendCardComponent*)self.component;
	[sc.send showVideoMedia];
}

- (void)actionImageTap:(CKButtonComponent *)sender
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	SendCardComponent* sc = (SendCardComponent*)self.component;
	[sc.send showImageMedia];
}

@end

