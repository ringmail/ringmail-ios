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

- (void)startCall
{
    NSString *address = [_data objectForKey:@"session_tag"];
    NSString *displayName;
    ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
    if (contact) {
        displayName = [FastAddressBook getContactDisplayName:contact];
    }
    if ([address rangeOfString:@"@"].location != NSNotFound)
    {
        displayName = [NSString stringWithString:address];
        address = [RgManager addressToSIP:address];
        NSLog(@"New Address: %@", address);
    }
    [[LinphoneManager instance] call:address displayName:displayName transfer:FALSE];
}

@end
