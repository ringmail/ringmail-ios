#import "Favorite.h"

@implementation Favorite

- (instancetype)initWithData:(NSDictionary *)data
{
	if (self = [super init])
	{
		_data = [data copy];
	}
	return self;
}

@end
