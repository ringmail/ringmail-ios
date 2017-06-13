//
//  RKMessage.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

#import "RKItem.h"

typedef NS_ENUM(NSInteger, RKMessageStatus) {
	RKMessageStatusReceived,
	RKMessageStatusSending,
	RKMessageStatusSent,
	RKMessageStatusDelivered
};

#define _RKMessageStatus(enum) [@[@"Received",@"Sending",@"Sent",@"Delivered"] objectAtIndex:enum]

@interface RKMessage : RKItem

@property (nonatomic, strong) NSNumber* messageId;
@property (nonatomic, strong) NSString* body;
@property (nonatomic) RKMessageStatus deliveryStatus;

+ (instancetype)newWithData:(NSDictionary*)param;

- (instancetype)initWithData:(NSDictionary*)param;
- (void)insertItem:(NoteDatabase*)ndb;
- (void)prepareMessage:(void (^)(NSObject* xml))send;

@end
