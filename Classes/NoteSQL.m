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
        self.primaryKey = @"rowid";
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
    //NSLog(@"Note SQL: %@", sql);
    NSMutableArray* result = [NSMutableArray array];
    FMResultSet* rs = [database executeQuery:sql withArgumentsInArray:paramList];
    while ([rs next])
    {
        [result push:[rs resultDictionary]]; // Each array element is a dictionary (hash)
    }
    [rs close];
    return result;
}

- (NSObject*)set:(NSDictionary*)params
{
    NSString *table = [params objectForKey:@"table"];
    NSString *sql = [NSString string];
    NSMutableArray *paramList = [NSMutableArray array];
    id insert = [params objectForKey:@"insert"];
    id update = [params objectForKey:@"update"];
    id delete = [params objectForKey:@"delete"];
    if (insert)
    {
        return [self create:table data:insert];
    }
    else if (delete)
    {
        sql = [sql stringByAppendingString:[NSString stringWithFormat:@"DELETE FROM %@ ", table]];
        if ([delete isKindOfClass:[NSDictionary class]])
        {
            NSMutableArray *allKeys = [[delete allKeys] mutableCopy];
            [allKeys sortUsingSelector:@selector(caseInsensitiveCompare:)];
            NSString *whr = [[allKeys map:^(NSString* key) {
                [paramList push:[delete objectForKey:key]];
                return [NSString stringWithFormat:@"%@ = ?", key];
            }] join:@" AND "];
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@" WHERE (%@)", whr]];
        }
        else if ([delete isKindOfClass:[NSString class]])
        {
            sql = [sql stringByAppendingString:[NSString stringWithFormat:@" WHERE %@", delete]];
        }
        //NSLog(@"Note SQL: %@", sql);
        BOOL ok = [database executeUpdate:sql withArgumentsInArray:paramList];
        if (! ok)
        {
            NSLog(@"Note SQL Error");
            return [NSNumber numberWithBool:NO];
        }
        else
        {
            return [NSNumber numberWithBool:YES];
        }
    }
    else if (update)
    {
        sql = [sql stringByAppendingString:[NSString stringWithFormat:@"UPDATE %@ ", table]];
        id update = [params objectForKey:@"update"];
        NSMutableArray *updateKeys = [[update allKeys] mutableCopy];
        [updateKeys sortUsingSelector:@selector(caseInsensitiveCompare:)];
        NSString *upd = [[updateKeys map:^(NSString* key) {
            [paramList push:[update objectForKey:key]];
            return [NSString stringWithFormat:@"%@ = ?", key];
        }] join:@", "];
        sql = [sql stringByAppendingString:[NSString stringWithFormat:@"SET %@ ", upd]];
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
        //NSLog(@"Note SQL: %@", sql);
        BOOL ok = [database executeUpdate:sql withArgumentsInArray:paramList];
        if (! ok)
        {
            NSLog(@"Note SQL Error");
            return [NSNumber numberWithBool:NO];
        }
        else
        {
            return [NSNumber numberWithBool:YES];
        }
    }
    return nil;
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

- (NoteRow*)row:(NSString*)table where:(NSDictionary*)params
{
    NSArray *rowQuery = [self get:@{
                                    @"select":@[self.primaryKey],
                                    @"table":table,
                                    @"where":params,
                                    }];
    NSNumber* recid;
    if ([rowQuery count] > 0)
    {
        recid = [[rowQuery objectAtIndex:0] objectForKey:self.primaryKey];
        NoteRow* obj = [[NoteRow alloc] initWithDatabase:self.database table:table id:recid];
        return obj;
    }
    return nil;
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

@implementation NSDate (Strftime)

- (NSString*)strftime:(NSString*)format
{
    NSDate *date = [NSDate date];
    time_t time = [date timeIntervalSince1970];
    struct tm timeStruct;
    gmtime_r(&time, &timeStruct);
    char buffer[80];
    strftime(buffer, 80, [format cString], &timeStruct);
    NSString *dateStr = [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding];
    return dateStr;
}

- (NSString*)strftime
{
    return [self strftime:@"%F %TZ"];
}

+ (NSDate *)parse:(NSString *)input
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ssZ"];
    NSDate *result = [dateFormatter dateFromString:input];
    return result;
}

@end
