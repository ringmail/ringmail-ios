#import <ComponentKit/ComponentKit.h>

@class Media;
@class MediaContext;

@interface MediaComponent : CKCompositeComponent

+ (instancetype)newWithMedia:(Media *)media context:(MediaContext *)context;

@end
