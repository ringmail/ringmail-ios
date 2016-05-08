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

#import "HashtagModelController.h"

#import <UIKit/UIColor.h>
#import <ObjectiveSugar/ObjectiveSugar.h>

#import "Card.h"
#import "CardsPage.h"
#import "LinphoneManager.h"


@implementation HashtagModelController
{
  NSInteger _numberOfObjects;
}

@synthesize mainList;
@synthesize mainCount;
@synthesize mainPath;

- (instancetype)init
{
    if (self = [super init]) {
        mainCount = [NSNumber numberWithInteger:0];
        mainList = nil;
        mainPath = RG_HASHTAG_DIRECTORY;
    }
    return self;
}

- (CardsPage *)fetchNewCardsPageWithCount:(NSInteger)count
{
    NSAssert(count >= 1, @"Count should be a positive integer");
    NSString* title;
    if (mainList == nil)
    {
        // Initialize
        mainList = [NSMutableArray array];
        if ([mainPath isEqualToString:RG_HASHTAG_DIRECTORY])
        {
            title = @"Hashtags";
            [mainList push:@{
                             @"type": @"hashtag_category",
                             @"name": @"Lifestyle",
                             }];
            [mainList push:@{
                             @"type": @"hashtag_category",
                             @"name": @"Technology",
                             }];
            [mainList push:@{
                             @"type": @"hashtag_category",
                             @"name": @"Stocks",
                             }];
            [mainList push:@{
                             @"type": @"hashtag_category",
                             @"name": @"News",
                             }];
        }
        else
        {
            title = [mainPath copy];
            for (NSUInteger i = 0; i < 25; i++)
            {
                [mainList push:@{
                    @"type": @"hashtag_category",
                    @"name": [NSString stringWithFormat:@"Tag: %lu", (unsigned long)i]
                }];
            }
        }
    }
    NSMutableArray *_cards = [NSMutableArray new];
    NSInteger added = 0;
    for (NSUInteger i = 0; i < count; i++)
    {
        if ([mainCount intValue] == 0 && i == 0)
        {
            NSNumber *headerCell = [NSNumber numberWithBool:1];
            Card *card = [[Card alloc] initWithData:@{@"text": title}
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
    mainCount = [NSNumber numberWithInteger:[mainCount integerValue] + added];
    return cardsPage;
}

@end
