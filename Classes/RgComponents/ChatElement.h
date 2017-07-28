#import <Foundation/Foundation.h>

@interface ChatElement : NSObject

@property (nonatomic, readonly, copy) NSDictionary *data;

+ (BOOL)showingMessageThread;
+ (BOOL)isAllEmojis:(NSString*)str;

- (instancetype)initWithData:(NSDictionary *)data;
- (void)showVideoMedia;
- (void)showImageMedia;
- (void)showMomentMedia;

@end
