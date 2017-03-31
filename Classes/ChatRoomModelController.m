#import "ChatRoomModelController.h"

#import <UIKit/UIColor.h>

#import "ChatElement.h"
#import "ChatElementPage.h"
#import "LinphoneManager.h"

@implementation ChatRoomModelController

@synthesize mainCount;
@synthesize chatThreadID;

- (id)initWithID:(NSNumber*)threadID
{
    if (self = [super init]) {
        mainCount = [NSNumber numberWithInteger:0];
        chatThreadID = threadID;
    }
    return self;
}

- (ChatElementPage *)fetchNewChatElementPageWithCount:(NSInteger)count;
{
	NSAssert(count >= 1, @"Count should be a positive integer");
	
	// TODO: move this to outer view controller?
	NSArray* messages = [[[LinphoneManager instance] chatManager] dbGetMessages:self.chatThreadID];
	NSLog(@"%@", messages);
	NSArray* elementList = @[];
	NSInteger added = 0;
	
	ChatElementPage *elementPage = [[ChatElementPage alloc] initWithChatElements:elementList position:[mainCount integerValue]];
	mainCount = [NSNumber numberWithInteger:[mainCount integerValue] + added];
	return elementPage;
}

@end
