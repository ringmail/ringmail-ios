#import <Foundation/Foundation.h>

@interface ChatElementPage : NSObject

@property (nonatomic, readonly, strong) NSArray *elements;
@property (nonatomic, readonly, assign) NSInteger position;

- (instancetype)initWithChatElements:(NSArray *)elems position:(NSInteger)position;

@end

@protocol ChatElementPageLoading <NSObject>

- (void)showWaiting;
- (void)hideWaiting;

@end
