#import <Foundation/Foundation.h>

@interface MessageThreadPage : NSObject

@property (nonatomic, readonly, strong) NSArray *threads;
@property (nonatomic, readonly, assign) NSInteger position;

- (instancetype)initWithMessageThreads:(NSArray *)cards position:(NSInteger)position;

@end

@protocol MessageThreadPageLoading <NSObject>

- (void)showWaiting;
- (void)hideWaiting;

@end
