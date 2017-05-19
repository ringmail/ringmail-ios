//
//  RKMessageStore.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKMessageStore.h"
#import "RKItem.h"
#import "RKThread.h"
#import "RKContact.h"

#import "NoteSQL.h"

@implementation RKMessageStore

@synthesize databaseQueue;

+ (instancetype)sharedInstance
{
    static RKMessageStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RKMessageStore alloc] init];
		[sharedInstance setupDatabase];
    });
    return sharedInstance;
}

- (void)setupDatabase
{
	NSString *path = @"ringmail_message_store";
    path = [path stringByAppendingString:@"_v1.db"];
	NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
	path = [docsPath stringByAppendingPathComponent:path];
	databaseQueue = [FMDatabaseQueue databaseQueueWithPath:path];
	[self setupTables];
}

- (void)setupTables
{
	FMDatabaseQueue* dbq = databaseQueue;
    [dbq inDatabase:^(FMDatabase *db) {
        NSArray *setup = [NSArray arrayWithObjects:
			// Reset database
            //@"DROP TABLE rk_thread;",
            //@"DROP TABLE rk_message;",
			
            @"CREATE TABLE IF NOT EXISTS rk_thread ("
                "id INTEGER PRIMARY KEY NOT NULL,"
				"uuid TEXT NOT NULL,"
				"address TEXT NOT NULL,"
				"address_md5 TEXT NOT NULL,"
                "contact_id INTEGER NULL DEFAULT NULL,"
				"original_to TEXT NULL DEFAULT NULL,"
                "ts_activity TEXT NOT NULL,"
                "unread INTEGER NOT NULL DEFAULT 0,"
            ");",
            @"CREATE UNIQUE INDEX IF NOT EXISTS uuid_1 ON rk_thread (uuid);",
            @"CREATE UNIQUE INDEX IF NOT EXISTS address_1 ON rk_thread (address, original_to);",
            @"CREATE UNIQUE INDEX IF NOT EXISTS contact_id_1 ON rk_thread (contact_id);",
            @"CREATE INDEX IF NOT EXISTS address_md5_1 ON rk_thread (address_md5);",
            @"CREATE INDEX IF NOT EXISTS ts_activity_1 ON rk_thread (ts_activity);",
			
            @"CREATE TABLE IF NOT EXISTS rk_thread_entry ("
                "id INTEGER PRIMARY KEY NOT NULL,"
				"thread_id INTEGER NOT NULL,"
				"message_id INTEGER NULL DEFAULT NULL,"
				"call_id INTEGER NULL DEFAULT NULL,"
                "ts_created TEXT NOT NULL,"
			");",
            @"CREATE INDEX IF NOT EXISTS thread_id_1 ON rk_thread_entry (thread_id);",
			
            @"CREATE TABLE IF NOT EXISTS rk_message ("
                "id INTEGER PRIMARY KEY NOT NULL,"
				"thread_id INTEGER NOT NULL,"
				"msg_body TEXT NOT NULL,"
				"msg_time TEXT NOT NULL,"
				"msg_inbound INTEGER,"
				"msg_uuid TEXT NOT NULL,"
				"msg_status TEXT NOT NULL DEFAULT '',"
				"msg_data BLOB DEFAULT NULL,"
				"msg_thumbnail BLOB DEFAULT NULL,"
				"msg_type TEXT DEFAULT 'text/plain',"
				"msg_url TEXT DEFAULT NULL"
			");",
            @"CREATE INDEX IF NOT EXISTS msg_uuid_1 ON rk_message (msg_uuid);",
			
			@"CREATE TABLE IF NOT EXISTS rk_call ("
                "id INTEGER PRIMARY KEY NOT NULL,"
                "thread_id INTEGER NOT NULL"
                "call_duration INTEGER DEFAULT 0,"
                "call_inbound INTEGER NOT NULL DEFAULT 0,"
                "call_sip TEXT NOT NULL,"
                "call_state TEXT NOT NULL,"
                "call_status TEXT,"
                "call_time TEXT NOT NULL,"
                "call_uuid TEXT,"
            ");",
            @"CREATE INDEX IF NOT EXISTS call_sip_1 ON rk_call (call_sip);",
            @"CREATE INDEX IF NOT EXISTS call_uuid_1 ON rk_call (call_uuid);",
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
    [dbq close];
    NSLog(@"%s: SQL Database Ready", __PRETTY_FUNCTION__);
}

- (void)addActivity:(RKItem*)item
{
	if (item.thread)
	{
		RKThread* currentThread = item.thread;
		NSLog(@"Add %@ to thread %@", item, currentThread);
	}
	else // No thread, create one
	{
	}
}

/*
- (RKThread*)createThread:(RKContact*)contact
{
}
*/

@end
