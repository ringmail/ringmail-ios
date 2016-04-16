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

@interface NSDate (Strftime)

- (NSString*)strftime:(NSString*)format;

- (NSString*)strftime;

+ (NSDate *)parse:(NSString *)input;

@end

        /*FMResultSet *r1 = [db executeQuery:@"SELECT * FROM session;"];
        while ([r1 next])
        {
            NSLog(@"%@", [r1 resultDictionary]);
        }
        [r1 close];*/
        
        /*FMResultSet *r2 = [db executeQuery:@"SELECT * FROM calls;"];
        while ([r2 next])
        {
            NSLog(@"%@", [r2 resultDictionary]);
        }
        [r2 close];*/
        
        /*NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
        NSArray *res1 = [ndb get:@{
           @"table":@"calls",
           @"select":@[@"oid",@"call_sip",@"session_id",@"call_state"],
        }];
        NSLog(@"Note DB Query: %@", res1);
        for (id i in res1)
        {
            NoteRow* r = [ndb row:@"calls" id:[i objectForKey:@"rowid"]];
            NSDictionary* rd = [r data];
            NSLog(@"Note DB Row: %@", rd);
        }*/

