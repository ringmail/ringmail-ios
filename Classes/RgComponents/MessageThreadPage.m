#import "MessageThreadPage.h"

@implementation MessageThreadPage

- (instancetype)initWithMessageThreads:(NSArray *)threads position:(NSInteger)position
{
    if (self = [super init]) {
        _threads = threads;
        _position = position;
    }
    return self;
}

@end
