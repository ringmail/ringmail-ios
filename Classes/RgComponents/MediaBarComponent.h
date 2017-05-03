//
//  MediaBarComponent.h
//  ringmail
//
//  Created by Mike Frager on 3/1/17.
//
//

#import <ComponentKit/CKStatefulViewComponent.h>
#import <ComponentKit/CKStatefulViewComponentController.h>

#import "MediaCollectionViewController.h"

@interface MediaBarComponent : CKStatefulViewComponent
+ (instancetype)newWithMedia:(NSArray*)media size:(const CKComponentSize &)size;
@end

@interface MediaBarView : UIView;

@property (nonatomic, weak) MediaCollectionViewController *componentViewController;

@end

@interface MediaBarComponentController : CKStatefulViewComponentController

@end
