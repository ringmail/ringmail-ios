#import <ComponentKit/ComponentKit.h>

@class ChatElement;
@class ChatElementContext;

@interface ChatElementTextComponent : CKCompositeComponent

@property (nonatomic, strong, readonly) ChatElement *element;

+ (instancetype)newWithChatElement:(ChatElement *)elem context:(ChatElementContext *)context;

@end
