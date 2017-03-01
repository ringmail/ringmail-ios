#import <ComponentKit/ComponentKit.h>

@class Send;
@class SendContext;


@interface SendComponent : CKCompositeComponent

+ (instancetype)newWithSend:(Send *)call context:(SendContext *)context;

@end
