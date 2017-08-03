#import <ComponentKit/ComponentKit.h>

@class Favorite;
@class FavoriteContext;

@interface FavoriteComponent : CKCompositeComponent

@property (nonatomic, strong, readonly) Favorite *favorite;

+ (instancetype)newWithFavorite:(Favorite *)fav context:(FavoriteContext *)context;


@end
