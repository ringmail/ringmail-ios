#import <Foundation/Foundation.h>

@interface MediaPage : NSObject

@property (nonatomic, readonly, strong) NSArray *media;
@property (nonatomic, readonly, assign) NSInteger position;

- (instancetype)initWithMedia:(NSArray *)media position:(NSInteger)position;

@end

@protocol MediaPageLoading <NSObject>

- (void)showWaiting;
- (void)hideWaiting;

@end
