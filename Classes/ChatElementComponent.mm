#import "ChatElement.h"
#import "ChatElementContext.h"
#import "ChatElementComponent.h"
#import "ChatElementTextComponent.h"
#import "ChatElementImageComponent.h"

#import "UIColor+Hex.h"

@implementation ChatElementComponent

+ (instancetype)newWithChatElement:(ChatElement *)elem context:(ChatElementContext *)context
{
	return [super newWithComponent:chatComponent(elem, context)];
}

static CKComponent *chatComponent(ChatElement *elem, ChatElementContext *context)
{
	return [ChatElementTextComponent newWithChatElement:elem context:context];
	/*NSDictionary* data = elem.data;
	NSLog(@"%@", data);
	if (
		[data[@"type"] isEqualToString:@"image/png"] ||
		[data[@"type"] isEqualToString:@"image/jpeg"]
	) {
		return [ChatElementImageComponent newWithChatElement:elem context:context];
	}
	else // Text component
	{
		return [ChatElementTextComponent newWithChatElement:elem context:context];
	}*/
}

@end
