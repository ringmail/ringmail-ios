//
//  RKMessage.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

#import "RKItem.h"

@interface RKMessage : RKItem

+ (instancetype)newWithData:(NSDictionary*)param;

- (instancetype)initWithData:(NSDictionary*)param;
- (void)insertItem:(NoteDatabase*)ndb;
- (void)prepareMessage:(void (^)(NSObject* xml))send;

@property (nonatomic, strong) NSNumber* messageId;
@property (nonatomic, strong) NSString* body;
@property (nonatomic, strong) NSString* deliveryStatus;

@end
