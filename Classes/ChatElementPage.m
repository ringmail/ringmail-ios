#import "ChatElementPage.h"

@implementation ChatElementPage

- (instancetype)initWithChatElements:(NSArray *)elems position:(NSInteger)position
{
	if (self = [super init])
	{
		_elements = elems;
		_position = position;
	}
	return self;
}

@end
