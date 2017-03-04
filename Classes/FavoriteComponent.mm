#import "Favorite.h"
#import "FavoriteContext.h"
#import "FavoriteComponent.h"

@implementation FavoriteComponent

+ (instancetype)newWithFavorite:(Favorite *)fav context:(FavoriteContext *)context
{
   return [super newWithComponent:favoriteComponent(fav, context)];
}

static CKComponent *favoriteComponent(Favorite *fav, FavoriteContext *context)
{
    NSString* name = [fav.data objectForKey:@"name"];
	return [CKStackLayoutComponent newWithView:{} size:{ .height = 76, .width = 60} style:{
		.direction = CKStackLayoutDirectionVertical,
		.alignItems = CKStackLayoutAlignItemsStart
	}
	children:{
		{[CKInsetComponent newWithInsets:{.top = 5, .left = INFINITY, .bottom = 5, .right = INFINITY} component:
			[CKComponent newWithView:{
				[UIView class],
				{
					{@selector(setBackgroundColor:), [UIColor blueColor]},
				}
			} size:{.height = 36, .width = 36}]
		]},
		{[CKInsetComponent newWithInsets:{.top = 8, .left = 5, .bottom = 12, .right = 5} component:
			[CKLabelComponent newWithLabelAttributes:{
				.string = name,
				.font = [UIFont systemFontOfSize:10],
			}
			viewAttributes:{
				{@selector(setBackgroundColor:), [UIColor clearColor]},
				{@selector(setUserInteractionEnabled:), @NO},
			}
			size:{.height = 10, .width = 50}]
		]}
	}];
}

@end
