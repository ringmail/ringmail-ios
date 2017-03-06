//
//  FavoritesBarComponent.h
//  ringmail
//
//  Created by Mike Frager on 3/1/17.
//
//

#import <ComponentKit/CKStatefulViewComponent.h>
#import <ComponentKit/CKStatefulViewComponentController.h>

#import "FavoriteCollectionViewController.h"

@interface FavoritesBarComponent : CKStatefulViewComponent
+ (instancetype)newWithSize:(const CKComponentSize &)size;
@end

@interface FavoritesBarView : UIView;

@property (nonatomic, weak) FavoriteCollectionViewController *componentViewController;

@end

@interface FavoritesBarComponentController : CKStatefulViewComponentController

@end
