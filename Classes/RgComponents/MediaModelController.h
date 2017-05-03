#import <Foundation/Foundation.h>
#import "RegexKitLite/RegexKitLite.h"
#import "MediaModelController.h"

@class CKCollectionViewDataSource;
@class MediaPage;

@interface MediaModelController : NSObject

@property (nonatomic, retain) NSArray *mediaData;
@property (nonatomic, retain) NSNumber *mainCount;

- (MediaModelController *)initWithMedia:(NSArray*)media;
- (MediaPage *)fetchNewMediaPageWithCount:(NSInteger)count;

@end
