//
//  RgViewDelegate.h
//  ringmail
//
//  Created by Mike Frager on 5/25/17.
//
//

#import <Foundation/Foundation.h>
#import "MessageViewController.h"
#import "RingKit.h"

@interface RgViewDelegate : NSObject<RKCommunicatorViewDelegate>

@property (nonatomic, strong) NSNumber* lastThreadId;
@property (nonatomic, strong) MessageViewController* messageView;
		

+ (instancetype)sharedInstance;

- (void)showMessageView:(RKThread*)thread;
//- (void)showCallView;
//- (void)showHashtagView:(NSString*)hashtag;
//- (void)showContactView:(NSNumber*)contactId;
- (void)showImageView:(UIImage*)image parameters:(NSDictionary*)params;
- (void)showMomentView:(UIImage*)image parameters:(NSDictionary*)params complete:(void(^)(void))complete;
- (void)startCall:(RKAddress*)dest video:(BOOL)video;

@end
