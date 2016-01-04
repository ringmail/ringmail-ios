//
//  NoteSQL.h
//  ringmail
//
//  Created by Mike Frager on 12/28/15.
//
//

#import <Foundation/Foundation.h>

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"

@interface NoteRow : NSMutableDictionary

@property (nonatomic, strong) FMDatabase* database;
@property (nonatomic, strong) NSString* table;
@property (nonatomic, strong) NSString* primaryKey;
@property (nonatomic, strong) NSNumber* rowid;

- (id)initWithDatabase:(FMDatabase*)db table:(NSString*)table id:(NSNumber*)inp;
- (NSDictionary*)data;
- (void)update:(NSDictionary*)params;

@end

@interface NoteDatabase : NSObject

@property (nonatomic, strong) FMDatabase* database;
@property (nonatomic, strong) NSString* primaryKey;

- (id)initWithDatabase:(FMDatabase*)db;
- (NSArray*)get:(NSDictionary*)params;
- (NSObject*)set:(NSDictionary*)params;
- (NoteRow*)create:(NSString*)table data:(NSDictionary*)params;
- (NoteRow*)row:(NSString*)table id:(NSNumber*)inp;

@end



