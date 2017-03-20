#import <Foundation/Foundation.h>
#import "RegexKitLite/RegexKitLite.h"
#import "FavoriteModelController.h"

@class CKCollectionViewDataSource;
@class FavoritesPage;

@interface FavoriteModelController : NSObject

@property (nonatomic, retain) NSArray *favList;
@property (nonatomic, retain) NSNumber *mainCount;

- (FavoritesPage *)fetchNewFavoritesPageWithCount:(NSInteger)count;

@end
