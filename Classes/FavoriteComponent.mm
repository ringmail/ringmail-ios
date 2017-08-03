#import "Favorite.h"
#import "FavoriteContext.h"
#import "FavoriteComponent.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"

@implementation FavoriteComponent

@synthesize favData;

+ (instancetype)newWithFavorite:(Favorite *)fav context:(FavoriteContext *)context
{
    FavoriteComponent *f = [super newWithComponent:favoriteComponent(fav, context)];
    [f setFavData:fav.data];
    return f;
}

static CKComponent *favoriteComponent(Favorite *fav, FavoriteContext *context)
{
    NSString* name = [fav.data objectForKey:@"name"];
    UIImage *cardImage = [fav.data objectForKey:@"image"];;
    
    cardImage = [cardImage thumbnailImage:96 transparentBorder:0 cornerRadius:48 interpolationQuality:kCGInterpolationHigh];
	return [CKStackLayoutComponent newWithView:{
        [UIView class],{
            {CKComponentTapGestureAttribute(@selector(actionSelect:))},
        }
    } size:{ .height = 76, .width = 80} style:{
		.direction = CKStackLayoutDirectionVertical,
		.alignItems = CKStackLayoutAlignItemsStart
	}
	children:{
		{[CKInsetComponent newWithInsets:{.top = 4, .left = INFINITY, .bottom = 0, .right = INFINITY} component:
			[CKImageComponent newWithImage:cardImage size:{.height = 48, .width = 48}]
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


- (void)actionSelect:(CKButtonComponent *)sender
{
    NSLog(@"favorite selected for:  %@", [favData objectForKey:@"contactId"]);
}

@end
