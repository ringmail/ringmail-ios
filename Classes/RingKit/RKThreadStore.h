//
//  RKThreadStore.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"
#import "Utils.h"

#import <Foundation/Foundation.h>

@class RKItem;
@class RKThread;
@class RKAddress;
@class RKContact;
@class RKCall;
@class RKMessage;

@interface RKThreadStore : NSObject

@property (nonatomic, retain) FMDatabaseQueue *dbqueue;

+ (instancetype)sharedInstance;

- (void)setupDatabase;
- (void)setupTables;
- (void)insertItem:(RKItem*)item;
- (void)updateItem:(RKItem*)item;
- (NSArray*)listThreads;
- (NSArray*)listThreadItems:(RKThread*)thread;
- (NSArray*)listThreadItems:(RKThread*)thread lastItemId:(NSNumber*)lastItemId;
- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress orignalTo:(RKAddress*)origTo contactId:(NSNumber*)ctid uuid:(NSString*)uuid;
- (RKCall*)getCallBySipId:(NSString*)sip;
- (RKMessage*)getMessageByUUID:(NSString*)inputUUID;

@end
