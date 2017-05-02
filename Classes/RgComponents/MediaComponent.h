#import <ComponentKit/ComponentKit.h>

@class Media;
@class MediaContext;

@interface MediaComponent : CKCompositeComponent

@property (nonatomic, weak) NSDictionary* localData;

+ (instancetype)newWithMedia:(Media *)media context:(MediaContext *)context;

@end
