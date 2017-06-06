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
	NSLog(@"Item: %@", data[@"item"]);
	if ([data[@"item"] isKindOfClass:[RKPhotoMessage class]])
	{
		NSLog(@"Photo message");
		return [ChatElementImageComponent newWithChatElement:elem context:context];
	}
	else if ([data[@"item"] isKindOfClass:[RKMessage class]])
	{
		NSLog(@"Text message");
		return [ChatElementTextComponent newWithChatElement:elem context:context];
	}
	else if ([data[@"item"] isKindOfClass:[RKCall class]])
	{
		NSLog(@"Call item");
		return [ChatElementCallComponent newWithChatElement:elem context:context];
	}
	return nil;
}

@end
