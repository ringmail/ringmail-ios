//
//  RKItem.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>
#import "NoteSQL.h"

typedef NS_ENUM(NSInteger, RKItemDirection) {
	RKItemDirectionOutbound,
	RKItemDirectionInbound
};

@class RKThread;

@interface RKItem : NSObject

@property (nonatomic, strong) NSNumber* itemId; // Refers to the rk_thread_item record id
@property (nonatomic, strong) NSNumber* version; // Update count
@property (nonatomic, strong) RKThread* thread;
@property (nonatomic, strong) NSString* uuid;
@property (nonatomic, strong) NSDate* timestamp;
@property (nonatomic) RKItemDirection direction;

- (instancetype)initWithData:(NSDictionary*)param;
- (void)insertItem:(NoteDatabase*)ndb;
- (void)updateItem:(NoteDatabase*)ndb;
- (RKThread*)updateItem:(NoteDatabase*)ndb seen:(BOOL)seen;
- (void)updateVersion:(NoteDatabase*)ndb;

@end
