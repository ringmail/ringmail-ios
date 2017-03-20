#import "FavoriteModelController.h"

#import <UIKit/UIColor.h>

#import "Favorite.h"
#import "FavoritesPage.h"

@implementation FavoriteModelController

@synthesize mainCount;

- (instancetype)init
{
    if (self = [super init]) {
        mainCount = [NSNumber numberWithInteger:0];
    }
    return self;
}

- (FavoritesPage *)fetchNewFavoritesPageWithCount:(NSInteger)count;
{
	NSAssert(count >= 1, @"Count should be a positive integer");
	NSArray* testFavs = @[
		@{@"name": @"Bob"},
		@{@"name": @"Jim"},
		@{@"name": @"James"},
		@{@"name": @"Pat"},
		@{@"name": @"Cathy"},
		@{@"name": @"Jennifer"},
		@{@"name": @"Jamie"},
		@{@"name": @"Mike"},
		@{@"name": @"John"},
		@{@"name": @"Ralph"},
		@{@"name": @"Nathaniel"},
		@{@"name": @"April"},
		@{@"name": @"Seth"},
	];
	NSMutableArray *favList = [NSMutableArray array];
	NSInteger added = 0;
	for (NSUInteger i = 0; i < count; i++)
    {
		NSInteger mainIndex = [mainCount intValue] + i;
		if ([testFavs count] > mainIndex)
		{
			Favorite* favItem = [[Favorite alloc] initWithData:[testFavs objectAtIndex:mainIndex]];
			[favList addObject:favItem];
			added++;
		}
	}
	FavoritesPage *favsPage = [[FavoritesPage alloc] initWithFavorites:favList position:[mainCount integerValue]];
	mainCount = [NSNumber numberWithInteger:[mainCount integerValue] + added];
	return favsPage;
}

@end
