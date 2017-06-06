//
//  RKCall.h
//  ringmail
//

#import <Foundation/Foundation.h>

#import "RKItem.h"

typedef NS_ENUM(NSInteger, RKCallResult) {
	RKCallResultSuccess,
	RKCallResultMissed,
	RKCallResultAborted,
	RKCallResultDeclined
};

@interface RKCall : RKItem

+ (instancetype)newWithData:(NSDictionary*)param;

- (instancetype)initWithData:(NSDictionary*)param;
- (void)insertItem:(NoteDatabase*)ndb;

@property (nonatomic, strong) NSNumber* callId;
@property (nonatomic, strong) NSString* sipId;
@property (nonatomic, strong) NSString* callStatus;
@property (nonatomic, strong) NSString* callResult;
@property (nonatomic, strong) NSNumber* duration;
@property (nonatomic, strong) NSNumber* video;

@end
