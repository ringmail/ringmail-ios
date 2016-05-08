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

#import "Card.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "RgManager.h"

@implementation Card

- (instancetype)initWithData:(NSDictionary *)data
                      header:(NSNumber *)header
{
  if (self = [super init]) {
    _data = [data copy];
    _header = [header copy];
  }
  return self;
}

- (NSNumber*)sessionId
{
    if ([_header boolValue])
    {
        return nil;
    }
    NSNumber *result = [_data objectForKey:@"id"];
    return result;
}

- (void)showMessages
{
    NSString *address = [_data objectForKey:@"session_tag"];
    [[LinphoneManager instance] setChatTag:address];
    [[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE];
}

- (void)startCall:(BOOL)video
{
    NSString *address = [_data objectForKey:@"session_tag"];
    [RgManager startCall:address contact:NULL video:video];
}

- (void)gotoContact
{
	NSLog(@"Goto Contact: %@", _data[@"session_tag"]);
	NSString *addr = _data[@"session_tag"];
    if ([[addr substringToIndex:1] isEqualToString:@"#"])
    {
		NSLog(@"Hashtag: %@", _data[@"session_tag"]);
	}
	else
	{
    	ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:addr];
    	ContactDetailsViewController *controller = DYNAMIC_CAST(
    		[[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE],
    		ContactDetailsViewController);
      	if (controller != nil) {
        	if (contact)
        	{
        		// Go to Contact details view
           		[controller setContact:contact];
        	}
        	else
        	{
           		[controller newContact:addr];
			}
    	}
	}
}

@end
