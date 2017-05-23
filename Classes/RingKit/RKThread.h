//
//  RKThread.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

@class RKAddress;
@class RKContact;

@interface RKThread : NSObject

@property (nonatomic, strong) NSNumber* threadId;
@property (nonatomic, strong) RKAddress* remoteAddress;
@property (nonatomic, strong) RKAddress* originalTo;
@property (nonatomic, strong) RKContact* contact;
@property (nonatomic, strong) NSString* uuid;

+ (instancetype)newWithData:(NSDictionary*)param;

@end
