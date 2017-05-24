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

#import "MessageThreadModelController.h"

#import <UIKit/UIColor.h>

#import "MessageThread.h"
#import "MessageThreadPage.h"
#import "LinphoneManager.h"
#import "RingKit.h"

@implementation MessageThreadModelController

@synthesize mainList;
@synthesize mainCount;

- (instancetype)init
{
    if (self = [super init])
	{
        mainList = [[RKCommunicator sharedInstance] listThreads];
        mainCount = [NSNumber numberWithInteger:0]; // Counter as items are added to the UI
    }
    return self;
}

- (MessageThreadPage *)fetchNewPageWithCount:(NSInteger)count
{
    NSAssert(count >= 1, @"Count should be a positive integer");
    NSMutableArray *cards = [NSMutableArray new];
    NSInteger added = 0;
    for (NSUInteger i = 0; i < count; i++)
    {
        NSInteger mainIndex = [mainCount integerValue] + i;
        if ([mainList count] > mainIndex)
        {
            MessageThread *card = [[MessageThread alloc] initWithData:mainList[mainIndex]];
            [cards addObject:card];
            added++;
        }
    }
    MessageThreadPage *page = [[MessageThreadPage alloc] initWithMessageThreads:cards position:[mainCount integerValue]];
    mainCount = [NSNumber numberWithInteger:[mainCount integerValue] + added];
    return page;
}

@end
