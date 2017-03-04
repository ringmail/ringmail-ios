//
//  FavoritesBarComponent.m
//  ringmail
//
//  Created by Mike Frager on 3/1/17.
//
//

#import <ComponentKit/CKComponentScope.h>
#import "FavoritesBarComponent.h"
#import "FavoriteCollectionViewController.h"

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
})

@interface FavoritesBarComponent ()

@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) FavoriteCollectionViewController *favoritesCollection;

@end

@implementation FavoritesBarComponent

+ (instancetype)newWithSize:(const CKComponentSize &)size
{
	CKComponentScope scope(self);
	FavoritesBarComponent *c = [super newWithSize:size accessibility:{}];
	if (c)
	{
		c->_flowLayout = [[UICollectionViewFlowLayout alloc] init];
		[c->_flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
		[c->_flowLayout setMinimumInteritemSpacing:0];
		[c->_flowLayout setMinimumLineSpacing:0];
		c->_favoritesCollection = [[FavoriteCollectionViewController alloc] initWithCollectionViewLayout:c->_flowLayout];
		[[c->_favoritesCollection collectionView] setShowsHorizontalScrollIndicator:NO];
	}
	return c;
}
@end

@implementation FavoritesBarComponentController

+ (FavoritesBarView *)newStatefulView:(id)context
{
	FavoritesBarView* fv = [[FavoritesBarView alloc] init];
	return fv;
}

+ (void)configureStatefulView:(FavoritesBarView *)sv forComponent:(FavoritesBarComponent *)component
{
	UIViewController* parent = UIViewParentController(sv);
	FavoriteCollectionViewController* favController = component.favoritesCollection;
	CGRect r = sv.frame;
    r.origin.y = 0;
    [favController.view setFrame:r];
    [sv addSubview:favController.view];
    [parent addChildViewController:favController];
    [favController didMoveToParentViewController:parent];
	//[component.favoritesCollection setCollectionView:sv];
}

@end

@implementation FavoritesBarView

@end
