#import "ChatRoomModelController.h"

#import <UIKit/UIColor.h>

#import "ChatElement.h"
#import "ChatElementPage.h"
#import "LinphoneManager.h"

@implementation ChatRoomModelController

@synthesize elements;
@synthesize mainCount;
@synthesize chatThreadID;

- (id)initWithID:(NSNumber*)threadID elements:(NSArray*)elems
{
    if (self = [super init]) {
		elements = [NSMutableArray arrayWithArray:elems];
        mainCount = [NSNumber numberWithInteger:0];
        chatThreadID = threadID;
    }
    return self;
}

- (ChatElementPage *)fetchNewChatElementPageWithCount:(NSInteger)count;
{
	NSAssert(count >= 1, @"Count should be a positive integer");
	
	NSMutableArray* elementList = [NSMutableArray array];
	NSInteger added = 0;
	for (NSUInteger i = 0; i < count; i++)
    {
		NSInteger mainIndex = [mainCount intValue] + i;
		if ([elements count] > mainIndex)
		{
			ChatElement* item = [[ChatElement alloc] initWithData:[elements objectAtIndex:mainIndex]];
			[elementList addObject:item];
			added++;
		}
	}
	
	ChatElementPage *elementPage = [[ChatElementPage alloc] initWithChatElements:elementList position:[mainCount integerValue]];
	mainCount = [NSNumber numberWithInteger:[mainCount integerValue] + added];
	return elementPage;
}

@end
