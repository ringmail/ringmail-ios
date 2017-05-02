#import <ComponentKit/ComponentKit.h>

@class ChatElement;
@class ChatElementContext;

@interface ChatElementComponent : CKCompositeComponent

@property (nonatomic, strong, readonly) ChatElement *element;

+ (instancetype)newWithChatElement:(ChatElement *)elem context:(ChatElementContext *)context;

@end
