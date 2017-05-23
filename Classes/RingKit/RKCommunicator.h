//
//  RKCommunicator.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

#import "RKThreadStore.h"
#import "RKMessage.h"

@interface RKCommunicator : NSObject

+ (instancetype)sharedInstance;

@end
