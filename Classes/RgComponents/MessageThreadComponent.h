#import <ComponentKit/ComponentKit.h>

@class MessageThread;
@class MessageThreadContext;

@interface MessageThreadComponent : CKCompositeComponent

@property NSMutableDictionary *removeButtons;

+ (instancetype)newWithMessageThread:(MessageThread *)thr context:(MessageThreadContext *)context;

@end
