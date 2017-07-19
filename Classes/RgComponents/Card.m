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

- (instancetype)initWithData:(NSDictionary *)data header:(NSNumber *)header
{
  if (self = [super init]) {
    _data = [data copy];
    _header = [header copy];
  }
  return self;
}

- (void)gotoHashtag
{
    NSString *address = [_data objectForKey:@"session_tag"];
    [RgManager startHashtag:address];
}

@end
