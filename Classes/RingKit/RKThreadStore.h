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
- (void)dumpThreads;
- (NSArray*)listThreads;
- (NSArray*)listThreadItems:(RKThread*)thread;
- (NSArray*)listThreadItems:(RKThread*)thread lastItemId:(NSNumber*)lastItemId notify:(BOOL)notify;
- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress orignalTo:(RKAddress*)origTo contactId:(NSNumber*)ctid uuid:(NSString*)uuid;
- (RKThread*)getThreadById:(NSNumber*)lookupId;
- (RKThread*)getThreadByMD5:(NSString*)lookupHash;
- (RKCall*)getCallBySipId:(NSString*)sip;
- (RKMessage*)getMessageByUUID:(NSString*)inputUUID;
- (void)setHidden:(BOOL)hidden forItemId:(NSNumber*)itemId;
- (void)removeContact:(NSNumber*)contact;
- (void)updateContact:(NSNumber*)contact changes:(NSDictionary*)changes;

@end
