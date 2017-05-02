#import <ComponentKit/ComponentKit.h>

@class Send;
@class SendContext;

@interface SendCardComponent : CKCompositeComponent

@property (nonatomic, strong, readonly) Send *send;

+ (id)initialState;
+ (instancetype)newWithSend:(Send *)item context:(SendContext *)context;

@end
