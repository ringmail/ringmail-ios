//
//  RKThreadStore.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKThreadStore.h"
#import "RKAddress.h"
#import "RKThread.h"
#import "RKContact.h"
#import "RKItem.h"
#import "RKMessage.h"

#import "NSString+MD5.h"
#import "NoteSQL.h"

@implementation RKThreadStore

@synthesize dbqueue;

+ (instancetype)sharedInstance
{
    static RKThreadStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RKThreadStore alloc] init];
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
	[self setDbqueue:[FMDatabaseQueue databaseQueueWithPath:path]];
	[self setupTables];
}

- (void)dbBlock:(void (^)(NoteDatabase *ndb))block
{
	[[self dbqueue] inDatabase:^(FMDatabase *db) {
		NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
		block(ndb);
	}];
}

- (void)setupTables
{
    [[self dbqueue] inDatabase:^(FMDatabase *db) {
        NSArray *setup = [NSArray arrayWithObjects:
			// Reset database
            //@"DROP TABLE rk_thread;",
            //@"DROP TABLE rk_thread_item;",
            //@"DROP TABLE rk_message;",
            //@"DROP TABLE rk_call;",
			
            @"CREATE TABLE IF NOT EXISTS rk_thread ("
                "id INTEGER PRIMARY KEY NOT NULL, "
				"uuid TEXT NOT NULL, "
				"address TEXT NOT NULL, "
				"address_md5 TEXT NOT NULL, "
                "contact_id INTEGER NULL DEFAULT NULL, "
				"original_to TEXT NOT NULL DEFAULT '', "
                "ts_activity TEXT NOT NULL, "
                "unread INTEGER NOT NULL DEFAULT 0"
            ");",
            @"CREATE UNIQUE INDEX IF NOT EXISTS uuid_1 ON rk_thread (uuid);",
            @"CREATE UNIQUE INDEX IF NOT EXISTS address_1 ON rk_thread (address, original_to);",
            @"CREATE UNIQUE INDEX IF NOT EXISTS contact_id_1 ON rk_thread (contact_id);",
            @"CREATE INDEX IF NOT EXISTS address_md5_1 ON rk_thread (address_md5);",
            @"CREATE INDEX IF NOT EXISTS ts_activity_1 ON rk_thread (ts_activity);",
			
            @"CREATE TABLE IF NOT EXISTS rk_thread_item ("
                "id INTEGER PRIMARY KEY NOT NULL, "
				"thread_id INTEGER NOT NULL, "
				"message_id INTEGER NULL DEFAULT NULL, "
				"call_id INTEGER NULL DEFAULT NULL, "
                "ts_created TEXT NOT NULL"
			");",
            @"CREATE INDEX IF NOT EXISTS thread_id_1 ON rk_thread_item (thread_id);",
			
            @"CREATE TABLE IF NOT EXISTS rk_message ("
                "id INTEGER PRIMARY KEY NOT NULL, "
				"thread_id INTEGER NOT NULL, "
				"msg_body TEXT NOT NULL, "
				"msg_time TEXT NOT NULL, "
				"msg_inbound INTEGER NOT NULL, "
				"msg_uuid TEXT NOT NULL, "
				"msg_status TEXT NOT NULL DEFAULT '', "
				"msg_data BLOB DEFAULT NULL, "
				"msg_thumbnail BLOB DEFAULT NULL, "
				"msg_type TEXT DEFAULT 'text/plain', "
				"msg_url TEXT DEFAULT NULL"
			");",
            @"CREATE INDEX IF NOT EXISTS msg_uuid_1 ON rk_message (msg_uuid);",
			
			@"CREATE TABLE IF NOT EXISTS rk_call ("
                "id INTEGER PRIMARY KEY NOT NULL, "
                "thread_id INTEGER NOT NULL, "
                "call_duration INTEGER DEFAULT 0, "
                "call_inbound INTEGER NOT NULL, "
                "call_sip TEXT NOT NULL, "
                "call_state TEXT NOT NULL, "
                "call_status TEXT, "
                "call_time TEXT NOT NULL, "
                "call_uuid TEXT"
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
    //[[self dbqueue] close];
    NSLog(@"%s: SQL Database Ready", __PRETTY_FUNCTION__);
}

- (void)insertItem:(RKItem*)item
{
	NSAssert(item.thread, @"RKItem must be part of a thread");
	NSAssert(item.thread.remoteAddress, @"RKThread must have an address");
	if (item.thread.threadId == nil)
	{
		[self insertThread:item.thread];
	}
	[self dbBlock:^(NoteDatabase *ndb) {
		[item insertItem:ndb];
	}];
	//[[self dbqueue] close];
}

- (void)insertThread:(RKThread*)thread
{
	if (thread.threadId == nil)
	{
		__block NSNumber* contactId = nil;
		if (thread.contact && thread.contact.contactId)
		{
			contactId = thread.contact.contactId;
		}
		__block NSString* originalTo = @"";
		if (thread.originalTo)
		{
			originalTo = thread.originalTo.address;
		}
		NSDictionary* insert = @{
			@"uuid": thread.uuid,
			@"address": thread.remoteAddress.address,
			@"address_md5": [thread.remoteAddress.address md5HexDigest],
			@"contact_id": (contactId) ? contactId : [NSNull null],
			@"original_to": originalTo,
			@"ts_activity": [[NSDate date] strftime],
			@"unread": [NSNumber numberWithInt:0],
		};
		NSLog(@"Insert: %@", insert);
		[self dbBlock:^(NoteDatabase *ndb) {
			[ndb set:@{
				@"table": @"rk_thread",
				@"insert": insert,
			}];
			thread.threadId = [ndb lastInsertId];
		}];
	}
}

- (NSArray*)listThreads
{
	__block NSMutableArray *result = [NSMutableArray array];
	[[self dbqueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *rs = [db executeQuery:@""
            "SELECT "
				"l.thread_id AS thread_id, "
				"l.address AS address, "
				"l.contact_id AS contact_id, "
				"l.original_to AS original_to, "
				"l.uuid AS uuid, "
				"ti.ts_created AS ts_created, "
				"m.id AS message_id, "
				"m.msg_body AS msg_body, "
				"m.msg_type AS msg_type, "
				"c.id AS call_id, "
				"c.call_sip AS call_sip, "
				"c.call_duration AS call_duration "
            "FROM ("
				"SELECT t.id AS thread_id, t.address, t.contact_id, t.original_to, t.uuid, "
				"(SELECT i.id FROM rk_thread_item i WHERE i.thread_id=t.id ORDER BY i.id DESC LIMIT 1) as item_id "
                "FROM rk_thread t"
            ") AS l "
            "LEFT JOIN rk_thread_item ti ON ti.id = l.item_id "
            "LEFT JOIN rk_message m ON m.id=ti.message_id "
            "LEFT JOIN rk_call c ON c.id=ti.call_id "
            "ORDER BY l.item_id DESC, l.thread_id DESC"
		];
		while ([rs next])
        {
			NSDictionary* row = [rs resultDictionary];
            NSLog(@"%s Row: %@", __PRETTY_FUNCTION__, row);
			RKAddress* addr = [RKAddress newWithAddress:row[@"address"]];
			NSMutableDictionary* ctdata = [NSMutableDictionary dictionaryWithDictionary:@{
				@"addressList": @[addr],
			}];
			if (NILIFNULL(row[@"contact_id"]) != nil)
			{
				ctdata[@"contactId"] = row[@"contact_id"];
			}
			RKContact* ct = [RKContact newWithData:ctdata];
			NSMutableDictionary* thrdata = [NSMutableDictionary dictionaryWithDictionary:@{
				@"threadId": row[@"thread_id"],
				@"remoteAddress": addr,
				@"contact": ct,
				@"uuid": row[@"uuid"],
			}];
			if (! [row[@"original_to"] isEqualToString:@""])
			{
				thrdata[@"originalTo"] = row[@"original_to"];
			}
			RKThread* thr = [RKThread newWithData:thrdata];
			NSString* itemType = @"none";
			NSDictionary* detail = @{};
			if (NILIFNULL(row[@"message_id"]) != nil)
			{
				itemType = @"message";
				detail = @{
					@"id": row[@"message_id"],
					@"body": row[@"msg_body"],
					@"type": row[@"msg_type"],
				};
			}
			else if (NILIFNULL(row[@"call_id"]) != nil)
			{
				itemType = @"call";
				detail = @{
					@"id": row[@"call_id"],
					@"sip": row[@"call_sip"],
					@"duration": row[@"call_duration"],
				};
			}
			NSDictionary* res = @{
				@"thread": thr,
				@"type": itemType,
				@"detail": detail,
			};
			[result addObject:res];
		}
		[rs close];
	}];
	return result;
}

- (NSArray*)listThreadItems
{
	__block NSMutableArray *result = [NSMutableArray array];
	
	return result;
}

- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress orignalTo:(RKAddress*)origTo contactId:(NSNumber*)ctid uuid:(NSString*)uuid
{
	NSLog(@"%s: address:%@ originalTo:%@ contactId:%@ uuid:%@", __PRETTY_FUNCTION__, remoteAddress.address, origTo, ctid, uuid);
    __block RKThread* result = nil;
	__block NSString* from = remoteAddress.address;
	__block NSString* originalTo = (origTo) ? origTo.address : @"";
	__block NSNumber* contactId = ctid;
	__block BOOL found = NO;
	__block NSNumber *curId = nil;
	__block NSString *curUUID = nil;
	__block NSString *curAddress = nil;
	__block NSNumber *curContact = nil;
	__block NSString *curOrigTo = @"";
    [[self dbqueue] inDatabase:^(FMDatabase *db) {
		if (uuid)
		{
            FMResultSet *rs1 = [db executeQuery:@"SELECT id, uuid, address, contact_id, original_to FROM rk_thread WHERE uuid = ? COLLATE NOCASE", uuid];
    		if ([rs1 next])
    		{
				NSLog(@"Found uuid");
				curId = [NSNumber numberWithLong:[rs1 longForColumnIndex:0]];
				curUUID = [rs1 stringForColumnIndex:1];
				curAddress = [rs1 stringForColumnIndex:2];
				curContact = [NSNumber numberWithLong:[rs1 longForColumnIndex:3]];
				curOrigTo = [rs1 stringForColumnIndex:4];
                found = YES;
    		}
    		[rs1 close];
		}
		if ((! found) && (contactId != nil))
		{
            FMResultSet *rs2 = [db executeQuery:@"SELECT id, uuid, address, contact_id, original_to FROM rk_thread WHERE contact_id = ? COLLATE NOCASE", contactId];
    		if ([rs2 next])
    		{
				NSLog(@"Found contact_id");
				curId = [NSNumber numberWithLong:[rs2 longForColumnIndex:0]];
				curUUID = [rs2 stringForColumnIndex:1];
				curAddress = [rs2 stringForColumnIndex:2];
				curContact = [NSNumber numberWithLong:[rs2 longForColumnIndex:3]];
				curOrigTo = [rs2 stringForColumnIndex:4];
                found = YES;
    		}
    		[rs2 close];
		}
		if (! found)
		{
            FMResultSet *rs3 = [db executeQuery:@"SELECT id, uuid, address, contact_id, original_to FROM rk_thread WHERE address = ? COLLATE NOCASE AND original_to = ? COLLATE NOCASE", from, originalTo];
            if ([rs3 next])
            {
				NSLog(@"Found address, originalTo");
				curId = [NSNumber numberWithLong:[rs3 longForColumnIndex:0]];
				curUUID = [rs3 stringForColumnIndex:1];
				curAddress = [rs3 stringForColumnIndex:2];
				curContact = [NSNumber numberWithLong:[rs3 longForColumnIndex:3]];
				curOrigTo = [rs3 stringForColumnIndex:4];
                found = YES;
            }
			[rs3 close];
		}
	}];
	if (found)
	{
		NSMutableDictionary* params = [NSMutableDictionary dictionary];
		params[@"remoteAddress"] = remoteAddress;
		params[@"threadId"] = curId;
		params[@"uuid"] = curUUID;
		if (! [curOrigTo isEqualToString:@""])
		{
			params[@"originalTo"] = [RKAddress newWithAddress:curOrigTo];
		}
		
		// Check for any needed updates
		BOOL update = NO;
		NSMutableDictionary *updates = [NSMutableDictionary dictionary];
		if (uuid != nil)
		{
			if (! [uuid isEqualToString:curUUID])
			{
				updates[@"uuid"] = uuid; // New UUID from server
				update = YES;
				params[@"uuid"] = uuid;
			}
		}
		if (contactId != nil)
		{
			if (! [contactId isEqualToNumber:curContact])
			{
				updates[@"contact_id"] = contactId;
				update = YES;
			}
			params[@"contact"] = [RKContact newWithData:@{@"contactId": contactId, @"addressList": @[remoteAddress]}];
		}
		else
		{
			if (! [curContact isKindOfClass:[NSNull class]]) // Input contact nil but database not so clear out contact (require match on server-side)
    		{
    			updates[@"contact_id"] = [NSNull null];
    			update = YES;
				params[@"contact"] = [RKContact newWithData:@{@"addressList": @[remoteAddress]}];
    		}
			else
			{
				params[@"contact"] = [RKContact newWithData:@{@"contactId": curContact, @"addressList": @[remoteAddress]}];
			}
		}
		if (! [from isEqualToString:curAddress])
		{
			updates[@"address"] = from;
			update = YES;
		}
		if (update)
		{
			[self dbBlock:^(NoteDatabase* ndb) {
    		    [ndb set:@{
                    @"table": @"rk_thread",
                    @"update": updates,
                    @"where": @{
                        @"id": curId,
                    },
                }];
			}];
		}
		result = [RKThread newWithData:params];
	}
	else // Create new thread
	{
        NSLog(@"Create new thread");
		NSMutableDictionary* params = [NSMutableDictionary dictionary];
		params[@"remoteAddress"] = remoteAddress;
		if (origTo)
		{
			params[@"originalTo"] = origTo;
		}
		if (uuid)
		{
			params[@"uuid"] = uuid;
		}
		if (contactId != nil)
		{
			params[@"contact"] = [RKContact newWithData:@{@"contactId": contactId, @"addressList": @[remoteAddress]}];
		}
		else
		{
			params[@"contact"] = [RKContact newWithData:@{@"addressList": @[remoteAddress]}];
		}
		result = [RKThread newWithData:params];
		[self insertThread:result];
	}
    //[[self dbqueue] close];
    return result;
}

@end
