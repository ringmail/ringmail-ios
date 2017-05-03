#import <Foundation/Foundation.h>

@interface FavoritesPage : NSObject

@property (nonatomic, readonly, strong) NSArray *favorites;
@property (nonatomic, readonly, assign) NSInteger position;

- (instancetype)initWithFavorites:(NSArray *)favs position:(NSInteger)position;

@end

@protocol FavoritesPageLoading <NSObject>

- (void)showWaiting;
- (void)hideWaiting;

@end
