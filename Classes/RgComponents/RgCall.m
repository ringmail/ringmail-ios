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

#import "RgCall.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

@implementation RgCall

@synthesize durationLabel;

- (instancetype)initWithData:(NSDictionary *)data
{
  if (self = [super init]) {
    _data = [data copy];
  }
  return self;
}

#pragma mark - Action Functions

+ (void)requestHangup
{
	LinphoneCore *lc = [LinphoneManager getLc];
	LinphoneCall *currentcall = linphone_core_get_current_call(lc);
	if (currentcall != NULL)
	{
		linphone_core_terminate_call(lc, currentcall);
	}
}

+ (void)toggleSpeaker
{
	if ([[LinphoneManager instance] speakerEnabled])
	{
		[[LinphoneManager instance] setSpeakerEnabled:NO];
	}
	else
	{
		[[LinphoneManager instance] setSpeakerEnabled:YES];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RgCallRefresh" object:nil];
}

+ (void)toggleMute
{
	if (linphone_core_is_mic_muted([LinphoneManager getLc]))
	{
		linphone_core_mute_mic([LinphoneManager getLc], false);
	}
	else
	{
		linphone_core_mute_mic([LinphoneManager getLc], true);
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RgCallRefresh" object:nil];
}

+ (void)incomingAnswer
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RgIncomingAnswer" object:nil];
}

+ (void)incomingReject
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"RgIncomingReject" object:nil];
}

@end
