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

#import <Foundation/Foundation.h>

@class CKCollectionViewDataSource;
@class CardsPage;

/**
 HashtagModelController handles the generation hashtag cards and category cards
 */
@interface HashtagModelController : NSObject

@property (nonatomic, retain) NSMutableArray *mainList;
@property (nonatomic, retain) NSNumber *mainCount;
@property (nonatomic, retain) NSString *mainPath;

/**
 Gets more page items
 @param count The number of Card models to fetch.
 @return A page of cards
 */
- (CardsPage *)fetchNewCardsPageWithCount:(NSInteger)count;

@end
