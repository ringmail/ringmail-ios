//
//  RKItem.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

@class RKThread;

@interface RKItem : NSObject

@property (nonatomic, strong) RKThread* thread;

@end
