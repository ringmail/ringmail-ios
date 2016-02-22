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

#import "CardModelController.h"

#import <UIKit/UIColor.h>

#import "Card.h"
#import "CardsPage.h"
#import "LinphoneManager.h"

@implementation CardModelController
{
  NSInteger _numberOfObjects;
}

@synthesize mainList;
@synthesize mainCount;

- (instancetype)init
{
    if (self = [super init]) {
        mainCount = [NSNumber numberWithInteger:0];
        mainList = nil;
    }
    return self;
}

- (NSArray *)readMainList
{
    return [[[LinphoneManager instance] chatManager] dbGetMainList];
}

- (CardsPage *)fetchNewCardsPageWithCount:(NSInteger)count
{
    NSAssert(count >= 1, @"Count should be a positive integer");
    if (mainList == nil)
    {
        mainList = [self readMainList];
    }
    NSMutableArray *_cards = [NSMutableArray new];
    NSInteger added = 0;
    for (NSUInteger i = 0; i < count; i++)
    {
        if ([mainCount intValue] == 0 && i == 0)
        {
            NSNumber *headerCell = [NSNumber numberWithBool:1];
            Card *card = [[Card alloc] initWithData:@{@"text": @"Recent Activity"}
                                             header:headerCell];
            [_cards addObject:card];
            added++;
        }
        else
        {
            NSInteger mainIndex = [mainCount intValue] + i - 1;
            if ([mainList count] > mainIndex)
            {
                NSDictionary *itemData = mainList[mainIndex];
                if (itemData != nil)
                {
                    // Todo: translate to name
                    Card *card = [[Card alloc] initWithData:itemData
                                            header:[NSNumber numberWithBool:0]];
                    [_cards addObject:card];
                    added++;
                }
            }
        }
    }
    CardsPage *cardsPage = [[CardsPage alloc] initWithCards:_cards
                                                     position:[mainCount integerValue]];
    mainCount = [NSNumber numberWithInteger:added];
    return cardsPage;
}

@end
