//
//  HashtagStore.h
//  ringmail
//
//  Created by Mark Baxter on 7/3/17.
//
//

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"
#import "Utils.h"

#import <AddressBook/AddressBook.h>
#import <Foundation/Foundation.h>

@interface HashtagStore : NSObject {
    
@private
    NSDateFormatter *dateFormatter;
    NSLocale *enUSPOSIXLocale;
    FMDatabase *database;
}

@property (nonatomic, retain) FMDatabaseQueue *dbqueue;

+ (instancetype)sharedInstance;

- (void)setupDatabase;
- (void)setupTables;

- (NSArray*)selectHistory;
- (void)insertCardData:(NSDictionary*)cardData;
- (void)refreshHistory;


@end
