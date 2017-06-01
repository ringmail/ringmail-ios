#import "ChatElement.h"
#import "ChatElementContext.h"
#import "ChatElementComponent.h"
#import "ChatElementTextComponent.h"
#import "ChatElementCallComponent.h"
#import "ChatElementImageComponent.h"

#import "UIColor+Hex.h"
#import "RingKit.h"

@implementation ChatElementComponent

+ (instancetype)newWithChatElement:(ChatElement *)elem context:(ChatElementContext *)context
{
	return [super newWithComponent:chatComponent(elem, context)];
}

static CKComponent *chatComponent(ChatElement *elem, ChatElementContext *context)
{
	NSDictionary* data = elem.data;
	if ([data[@"item"] isKindOfClass:[RKMessage class]])
	{
		return [ChatElementTextComponent newWithChatElement:elem context:context];
	}
	else if ([data[@"item"] isKindOfClass:[RKCall class]])
	{
		return [ChatElementCallComponent newWithChatElement:elem context:context];
	}
	return nil;
}

@end
