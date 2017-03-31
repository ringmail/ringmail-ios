#import <Foundation/Foundation.h>
#import "RegexKitLite/RegexKitLite.h"
#import "ChatRoomModelController.h"

@class CKCollectionViewDataSource;
@class ChatElementPage;

@interface ChatRoomModelController : NSObject

@property (nonatomic, retain) NSArray *elements;
@property (nonatomic, retain) NSNumber *chatThreadID;
@property (nonatomic, retain) NSNumber *mainCount;

- (id)initWithID:(NSNumber*)threadID;
- (ChatElementPage *)fetchNewChatElementPageWithCount:(NSInteger)count;

@end
