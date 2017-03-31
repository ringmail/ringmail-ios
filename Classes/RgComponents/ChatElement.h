#import <Foundation/Foundation.h>

@interface ChatElement : NSObject

@property (nonatomic, readonly, copy) NSNumber *header;
@property (nonatomic, readonly, copy) NSDictionary *data;

- (instancetype)initWithData:(NSDictionary *)data;

@end
