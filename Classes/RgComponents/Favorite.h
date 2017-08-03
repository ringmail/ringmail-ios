#import <Foundation/Foundation.h>

@interface Favorite : NSObject

@property (nonatomic, readonly, copy) NSNumber *header;
@property (nonatomic, readonly, copy) NSDictionary *data;

- (instancetype)initWithData:(NSDictionary *)data;
- (void)favoriteClick;

@end
