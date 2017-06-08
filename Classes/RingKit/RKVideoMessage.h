//
//  RKMessage.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

#import "RKMediaMessage.h"

@interface RKVideoMessage : RKMediaMessage

+ (instancetype)newWithData:(NSDictionary*)param;

- (instancetype)initWithData:(NSDictionary*)param;


@end
