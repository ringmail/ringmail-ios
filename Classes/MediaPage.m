#import "MediaPage.h"

@implementation MediaPage

- (instancetype)initWithMedia:(NSArray *)media position:(NSInteger)position
{
	if (self = [super init])
	{
		_media = media;
		_position = position;
	}
	return self;
}

@end
