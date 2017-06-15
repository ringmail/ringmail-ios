//
//  RgViewDelegate.h
//  ringmail
//
//  Created by Mike Frager on 5/25/17.
//
//

#import <Foundation/Foundation.h>
#import "RingKit.h"

@interface RgViewDelegate : NSObject<RKCommunicatorViewDelegate>

+ (instancetype)sharedInstance;

- (void)showMessageView;
//- (void)showCallView;
//- (void)showHashtagView:(NSString*)hashtag;
//- (void)showContactView:(NSNumber*)contactId;
- (void)showImageView:(UIImage*)image parameters:(NSDictionary*)params;
- (void)showMomentView:(UIImage*)image parameters:(NSDictionary*)params complete:(void(^)(void))complete;

@end
