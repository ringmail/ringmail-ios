//
//  RgNetwork.h
//  ringmail
//
//  Created by Mike Frager on 9/4/15.
//
//

#import <Foundation/Foundation.h>
#import "AFNetworking/AFNetworking.h"

@interface RgNetwork : NSObject

@property (nonatomic, strong) NSString* networkHost;

+ (RgNetwork *)instance;
- (void)login:(NSString*)login password:(NSString*)password;
- (void)registerPushToken;

@end
