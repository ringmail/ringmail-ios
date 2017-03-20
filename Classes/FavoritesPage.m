#import "FavoritesPage.h"

@implementation FavoritesPage

- (instancetype)initWithFavorites:(NSArray *)favs position:(NSInteger)position
{
	if (self = [super init])
	{
		_favorites = favs;
		_position = position;
	}
	return self;
}

@end
