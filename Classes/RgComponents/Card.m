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
    [[LinphoneManager instance] setChatSession:_data[@"id"]];
    [[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE];
}

- (void)startCall:(BOOL)video
{
    NSNumber *session = [_data objectForKey:@"id"];
	NSDictionary *sdata = [[[LinphoneManager instance] chatManager] dbGetSessionData:session];
	ABRecordRef contact = NULL;
	if (! [sdata[@"contact_id"] isKindOfClass:[NSNull class]])
	{
		contact = [[[LinphoneManager instance] fastAddressBook] getContactById:sdata[@"contact_id"]];
	}
    [RgManager startCall:sdata[@"session_tag"] contact:contact video:video];
}

- (void)gotoContact
{
	NSLog(@"Goto Contact: %@", _data[@"session_tag"]);
	NSString *addr = _data[@"session_tag"];
    if ([addr length] > 0 && [[addr substringToIndex:1] isEqualToString:@"#"])
    {
		NSLog(@"Hashtag: %@", _data[@"session_tag"]);
	}
	else
	{
        NSNumber *session = [_data objectForKey:@"id"];
    	NSDictionary *sdata = [[[LinphoneManager instance] chatManager] dbGetSessionData:session];
    	ABRecordRef contact = NULL;
    	if (! [sdata[@"contact_id"] isKindOfClass:[NSNull class]])
    	{
    		contact = [[[LinphoneManager instance] fastAddressBook] getContactById:sdata[@"contact_id"]];
    	}
        else
        {
            contact = [[[LinphoneManager instance] fastAddressBook] getContact:sdata[@"session_tag"]];
        }
        if (contact)
        {
           	ContactDetailsViewController *controller = DYNAMIC_CAST(
                [[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE],
                ContactDetailsViewController);
            if (controller != nil)
            {
        		// Go to Contact details view
           		[controller setContact:contact];
            }
        }
        else
        {
            [[PhoneMainView instance] promptNewOrEdit:addr];
        }
	}
}

- (void)gotoHashtag
{
    NSString *address = [_data objectForKey:@"session_tag"];
    [RgManager startHashtag:address];
}

@end
