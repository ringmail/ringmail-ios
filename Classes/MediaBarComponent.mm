//
//  MediaBarComponent.m
//  ringmail
//
//  Created by Mike Frager on 3/1/17.
//
//

#import <ComponentKit/CKComponentScope.h>
#import "MediaBarComponent.h"

#import "UIColor+Hex.h"

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
})


@interface MediaBarComponent ()

@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;
@property (nonatomic, strong) MediaCollectionViewController *mediaCollection;

@end

@implementation MediaBarComponent

+ (instancetype)newWithMedia:(NSArray*)media size:(const CKComponentSize &)size
{
	CKComponentScope scope(self);
	MediaBarComponent *c = [super newWithSize:size accessibility:{}];
	if (c)
	{
		c->_flowLayout = [[UICollectionViewFlowLayout alloc] init];
		[c->_flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
		[c->_flowLayout setMinimumInteritemSpacing:0];
		[c->_flowLayout setMinimumLineSpacing:0];
		c->_mediaCollection = [[MediaCollectionViewController alloc] initWithCollectionViewLayout:c->_flowLayout media:media];
		[[c->_mediaCollection collectionView] setShowsHorizontalScrollIndicator:NO];
	}
	return c;
}
@end

@implementation MediaBarComponentController

+ (MediaBarView *)newStatefulView:(id)context
{
	MediaBarView* fv = [[MediaBarView alloc] init];
	fv.componentViewController = nil;
	return fv;
}

+ (void)configureStatefulView:(MediaBarView *)sv forComponent:(MediaBarComponent *)component
{
	//NSLog(@"configureStatefulView");
	if (sv.componentViewController == nil)
	{
		[sv setBackgroundColor:[UIColor clearColor]];
		UIViewController* parent = UIViewParentController(sv);
		MediaCollectionViewController* favController = component.mediaCollection;
		CGRect r = sv.frame;
		r.origin.y = 0;
		[favController.view setFrame:r];
		[sv addSubview:favController.view];
		[parent addChildViewController:favController];
		[favController didMoveToParentViewController:parent];
		sv.componentViewController = favController;
		[[favController collectionView] setAlwaysBounceHorizontal:YES];
	}
	else
	{
		component.mediaCollection = sv.componentViewController; // Keep the same controller on rebuild
	}
}

@end

@implementation MediaBarView

@end
