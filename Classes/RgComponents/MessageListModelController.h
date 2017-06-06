#import <Foundation/Foundation.h>
#import "RegexKitLite/RegexKitLite.h"

@class CKCollectionViewDataSource;
@class MessageThreadPage;

@interface MessageListModelController : NSObject

@property (nonatomic, retain) NSArray *mainList;
@property (nonatomic, retain) NSNumber *mainCount;

- (MessageThreadPage *)fetchNewPageWithCount:(NSInteger)count;

@end
