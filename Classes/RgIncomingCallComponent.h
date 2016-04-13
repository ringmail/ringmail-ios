#import <ComponentKit/ComponentKit.h>

@class RgCall;
@class RgCallContext;

@interface RgIncomingCallComponent : CKCompositeComponent

+ (instancetype)newWithCall:(RgCall *)call context:(RgCallContext *)context;

@end
