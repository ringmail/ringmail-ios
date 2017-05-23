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

@interface RKThreadStore : NSObject

@property (nonatomic, retain) FMDatabaseQueue *dbqueue;

+ (instancetype)sharedInstance;

- (void)setupDatabase;
- (void)setupTables;
- (void)insertItem:(RKItem*)item;
- (NSArray*)listThreads;
- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress orignalTo:(RKAddress*)origTo contactId:(NSNumber*)ctid uuid:(NSString*)uuid;

@end
