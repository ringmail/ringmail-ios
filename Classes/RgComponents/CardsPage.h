#import <Foundation/Foundation.h>

@interface CardsPage : NSObject

@property (nonatomic, readonly, strong) NSArray *cards;
@property (nonatomic, readonly, assign) NSInteger position;

- (instancetype)initWithCards:(NSArray *)cards
                      position:(NSInteger)position;

@end

@protocol CardPageLoading <NSObject>

- (void)showWaiting;
- (void)hideWaiting;

@end
