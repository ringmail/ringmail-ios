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
#import "RKCall.h"
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
    path = [path stringByAppendingString:@"_v0.1.db"];
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
            @"DROP INDEX contact_id_1;",
            @"CREATE UNIQUE INDEX IF NOT EXISTS contact_id_1 ON rk_thread (contact_id, original_to);",
            @"CREATE INDEX IF NOT EXISTS address_md5_1 ON rk_thread (address_md5);",
            @"CREATE INDEX IF NOT EXISTS ts_activity_1 ON rk_thread (ts_activity);",
			
            @"CREATE TABLE IF NOT EXISTS rk_thread_item ("
                "id INTEGER PRIMARY KEY NOT NULL, "
				"thread_id INTEGER NOT NULL, "
				"message_id INTEGER NULL DEFAULT NULL, "
				"call_id INTEGER NULL DEFAULT NULL, "
				"hidden INTEGER NOT NULL DEFAULT 0, "
                "ts_created TEXT NOT NULL,"
                "version INTEGER DEFAULT 1"
			");",
            @"CREATE INDEX IF NOT EXISTS thread_id_1 ON rk_thread_item (thread_id);",
			@"CREATE INDEX IF NOT EXISTS call_id_1 ON rk_thread_item (call_id);",
			@"CREATE INDEX IF NOT EXISTS message_id_1 ON rk_thread_item (message_id);",
			
            @"CREATE TABLE IF NOT EXISTS rk_message ("
                "id INTEGER PRIMARY KEY NOT NULL, "
				"thread_id INTEGER NOT NULL, "
				"msg_body TEXT NOT NULL, "
				"msg_time TEXT NOT NULL, "
				"msg_inbound INTEGER NOT NULL, "
				"msg_uuid TEXT NOT NULL, "
				"msg_status INTEGER NOT NULL DEFAULT '', "
				"msg_type TEXT DEFAULT 'text/plain', "
				"msg_class TEXT DEFAULT '', "
				"msg_local_path TEXT DEFAULT NULL, "
				"msg_remote_url TEXT DEFAULT NULL"
			");",
            @"CREATE INDEX IF NOT EXISTS msg_uuid_1 ON rk_message (msg_uuid);",
			
			@"CREATE TABLE IF NOT EXISTS rk_call ("
                "id INTEGER PRIMARY KEY NOT NULL, "
                "thread_id INTEGER NOT NULL, "
                "call_video INTEGER DEFAULT 0, "
                "call_duration INTEGER DEFAULT 0, "
                "call_inbound INTEGER NOT NULL, "
                "call_sip TEXT NOT NULL, "
                "call_status TEXT NOT NULL DEFAULT '', "
                "call_result TEXT NOT NULL DEFAULT '', "
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
}

- (void)updateItem:(RKItem*)item
{
	[self dbBlock:^(NoteDatabase *ndb) {
		[item updateItem:ndb];
		[item updateVersion:ndb];
	}];
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
		//NSLog(@"Insert: %@", insert);
		[self dbBlock:^(NoteDatabase *ndb) {
			[ndb set:@{
				@"table": @"rk_thread",
				@"insert": insert,
			}];
			thread.threadId = [ndb lastInsertId];
		}];
	}
}

- (void)dumpThreads
{
	__block NSMutableArray *result = [NSMutableArray array];
	[[self dbqueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *rs = [db executeQuery:@"SELECT * FROM rk_thread ORDER BY id ASC"];
		while ([rs next])
        {
			NSDictionary* row = [rs resultDictionary];
			[result addObject:row];
		}
		[rs close];
	}];
	NSLog(@"%s: %@", __PRETTY_FUNCTION__, result);
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
				"ti.id AS item_id, "
				"ti.ts_created AS ts_created, "
				"ti.version AS version, "
				"m.id AS message_id, "
				"m.msg_body AS msg_body, "
				"m.msg_type AS msg_type, "
				"m.msg_class AS msg_class, "
				"m.msg_uuid AS msg_uuid, "
				"m.msg_inbound AS msg_inbound, "
				"c.id AS call_id, "
				"c.call_sip AS call_sip, "
				"c.call_duration AS call_duration, "
				"c.call_video AS call_video, "
				"c.call_uuid AS call_uuid, "
				"c.call_inbound AS call_inbound, "
				"c.call_result AS call_result "
            "FROM ("
				"SELECT t.id AS thread_id, t.address, t.contact_id, t.original_to, t.uuid, "
				"(SELECT i.id FROM rk_thread_item i WHERE i.thread_id=t.id AND i.hidden = 0 ORDER BY i.id DESC LIMIT 1) as item_id "
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
            //NSLog(@"%s Row: %@", __PRETTY_FUNCTION__, row);
			RKContact* ct;
			RKAddress* addr = [RKAddress newWithString:row[@"address"]];
			if (NILIFNULL(row[@"contact_id"]) != nil)
			{
				ct = [RKContact newWithData:@{
					@"contactId": row[@"contact_id"],
    				@"addressList": @[addr],
				}];
			}
			else
			{
				ct = [RKContact newByMatchingAddress:addr];
			}
			NSMutableDictionary* thrdata = [NSMutableDictionary dictionaryWithDictionary:@{
				@"threadId": row[@"thread_id"],
				@"remoteAddress": addr,
				@"contact": ct,
				@"uuid": row[@"uuid"],
			}];
			if (! [row[@"original_to"] isEqualToString:@""])
			{
				thrdata[@"originalTo"] = [RKAddress newWithString:row[@"original_to"]];
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
					@"direction": row[@"msg_inbound"],
					@"class": row[@"msg_class"],
					@"uuid": row[@"msg_uuid"],
				};
			}
			else if (NILIFNULL(row[@"call_id"]) != nil)
			{
				itemType = @"call";
				detail = @{
					@"id": row[@"call_id"],
					@"sip": row[@"call_sip"],
					@"duration": row[@"call_duration"],
					@"direction": row[@"call_inbound"],
					@"video": row[@"call_video"],
					@"result": row[@"call_result"],
					@"uuid": row[@"call_uuid"],
				};
			}
			NSDate* dt = [NSDate date];
			NSNumber* curId = @0;
			NSNumber* ver = @0;
			if (! [itemType isEqualToString:@"none"])
			{
				dt = [NSDate parse:row[@"ts_created"]];
				curId = row[@"item_id"];
				ver = row[@"version"];
			}
			NSDictionary* res = @{
				@"thread": thr,
				@"type": itemType,
				@"detail": detail,
				@"item_id": curId,
				@"version": ver,
				@"timestamp": dt,
			};
			[result addObject:res];
		}
		[rs close];
	}];
	return result;
}

- (NSArray*)listThreadItems:(RKThread*)thread
{
	return [self listThreadItems:thread lastItemId:nil];
}

- (NSArray*)listThreadItems:(RKThread*)thread lastItemId:(NSNumber*)lastItemId
{
	NSAssert(thread.threadId != nil, @"Undefined thread id");
	__block NSMutableArray *result = [NSMutableArray array];
	[[self dbqueue] inDatabase:^(FMDatabase *db) {
		NSString *sql = @""
            "SELECT "
				"ti.id AS item_id, "
				"ti.ts_created AS ts_created, "
				"ti.version AS version, "
				"m.id AS message_id, "
				"m.msg_body AS msg_body, "
				"m.msg_type AS msg_type, "
				"m.msg_inbound AS msg_inbound, "
				"m.msg_uuid AS msg_uuid, "
				"m.msg_status AS msg_status, "
				"m.msg_class AS msg_class, "
				"m.msg_remote_url AS msg_remote_url, "
				"m.msg_local_path AS msg_local_path, "
				"c.id AS call_id, "
				"c.call_sip AS call_sip, "
				"c.call_duration AS call_duration, "
				"c.call_inbound AS call_inbound, "
				"c.call_video AS call_video, "
				"c.call_status AS call_status, "
				"c.call_result AS call_result, "
				"c.call_time AS call_time, "
				"c.call_uuid AS call_uuid "
            "FROM rk_thread_item ti "
            "LEFT JOIN rk_message m ON m.id=ti.message_id "
            "LEFT JOIN rk_call c ON c.id=ti.call_id ";
		FMResultSet *rs;
		if (lastItemId != nil)
		{
    		sql = [sql stringByAppendingString:@""
    			"WHERE ti.thread_id=? "
    			"AND ti.id > ? "
    			"AND ti.hidden = 0 "
				"ORDER BY ti.id ASC"
			];
			//NSLog(@"SQL: %@", sql);
			rs = [db executeQuery:sql, thread.threadId, lastItemId];
		}
		else
		{
    		sql = [sql stringByAppendingString:@""
    			"WHERE ti.thread_id=? "
    			"AND ti.hidden = 0 "
				"ORDER BY ti.id ASC"
			];
			rs = [db executeQuery:sql, thread.threadId];
		}
		while ([rs next])
        {
			NSDictionary* row = [rs resultDictionary];
            //NSLog(@"%s Row: %@", __PRETTY_FUNCTION__, row);
			if (NILIFNULL(row[@"message_id"]) != nil)
			{
				NSMutableDictionary* param = [NSMutableDictionary dictionaryWithDictionary:@{
					@"class": row[@"msg_class"],
					@"itemId": row[@"item_id"],
					@"messageId": row[@"message_id"],
					@"version": row[@"version"],
					@"thread": thread,
					@"uuid": row[@"msg_uuid"],
					@"timestamp": [NSDate parse:row[@"ts_created"]],
					@"direction": row[@"msg_inbound"],
					@"body": row[@"msg_body"],
					@"deliveryStatus": row[@"msg_status"],
					@"mediaType": row[@"msg_type"],
				}];
				if (NILIFNULL(row[@"msg_remote_url"]) != nil)
				{
					param[@"remoteURL"] = [NSURL URLWithString:row[@"msg_remote_url"]];
				}
				if (NILIFNULL(row[@"msg_local_path"]) != nil)
				{
					param[@"localPath"] = row[@"msg_local_path"];
				}
				RKMessage* msg = [RKMessage newWithData:param];
				[result addObject:msg];
			}
			else if (NILIFNULL(row[@"call_id"]) != nil)
			{
				//NSLog(@"Call Item: %@", row);
				RKCall* call = [RKCall newWithData:@{
    				@"uuid": row[@"call_uuid"],
    				@"thread": thread,
					@"version": row[@"version"],
    				@"itemId": row[@"item_id"],
    				@"callId": row[@"call_id"],
    				@"direction": row[@"call_inbound"],
    				@"video": row[@"call_video"],
    				@"sipId": row[@"call_sip"],
    				@"timestamp": [NSDate parse:row[@"call_time"]],
    				@"duration": row[@"call_duration"],
    				@"callResult": row[@"call_result"],
    				@"callStatus": row[@"call_status"],
    			}];
				[result addObject:call];
			}
		}
		[rs close];
	}];
	//NSLog(@"%s: Thread Items: %@", __PRETTY_FUNCTION__, result);
	return result;
}

- (RKThread*)getThreadByAddress:(RKAddress*)remoteAddress orignalTo:(RKAddress*)origTo contactId:(NSNumber*)ctid uuid:(NSString*)uuid
{
	//NSLog(@"%s: address:%@ originalTo:%@ contactId:%@ uuid:%@", __PRETTY_FUNCTION__, remoteAddress.address, origTo, ctid, uuid);
    __block RKThread* result = nil;
	__block NSString* from = remoteAddress.address;
	__block NSString* originalTo = (origTo != nil) ? origTo.address : @"";
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
				curContact = [rs1 objectForColumnIndex:3];
				curOrigTo = [rs1 stringForColumnIndex:4];
                found = YES;
    		}
    		[rs1 close];
		}
		if ((! found) && (contactId != nil))
		{
            FMResultSet *rs2 = [db executeQuery:@"SELECT id, uuid, address, contact_id, original_to FROM rk_thread WHERE contact_id = ? COLLATE NOCASE AND original_to = ? COLLATE NOCASE", contactId, originalTo];
    		if ([rs2 next])
    		{
				NSLog(@"Found contact_id");
				curId = [NSNumber numberWithLong:[rs2 longForColumnIndex:0]];
				curUUID = [rs2 stringForColumnIndex:1];
				curAddress = [rs2 stringForColumnIndex:2];
				curContact = [rs2 objectForColumnIndex:3];
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
				curContact = [rs3 objectForColumnIndex:3];
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
			params[@"originalTo"] = [RKAddress newWithString:curOrigTo];
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

- (RKThread*)getThreadById:(NSNumber*)lookupId
{
	//NSLog(@"%s: address:%@ originalTo:%@ contactId:%@ uuid:%@", __PRETTY_FUNCTION__, remoteAddress.address, origTo, ctid, uuid);
	NSAssert(lookupId, @"lookupId required");
	__block BOOL found = NO;
	__block NSNumber *curId = nil;
	__block NSString *curUUID = nil;
	__block NSString *curAddress = nil;
	__block NSNumber *curContact = nil;
	__block NSString *curOrigTo = @"";
    [[self dbqueue] inDatabase:^(FMDatabase *db) {
        FMResultSet *rs1 = [db executeQuery:@"SELECT id, uuid, address, contact_id, original_to FROM rk_thread WHERE id = ? COLLATE NOCASE", lookupId];
		if ([rs1 next])
		{
			curId = [NSNumber numberWithLong:[rs1 longForColumnIndex:0]];
			curUUID = [rs1 stringForColumnIndex:1];
			curAddress = [rs1 stringForColumnIndex:2];
			curContact = [rs1 objectForColumnIndex:3];
			curOrigTo = [rs1 stringForColumnIndex:4];
            found = YES;
		}
		[rs1 close];
	}];
    RKThread* result = nil;
	if (found)
	{
		NSMutableDictionary* params = [NSMutableDictionary dictionary];
		params[@"remoteAddress"] = [RKAddress newWithString:curAddress];
		params[@"threadId"] = curId;
		params[@"uuid"] = curUUID;
		if (! [curOrigTo isEqualToString:@""])
		{
			params[@"originalTo"] = [RKAddress newWithString:curOrigTo];
		}
		if ([curContact isKindOfClass:[NSNull class]])
	 	{
			params[@"contact"] = [RKContact newWithData:@{@"addressList": @[params[@"remoteAddress"]]}];
		}
		else
		{
			params[@"contact"] = [RKContact newWithData:@{@"contactId": curContact, @"addressList": @[params[@"remoteAddress"]]}];
		}
		result = [RKThread newWithData:params];
	}
    return result;
}

- (RKCall*)getCallBySipId:(NSString*)sip
{
	__block RKCall* result = nil;
	[[self dbqueue] inDatabase:^(FMDatabase *db) {
		FMResultSet *rs = [db executeQuery:@""
            "SELECT "
				"t.id AS thread_id, "
				"t.address AS address, "
				"t.contact_id AS contact_id, "
				"t.original_to AS original_to, "
				"t.uuid AS uuid, "
				"ti.id AS item_id, "
				"ti.version AS version, "
				"c.id AS call_id, "
				"c.call_duration AS call_duration, "
				"c.call_inbound AS call_inbound, "
				"c.call_video AS call_video, "
				"c.call_sip AS call_sip, "
				"c.call_status AS call_status, "
				"c.call_result AS call_result, "
				"c.call_time AS call_time, "
				"c.call_uuid AS call_uuid "
            "FROM rk_call c, rk_thread t, rk_thread_item ti "
			"WHERE c.call_sip = ? "
            "AND t.id = c.thread_id "
            "AND ti.call_id = c.id",
			sip
		];
		while ([rs next])
        {
			NSDictionary* row = [rs resultDictionary];
            //NSLog(@"%s Row: %@", __PRETTY_FUNCTION__, row);
			RKContact* ct;
			RKAddress* addr = [RKAddress newWithString:row[@"address"]];
			if (NILIFNULL(row[@"contact_id"]) != nil)
			{
				ct = [RKContact newWithData:@{
					@"contactId": row[@"contact_id"],
    				@"addressList": @[addr],
				}];
			}
			else
			{
				ct = [RKContact newByMatchingAddress:addr];
			}
			NSMutableDictionary* thrdata = [NSMutableDictionary dictionaryWithDictionary:@{
				@"threadId": row[@"thread_id"],
				@"remoteAddress": addr,
				@"contact": ct,
				@"uuid": row[@"uuid"],
			}];
			if (! [row[@"original_to"] isEqualToString:@""])
			{
				thrdata[@"originalTo"] = [RKAddress newWithString:row[@"original_to"]];
			}
			RKThread* thr = [RKThread newWithData:thrdata];
			result = [RKCall newWithData:@{
				@"uuid": row[@"call_uuid"],
				@"thread": thr,
				@"version": row[@"version"],
				@"itemId": row[@"item_id"],
				@"callId": row[@"call_id"],
				@"direction": row[@"call_inbound"],
				@"video": row[@"call_video"],
				@"sipId": row[@"call_sip"],
				@"timestamp": [NSDate parse:row[@"call_time"]],
				@"duration": row[@"call_duration"],
				@"callResult": row[@"call_result"],
				@"callStatus": row[@"call_status"],
			}];
		}
		[rs close];
	}];
	return result;
}

- (RKMessage*)getMessageByUUID:(NSString*)inputUUID
{
	__block RKMessage *result = nil;
	[[self dbqueue] inDatabase:^(FMDatabase *db) {
		NSString *sql = @""
            "SELECT "
				"t.id AS thread_id, "
				"t.address AS address, "
				"t.contact_id AS contact_id, "
				"t.original_to AS original_to, "
				"t.uuid AS uuid, "
				"ti.id AS item_id, "
				"ti.ts_created AS ts_created, "
				"ti.version AS version, "
				"m.id AS message_id, "
				"m.msg_body AS msg_body, "
				"m.msg_type AS msg_type, "
				"m.msg_inbound AS msg_inbound, "
				"m.msg_uuid AS msg_uuid, "
				"m.msg_status AS msg_status, "
				"m.msg_class AS msg_class, "
				"m.msg_remote_url AS msg_remote_url, "
				"m.msg_local_path AS msg_local_path "
            "FROM rk_message m, rk_thread_item ti, rk_thread t "
            "WHERE m.id=ti.message_id AND m.thread_id = t.id "
            "AND m.msg_uuid = ?";
		FMResultSet *rs = [db executeQuery:sql, inputUUID];
		while ([rs next])
        {
			NSDictionary* row = [rs resultDictionary];
            //NSLog(@"%s Row: %@", __PRETTY_FUNCTION__, row);
			RKContact* ct;
			RKAddress* addr = [RKAddress newWithString:row[@"address"]];
			if (NILIFNULL(row[@"contact_id"]) != nil)
			{
				ct = [RKContact newWithData:@{
					@"contactId": row[@"contact_id"],
    				@"addressList": @[addr],
				}];
			}
			else
			{
				ct = [RKContact newByMatchingAddress:addr];
			}
			NSMutableDictionary* thrdata = [NSMutableDictionary dictionaryWithDictionary:@{
				@"threadId": row[@"thread_id"],
				@"remoteAddress": addr,
				@"contact": ct,
				@"uuid": row[@"uuid"],
			}];
			if (! [row[@"original_to"] isEqualToString:@""])
			{
				thrdata[@"originalTo"] = [RKAddress newWithString:row[@"original_to"]];
			}
			RKThread* thr = [RKThread newWithData:thrdata];
			if (NILIFNULL(row[@"message_id"]) != nil)
			{
				NSMutableDictionary* param = [NSMutableDictionary dictionaryWithDictionary:@{
					@"class": row[@"msg_class"],
					@"itemId": row[@"item_id"],
					@"messageId": row[@"message_id"],
					@"version": row[@"version"],
					@"thread": thr,
					@"uuid": row[@"msg_uuid"],
					@"timestamp": [NSDate parse:row[@"ts_created"]],
					@"direction": row[@"msg_inbound"],
					@"body": row[@"msg_body"],
					@"deliveryStatus": row[@"msg_status"],
					@"mediaType": row[@"msg_type"],
				}];
				if (NILIFNULL(row[@"msg_remote_url"]) != nil)
				{
					param[@"remoteURL"] = [NSURL URLWithString:row[@"msg_remote_url"]];
				}
				if (NILIFNULL(row[@"msg_local_path"]) != nil)
				{
					param[@"localPath"] = row[@"msg_local_path"];
				}
				result = [RKMessage newWithData:param];
			}
		}
	}];
	return result;
}

- (void)setHidden:(BOOL)hidden forItemId:(NSNumber*)itemId
{
	[[self dbqueue] inDatabase:^(FMDatabase *db) {
		NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
		[ndb set:@{
			@"table": @"rk_thread_item",
			@"update": @{
				@"hidden": [NSNumber numberWithBool:hidden],
			},
			@"where": @{
				@"id": itemId,
			},
		}];
	}];
}

- (void)removeContact:(NSNumber*)contact
{
    [[self dbqueue] inDatabase:^(FMDatabase *db) {
		NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
		NoteRow *chatRow = [ndb row:@"rk_thread" where:@{@"contact_id": contact}];
		if (chatRow != nil)
		{
			[chatRow update:@{
				@"contact_id": [NSNull null],
			}];
		}
    }];
}

- (void)updateContact:(NSNumber*)contact changes:(NSDictionary*)changes
{
    [[self dbqueue] inDatabase:^(FMDatabase *db) {
		__block NoteDatabase *ndb = [[NoteDatabase alloc] initWithDatabase:db];
        [changes[@"change"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[ndb set:@{
				@"table": @"rk_thread",
				@"update": @{
					@"address": obj,
				},
				@"where": @{
					@"contact_id": contact,
					@"address": key,
				},
			}];
		}];
	    [changes[@"delete"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			[ndb set:@{
				@"table": @"rk_thread",
				@"update": @{
					@"contact_id": [NSNull null],
				},
				@"where": @{
					@"contact_id": contact,
					@"address": key,
				},
			}];
		}];
		[changes[@"add"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSString* sql = @"UPDATE rk_thread SET contact_id = ? WHERE contact_id IS NULL AND address = ?";
			[db executeUpdate:sql withArgumentsInArray:@[ contact, key ]];
		}];
    }];
}

@end
