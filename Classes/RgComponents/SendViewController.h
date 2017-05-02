#ifndef SendViewController_h
#define SendViewController_h

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "Send.h"
#import "SendContext.h"

@interface SendViewController : UIViewController

@property (nonatomic, strong) NSMutableDictionary *sendInfo;

- (id)init;
- (void)updateSend;
- (void)selectMedia:(NSNotification *)notif;
- (void)addMedia:(NSDictionary*)param;
- (void)removeMedia;

@end

#endif
