//
//  RKMessageStore.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"

#import <Foundation/Foundation.h>

@class RKItem;

@interface RKMessageStore : NSObject

@property (nonatomic, retain) FMDatabaseQueue *databaseQueue;

+ (instancetype)sharedInstance;

- (void)setupDatabase;
- (void)setupTables;
- (void)addActivity:(RKItem*)item;

@end
