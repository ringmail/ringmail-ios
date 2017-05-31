//
//  RKMessage.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

#import "RKMessage.h"

@interface RKMediaMessage : RKMessage

+ (instancetype)newWithData:(NSDictionary*)param;

- (instancetype)initWithData:(NSDictionary*)param;

@property (nonatomic, strong) NSURL* mediaURL;
@property (nonatomic, strong) NSData* mediaData;
@property (nonatomic, strong) NSString* mediaType;

@end
