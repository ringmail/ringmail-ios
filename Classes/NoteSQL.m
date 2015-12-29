//
//  NoteSQL.m
//  ringmail
//
//  Created by Mike Frager on 12/28/15.
//
//

#import "NoteSQL.h"
#import <ObjectiveSugar/ObjectiveSugar.h>

@implementation NoteDatabase

@synthesize database;

- (id)initWithDatabase:(FMDatabase*)db
{
    self = [super init];
    if (self)
    {
        self.database = db;
    }
    return self;
}

- (NSArray*)get:(NSDictionary*)params
{
    NSString *table = [params objectForKey:@"table"];
    NSString *sql = [NSString stringWithFormat:@"SELECT "];
    NSArray *fromList = [params objectForKey:@"select"];
    
    if (fromList)
    {
        NSString *from = [fromList join:@", "];
        sql = [sql stringByAppendingString:[NSString stringWithFormat:@"%@ ", from]];
    }
    else
    {
        sql = [sql stringByAppendingString:@"*"];
    }
    sql = [sql stringByAppendingString:[NSString stringWithFormat:@" FROM %@", table]];
    NSMutableArray *paramList = [NSMutableArray array];
    id where = [params objectForKey:@"where"];
    if (where)
    {
        // TODO: make recursive and fancy like Perl version
        if ([where isKindOfClass:[NSDictionary class]])
        {
            NSMutableArray *allKeys = [[where allKeys] mutableCopy];
            [allKeys sortUsingSelector:@selector(caseInsensitiveCompare:)];
            NSString *whr = [[allKeys map:^(NSString* key) {
                [paramList push:[where objectForKey:key]];
                return [NSString stringWithFormat:@"%@ = ?", key];
            }] join:@" AND "];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@" WHERE (%@)", whr]];
        }
        else if ([where isKindOfClass:[NSString class]])
        {
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@" WHERE %@", where]];
        }
    }
    NSLog(@"Note SQL: %@", sql);
    NSMutableArray* result = [NSMutableArray array];
    FMResultSet* rs = [database executeQuery:sql withArgumentsInArray:paramList];
    while ([rs next])
    {
        [result push:[rs resultDictionary]];
    }
    [rs close];
    return result;
}

- (void)set:(NSDictionary*)params
{
}

- (NoteRow*)create:(NSString*)table data:(NSDictionary*)params
{
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (", table];
    NSMutableArray *allKeys = [[params allKeys] mutableCopy];
    [allKeys sortUsingSelector:@selector(caseInsensitiveCompare:)];
    sql = [sql stringByAppendingString:[allKeys join:@", "]];
    sql = [sql stringByAppendingString:@") VALUES ("];
    sql = [sql stringByAppendingString:[[allKeys map:^(NSString* key) {
        return [NSString stringWithFormat:@":%@", key];
    }] join:@", "]];
    sql = [sql stringByAppendingString:@");"];
    NSLog(@"Note SQL: %@", sql);
    BOOL ok = [database executeUpdate:sql withParameterDictionary:params];
    if (ok)
    {
        return (NoteRow*)[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithLongLong:[database lastInsertRowId]], @"id", nil];
    }
    return nil;
}

- (NoteRow*)row:(NSString*)table id:(NSNumber*)inp
{
    NoteRow* obj = [[NoteRow alloc] initWithDatabase:self.database table:table id:inp];
    return obj;
}

@end

@implementation NoteRow

@synthesize database;
@synthesize table;
@synthesize rowid;
@synthesize primaryKey;

- (id)initWithDatabase:(FMDatabase*)db table:(NSString*)tbl id:(NSNumber*)inp
{
    self = [super init];
    if (self)
    {
        self.database = db;
        self.table = tbl;
        self.rowid = inp;
        self.primaryKey = @"rowid";
    }
    return self;
}

- (NSDictionary *)data
{
    NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:self.database];
    NSArray* res = [ndb get:@{
                      @"table":self.table,
                      @"where":@{
                          self.primaryKey: self.rowid,
                      },
                  }];
    if ([res count] > 0)
    {
        NSMutableDictionary* final = [NSMutableDictionary dictionaryWithDictionary:[res objectAtIndex:0]];
        [final setObject:self.rowid forKey:self.primaryKey];
        return final;
    }
    return nil;
}

- (void)update:(NSDictionary*)params
{
    NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:self.database];
    [ndb set:@{
       @"update":params,
       @"where":@{
           self.primaryKey: self.rowid
       },
    }];
}

@end

