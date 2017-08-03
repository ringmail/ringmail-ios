#import <ComponentKit/ComponentKit.h>

@class Favorite;
@class FavoriteContext;

@interface FavoriteComponent : CKCompositeComponent

@property (nonatomic, retain) NSDictionary *favData;

+ (instancetype)newWithFavorite:(Favorite *)fav context:(FavoriteContext *)context;


@end
