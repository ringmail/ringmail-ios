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

@implementation CardModelController
{
  NSInteger _numberOfObjects;
}

- (instancetype)init
{
  if (self = [super init]) {
    _numberOfObjects = 0;
  }
  return self;
}

- (CardsPage *)fetchNewCardsPageWithCount:(NSInteger)count
{
  NSAssert(count >= 1, @"Count should be a positive integer");
  NSArray *cards = generateCards(_numberOfObjects, count);
  CardsPage *cardsPage = [[CardsPage alloc] initWithCards:cards
                                                     position:_numberOfObjects];
  _numberOfObjects += count;
  return cardsPage;
}

#pragma mark - Random Card Generation

static NSArray *generateCards(NSInteger start, NSInteger count)
{
    NSMutableArray *_cards = [NSMutableArray new];
    if (start == 0)
    {
        for (NSUInteger i = 0; i < count; i++)
        {
            NSNumber *headerCell = [NSNumber numberWithBool:0];
            NSDictionary *cardInfo = @{@"text":@"Card Text"};
            if (i == 0)
            {
                headerCell = [NSNumber numberWithBool:1];
                cardInfo = @{@"text":@"Recent Activity"};
            }
            Card *card = [[Card alloc] initWithText:cardInfo[@"text"]
                                             header:headerCell];
            [_cards addObject:card];
            //i = count;
        }
    }
    return _cards;
}

@end
