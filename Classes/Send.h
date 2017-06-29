#import <Foundation/Foundation.h>

@interface Send : NSObject

@property (nonatomic, readonly, copy) NSDictionary *data;

- (instancetype)initWithData:(NSDictionary *)data;

- (void)sendMessage:(NSDictionary *)msgdata;
- (void)showPhotoCamera;
- (void)showVideoCamera;
- (void)showMomentCamera;

- (void)showVideoMedia;
- (void)showImageMedia;

- (void)showContactSelect;

@end
