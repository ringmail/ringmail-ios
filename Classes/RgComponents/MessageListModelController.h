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
#import "RegexKitLite/RegexKitLite.h"

@class CKCollectionViewDataSource;
@class CardsPage;

/**
 CardModelController handles the generation of pages of quotes to be added to a list.
 */
@interface CardModelController : NSObject

@property (nonatomic, retain) NSArray *mainList;
@property (nonatomic, retain) NSNumber *mainCount;

/**
 Gets more quotes to add to the list.
 @param count The number of Card models to fetch.
 @return A page of quotes containing the end insertion position and the list of quotes to insert.
 */
- (CardsPage *)fetchNewCardsPageWithCount:(NSInteger)count;

- (NSArray *)buildCards:(NSArray*)list;

@end
