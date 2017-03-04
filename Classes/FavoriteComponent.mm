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
	return [CKStackLayoutComponent newWithView:{} size:{ .height = 76, .width = 80} style:{
		.direction = CKStackLayoutDirectionVertical,
		.alignItems = CKStackLayoutAlignItemsStart
	}
	children:{
		{[CKInsetComponent newWithInsets:{.top = 4, .left = INFINITY, .bottom = 0, .right = INFINITY} component:
			[CKComponent newWithView:{
				[UIView class],
				{
					{@selector(setBackgroundColor:), [UIColor grayColor]},
					{CKComponentViewAttribute::LayerAttribute(@selector(setCornerRadius:)), @24.0}
				}
			} size:{.height = 48, .width = 48}]
		]},
		{[CKInsetComponent newWithInsets:{.top = 4, .left = INFINITY, .bottom = 0, .right = INFINITY} component:
			[CKLabelComponent newWithLabelAttributes:{
				.string = name,
				.font = [UIFont systemFontOfSize:12],
				.alignment = NSTextAlignmentCenter,
			}
			viewAttributes:{
				{@selector(setBackgroundColor:), [UIColor clearColor]},
				{@selector(setUserInteractionEnabled:), @NO},
			}
			size:{.height = 16, .width = 70}]
		]}
	}];
}

@end
