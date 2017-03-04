#import <ComponentKit/ComponentKit.h>

@class Favorite;
@class FavoriteContext;

@interface FavoriteComponent : CKCompositeComponent

+ (instancetype)newWithFavorite:(Favorite *)fav context:(FavoriteContext *)context;

@end
