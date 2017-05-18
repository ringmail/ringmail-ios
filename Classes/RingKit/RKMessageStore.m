//
//  RKMessageStore.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKMessageStore.h"

@implementation RKMessageStore

+ (instancetype)sharedInstance
{
    static RKMessageStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RKMessageStore alloc] init];
    });
    return sharedInstance;
}

@end
