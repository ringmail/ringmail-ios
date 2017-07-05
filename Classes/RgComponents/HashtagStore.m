//
//  HashtagStore.m
//  ringmail
//
//  Created by Mark Baxter on 7/3/17.
//
//

#import "HashtagStore.h"
#import "NSString+MD5.h"
#import "NoteSQL.h"
#import "LinphoneManager.h"
#import <NSHash/NSString+NSHash.h>

@implementation HashtagStore
{
    BOOL database_block;
}

@synthesize dbqueue;

+ (instancetype)sharedInstance
{
    static HashtagStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[HashtagStore alloc] init];
        sharedInstance->database_block = NO;
        [sharedInstance setupDatabase];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    }
    return self;
}

- (void)setupDatabase
{
    NSString *path = @"ringmail_hashtag_store";
    path = [path stringByAppendingString:@"_v0.1.db"];
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    path = [docsPath stringByAppendingPathComponent:path];
    [self setDbqueue:[FMDatabaseQueue databaseQueueWithPath:path]];
    [self setupTables];
}

- (void)inDatabase:(void (^)(FMDatabase *db))block
{
    if (self->database_block)
    {
        block(self->database);
    }
    else
    {
        self->database_block = YES;
        [[self dbqueue] inDatabase:^(FMDatabase *db) {
            self->database = db;
            block(db);
            self->database = nil;
        }];
        self->database_block = NO;
    }
}

- (void)setupTables
{
    [[self dbqueue] inDatabase:^(FMDatabase *db) {
        NSArray *setup = [NSArray arrayWithObjects:
              @"CREATE TABLE IF NOT EXISTS hashtag_history ("
              "id INTEGER PRIMARY KEY NOT NULL, "
              "label varchar(128) NOT NULL, "
              "image varchar(128) NOT NULL, "
              "session_tag varchar(128) NOT NULL, "
              "selected datetime NOT NULL, "
              "type varchar(16) NOT NULL"
              ");",
              nil
              ];
        for (NSString *sql in setup)
        {
            [db executeStatements:sql];
            if ([db hadError])
            {
                NSLog(@"SQL Error: %@\nSQL:\n%@", [db lastErrorMessage], sql);
            }
        }
    }];
}


- (NSArray*)selectHistory
{
    NSMutableArray *array = [NSMutableArray array];
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT DISTINCT label, image, session_tag, type FROM hashtag_history ORDER BY selected DESC"];
        while ([rs next])
        {
            [array addObject:[rs resultDictionary]];
        }
        [rs close];
    }];
    
    return [array copy];
}


- (void)insertCardData:(NSDictionary*)cardData
{
    NSString *currentDateTime = [dateFormatter stringFromDate:[NSDate date]];
    
    [self inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT INTO hashtag_history (label, image, session_tag, selected, type) VALUES (?, ?, ?, ?, ?)",cardData[@"label"],cardData[@"image"],cardData[@"session_tag"],currentDateTime,@"hashtag"];
    }];
    
    [self refreshHistory];
}


- (void)refreshHistory
{
    [self inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM hashtag_history WHERE id NOT IN (SELECT DISTINCT id FROM hashtag_history ORDER BY selected DESC LIMIT 25)"];
        
    }];
}

@end
