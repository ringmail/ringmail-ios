//
//  RKCommunicator.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKCommunicator.h"
#import "RKMessageStore.h"

@class RKMessage;

@implementation RKCommunicator

+ (instancetype)sharedInstance
{
    static RKCommunicator *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RKCommunicator alloc] init];
    });
    return sharedInstance;
}

- (void)sendMessage:(RKMessage*)message
{
	[RKMessageStore sharedInstance];
}

- (void)didReceiveMessage:(RKMessage*)message
{
}

@end
