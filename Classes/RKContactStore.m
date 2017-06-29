//
//  RKContactStore.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKContactStore.h"
#import "RKThreadStore.h"

#import "NSString+MD5.h"
#import "NoteSQL.h"
#import "LinphoneManager.h"
#import <NSHash/NSString+NSHash.h>

@implementation RKContactStore
{
	BOOL database_block;
}

@synthesize dbqueue;

+ (instancetype)sharedInstance
{
    static RKContactStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedInstance = [[RKContactStore alloc] init];
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
	NSString *path = @"ringmail_contact_store";
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
			// Reset database
			
			// Create tables
            @"CREATE TABLE IF NOT EXISTS contact_match ("
                "id INTEGER PRIMARY KEY NOT NULL, "
                "item_hash text NOT NULL"
            ");",
            @"CREATE UNIQUE INDEX IF NOT EXISTS item_hash_1 ON contact_match (item_hash);",
			
			@"CREATE TABLE IF NOT EXISTS contact_detail ("
				"apple_id INT NOT NULL, "
				"ringmail_enabled BOOL DEFAULT 0, "
				"primary_address TEXT"
			");",
            @"CREATE UNIQUE INDEX IF NOT EXISTS apple_id_1 ON contact_status (apple_id);",
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

- (void)updateMatches:(NSArray*)rgMatches
{
    [self inDatabase:^(FMDatabase *db) {
        // Get current ringmail users
        NSMutableDictionary *cur = [NSMutableDictionary dictionary];
        FMResultSet *rs = [db executeQuery:@"SELECT item_hash FROM contact_match"];
        while ([rs next])
        {
            NSString *match = [rs stringForColumnIndex:0];
            [cur setObject:@(1) forKey:match];
        }
        [rs close];
		//NSLog(@"Current: %@", cur);
        
        NSMutableDictionary *seen = [NSMutableDictionary dictionary];
        for (NSString *newMatch in rgMatches)
        {
			if ([cur objectForKey:newMatch] != nil) // Found
			{
                //NSLog(@"RingMail: Contact Already Found: %@", newMatch);
				[cur removeObjectForKey:newMatch];
			}
			else
			{
                //NSLog(@"RingMail: Contact Activate 1: %@", newMatch);
				if (seen[newMatch] == nil)
				{
					//NSLog(@"RingMail: Contact Activate 2: %@", newMatch);
					[db executeUpdate:@"INSERT INTO contact_match (item_hash) VALUES (?)", newMatch];
				}
			}
			seen[newMatch] = @1;
        }
		
        // Purge contacts that are no longer RingMail users :(
        [cur enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            //NSLog(@"RingMail: Contact Deactivate: %@", key);
            [db executeUpdate:@"DELETE FROM contact_match WHERE item_hash=?", key];

        }];
    }];
}

- (BOOL)updateDetails:(NSArray*)rgUsers
{
    __block BOOL refresh = NO;
    [self inDatabase:^(FMDatabase *db) {
        // Get current ringmail users
        NSMutableDictionary *cur = [NSMutableDictionary dictionary];
        NSMutableDictionary *addrs = [NSMutableDictionary dictionary];
        FMResultSet *rs = [db executeQuery:@"SELECT apple_id, primary_address FROM contact_detail WHERE ringmail_enabled = 1"];
        while ([rs next])
        {
            NSNumber *contactID = [rs objectForColumnIndex:0];
            [cur setObject:contactID forKey:[contactID stringValue]];
            [addrs setObject:[rs objectForColumnIndex:1] forKey:[contactID stringValue]];
        }
        [rs close];
        //NSLog(@"RingMail: Contact Matches: %@ From: %@", addrs, rgUsers);
		
        for (NSString *contactID in rgUsers)
        {
            FMResultSet *rs = [db executeQuery:@"SELECT count(oid) FROM contact_detail WHERE apple_id=?", contactID];
            if ([rs next]) // found
            {
                NSNumber *count = [rs objectForColumnIndex:0];
                //NSLog(@"RingMail: Contact Activate: %@ -> %@", contactID, count);
                if ([count intValue] == 0) // Insert
                {
                    [db executeUpdate:@"INSERT INTO contact_detail (apple_id, ringmail_enabled, primary_address) VALUES (?, 1, '')", contactID];
                }
                else if ([count intValue] == 1) // Update
                {
                    [db executeUpdate:@"UPDATE contact_detail SET ringmail_enabled=1 WHERE apple_id=?", contactID];
                }
                refresh = YES;
            }
            [rs close];
            ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContactById:[cur objectForKey:contactID]];
            NSString *firstAddr = [self defaultPrimaryAddress:contact current:[addrs objectForKey:contactID]];
            //NSLog(@"RingMail Set Contact %@ -> %@", contactID, firstAddr);
            if (! [firstAddr isEqualToString:[addrs objectForKey:contactID]])
            {
                //NSLog(@"RingMail Update Contact %@ -> %@", contactID, firstAddr);
                [db executeUpdate:@"UPDATE contact_detail SET primary_address=? WHERE apple_id=?", firstAddr, contactID];
            }
            [cur removeObjectForKey:contactID];
        }
        
        // Purge contacts that are no longer RingMail users :(
        [cur enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            //NSLog(@"RingMail: Contact Deactivate: %@", key);
            [db executeUpdate:@"UPDATE contact_detail SET ringmail_enabled=0 WHERE apple_id=?", key];
            [[RKThreadStore sharedInstance] removeContact:(NSNumber*)key];
            refresh = YES;
        }];
    }];
	return refresh;
}

- (BOOL)isEnabled:(NSString*)addrStr
{
    __block NSString *data = [[NSString stringWithFormat:@"r!ng:%@", addrStr] SHA256];
    __block BOOL matched = NO;
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT count(item_hash) FROM contact_match WHERE item_hash = ?", data];
        if ([rs next])
        {
			NSNumber *count = [rs objectForColumnIndex:0];
			if ([count intValue] > 0)
			{
				matched = YES;
			}
		}
		[rs close];
    }];
	return matched;
}

- (BOOL)contactEnabled:(NSString*)contactID
{
    __block BOOL res = NO;
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT COUNT(oid) FROM contacts WHERE ringmail_enabled = 1 AND apple_id = ?", contactID];
        while ([rs next])
        {
            NSNumber *count = [rs objectForColumnIndex:0];
            if ([count intValue] == 1)
            {
                res = YES;
            }
        }
        [rs close];
    }];
    return res;
}

- (NSDictionary*)getEnabledContacts
{
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT apple_id FROM contact_detail WHERE ringmail_enabled = 1"];
        while ([rs next])
        {
            NSNumber *contactID = [rs objectForColumnIndex:0];
            //NSLog(@"RingMail: Contact Item: %@", contactID);
            [res setObject:@"" forKey:[contactID stringValue]];
        }
        [rs close];
    }];
    return res;
}

- (NSString*)getPrimaryAddress:(NSString*)contactID
{
    __block NSString* addr = @"";
    [self inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT primary_address FROM contact_detail WHERE apple_id = ?", contactID];
        while ([rs next])
        {
            addr = [rs objectForColumnIndex:0];
        }
        [rs close];
    }];
    return addr;
}

- (NSString*)defaultPrimaryAddress:(ABRecordRef)lPerson
{
	FastAddressBook *fab = [[LinphoneManager instance] fastAddressBook];
	NSArray *emailList = [fab getEmailArray:lPerson];
    NSString *res = nil;
	for (NSString *val in emailList)
	{
        NSString *nval = [[val lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([self isEnabled:nval])
        {
            res = nval;
            break;
        }
    }
    if (res != nil)
    {
        return res;
    }
	NSArray *phoneList = [fab getPhoneArray:lPerson];
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
	for (NSString *val in phoneList)
	{
        NSError *anError = nil;
        NBPhoneNumber *myNumber = [phoneUtil parse:val defaultRegion:@"US" error:&anError];
        if (anError == nil && [phoneUtil isValidNumber:myNumber])
        {
            NSString *nval = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&anError];
            if ([self isEnabled:nval])
            {
                res = nval;
                break;
            }
        }
    }
    return res;
}

// This version prefers emails to phone numbers, even if the current phone number might match
- (NSString*)defaultPrimaryAddress:(ABRecordRef)lPerson current:(NSString*)cur
{
	FastAddressBook *fab = [[LinphoneManager instance] fastAddressBook];
    BOOL found = NO;
    NSString *res = nil;
	NSArray *emailList = [fab getEmailArray:lPerson];
	for (NSString *val in emailList)
	{
        NSString *nval = [[val lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([self isEnabled:nval])
        {
            if ([nval isEqualToString:cur])
            {
                found = YES;
                break;
            }
            else if (res == nil)
            {
                res = nval;
            }
        }
    }
    if (found)
    {
        return cur;
    }
    else if (res != nil)
    {
        return res;
    }
	NSArray *phoneList = [fab getPhoneArray:lPerson];
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
	for (NSString *val in phoneList)
	{
        NSError *anError = nil;
        NBPhoneNumber *myNumber = [phoneUtil parse:val defaultRegion:@"US" error:&anError];
        if (anError == nil && [phoneUtil isValidNumber:myNumber])
        {
            NSString *nval = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&anError];
            if ([self isEnabled:nval])
            {
                if ([nval isEqualToString:cur])
                {
                    found = YES;
                    break;
                }
                else if (res == nil)
                {
                    res = nval;
                }
            }
        }
    }
    if (found)
    {
        return cur;
    }
    else if (res != nil)
    {
        return res;
    }
    else
    {
        return @"";
    }
}

@end
