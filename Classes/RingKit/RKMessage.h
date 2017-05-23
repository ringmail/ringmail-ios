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

- (instancetype)initWithData:(NSDictionary*)param;
- (void)insertItem:(NoteDatabase*)ndb;

@property (nonatomic, strong) NSString* body;
@property (nonatomic, strong) NSString* deliveryStatus;

@end
