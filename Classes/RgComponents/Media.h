#import <Foundation/Foundation.h>

@interface Media : NSObject

@property (nonatomic, readonly, copy) NSDictionary *data;

- (instancetype)initWithData:(NSDictionary *)data;

@end
