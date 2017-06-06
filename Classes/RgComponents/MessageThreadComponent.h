#import <ComponentKit/ComponentKit.h>

@class MessageThread;
@class MessageThreadContext;

@interface MessageThreadComponent : CKCompositeComponent

@property (nonatomic, strong) MessageThread* currentThread;

+ (instancetype)newWithMessageThread:(MessageThread *)thr context:(MessageThreadContext *)context;

@end
