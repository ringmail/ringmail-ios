//
//  RKCall.h
//  ringmail
//

#import <Foundation/Foundation.h>

#import "RKItem.h"

@interface RKCall : RKItem

+ (instancetype)newWithData:(NSDictionary*)param;

- (instancetype)initWithData:(NSDictionary*)param;
- (void)insertItem:(NoteDatabase*)ndb;

@property (nonatomic, strong) NSNumber* callId;
@property (nonatomic, strong) NSString* sipId;
@property (nonatomic, strong) NSString* callStatus;
@property (nonatomic, strong) NSString* callResult;
@property (nonatomic, strong) NSNumber* duration;

@end
