#import <ComponentKit/ComponentKit.h>
#import <AVFoundation/AVFoundation.h>

@class ChatElement;
@class ChatElementContext;

@interface ChatElementVideoComponent : CKCompositeComponent

@property (nonatomic, strong, readonly) ChatElement *element;

+ (instancetype)newWithChatElement:(ChatElement *)elem context:(ChatElementContext *)context;

@end
