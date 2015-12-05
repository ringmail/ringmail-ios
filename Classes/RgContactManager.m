//
//  RgContactManager.m
//  ringmail
//
//  Created by Mike Frager on 12/3/15.
//
//

#import <NSHash/NSString+NSHash.h>
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "RgNetwork.h"
#import "RgContactManager.h"

@implementation RgContactManager

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super init];
    if (self) {
        addressBook = ABAddressBookCreateWithOptions(nil, nil);
        contacts = nil;
        dateFormatter = [[NSDateFormatter alloc] init];
        enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [self setupDatabase];
        //ABAddressBookRegisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
    }
    return self;
}

- (void)dealloc {
    //ABAddressBookUnregisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
    CFRelease(addressBook);
}

#pragma mark - Manage Contact Syncing

- (NSArray*)getContactList
{
    return [self getContactList:0];
}

- (NSArray*)getContactList:(BOOL)reload
{
    if (reload || contacts == nil)
    {
        contacts = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
    }
    return contacts;
}

- (NSMutableDictionary *)getAddressBookStats:(NSArray*)contactList
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSString *lastMod = nil;
    NSDate *maxDate = nil;
    int counter = 0;
    for (id person in contacts)
    {
        counter++;
        NSDate *modDate = CFBridgingRelease(ABRecordCopyValue((__bridge ABRecordRef)person, kABPersonModificationDateProperty));
        if (maxDate)
        {
            if ([(NSDate*)maxDate compare:modDate] == NSOrderedAscending)
            {
                maxDate = modDate;
            }
        }
        else
        {
            maxDate = modDate;
        }
    }
    NSLog(@"Max Date: %@", maxDate);
    if (maxDate)
    {
        lastMod = [dateFormatter stringFromDate:maxDate];
        NSLog(@"Last Mod: %@", lastMod);
    }
    if (lastMod == nil)
    {
        lastMod = @"";
    }
    [result setObject:lastMod forKey:@"ts_update"];
    NSString *count = [NSString stringWithFormat:@"%i", counter];
    [result setObject:count forKey:@"count"];
    return result;
}

- (NSMutableDictionary *)contactItem:(ABRecordRef)lPerson
{
    
    ABMultiValueRef emailMap = ABRecordCopyValue((ABRecordRef)lPerson, kABPersonEmailProperty);
    NSMutableArray *emailArray = [NSMutableArray array];
    if (emailMap) {
        for(int i = 0; i < ABMultiValueGetCount(emailMap); ++i) {
            NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emailMap, i));
            if (val)
            {
                val = [[val lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                val = [[NSString stringWithFormat:@"r!ng:%@", val] SHA256];
                [emailArray addObject:val];
            }
        }
        CFRelease(emailMap);
    }
    ABMultiValueRef phoneMap = ABRecordCopyValue((ABRecordRef)lPerson, kABPersonPhoneProperty);
    NSMutableArray *phoneArray = [NSMutableArray array];
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    if (phoneMap) {
        for(int i = 0; i < ABMultiValueGetCount(phoneMap); ++i) {
            NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneMap, i));
            if (val)
            {
                NSError *anError = nil;
                NBPhoneNumber *myNumber = [phoneUtil parse:val defaultRegion:@"US" error:&anError];
                if (anError == nil && [phoneUtil isValidNumber:myNumber])
                {
                    val = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&anError];
                    val = [[NSString stringWithFormat:@"r!ng:%@", val] SHA256];
                    [phoneArray addObject:val];
                }
            }
        }
        CFRelease(phoneMap);
    }
    NSDate *modDate = CFBridgingRelease(ABRecordCopyValue((ABRecordRef)lPerson, kABPersonModificationDateProperty));
    NSString *modDateGMT = [dateFormatter stringFromDate:modDate];
    NSNumber *recordId = [NSNumber numberWithInteger:ABRecordGetRecordID((ABRecordRef)lPerson)];
    NSString *recordStr = [NSString stringWithFormat:@"%@", recordId];
    NSDictionary *contactBase = @{ @"em": emailArray, @"ph": phoneArray, @"ts": modDateGMT, @"id": recordStr };
    NSMutableDictionary *contact = [NSMutableDictionary dictionaryWithDictionary:contactBase];
    
    NSString *lFirstName = CFBridgingRelease(ABRecordCopyValue(lPerson, kABPersonFirstNameProperty));
	NSString *lLocalizedFirstName = [FastAddressBook localizedLabel:lFirstName];
	NSString *lLastName = CFBridgingRelease(ABRecordCopyValue(lPerson, kABPersonLastNameProperty));
	NSString *lLocalizedLastName = [FastAddressBook localizedLabel:lLastName];
	NSString *lOrganization = CFBridgingRelease(ABRecordCopyValue(lPerson, kABPersonOrganizationProperty));
	NSString *lLocalizedlOrganization = [FastAddressBook localizedLabel:lOrganization];
    
    if (lLocalizedFirstName != nil)
    {
        [contact setObject:(NSString*)lLocalizedFirstName forKey:@"fn"];
    }
    if (lLocalizedLastName != nil)
    {
        [contact setObject:(NSString*)lLocalizedLastName forKey:@"ln"];
    }
    if (lLocalizedlOrganization != nil)
    {
        [contact setObject:(NSString*)lLocalizedlOrganization forKey:@"co"];
    }
    return contact;
}

- (NSMutableArray *)getContactData:(NSArray*)contactList
{
    NSMutableArray *contactsArray = [NSMutableArray array];
    for (id lPerson in contactList)
    {
        [contactsArray addObject:[self contactItem:(__bridge ABRecordRef)lPerson]];
    }
    return contactsArray;
    //NSData *jsonData = [NSJSONSerialization dataWithJSONObject:final options:0 error:nil];
    //NSString *result = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //return result;
}

#pragma mark Remote API calls

- (void)sendContactData
{
    NSArray *contactList = [self getContactList];
    NSArray *ctd = [self getContactData:contactList];
    NSLog(@"RingMail: Send Contact Data: %@", ctd);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:ctd options:0 error:nil];
    NSString *ctdjson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [[RgNetwork instance] updateContacts:@{@"contacts": ctdjson} callback:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary* res = responseObject;
        NSString *ok = [res objectForKey:@"result"];
        if (! [ok isEqualToString:@"ok"])
        {
            NSLog(@"RingMail API Error: %@", @"Update contacts failed");
        }
    }];
}

#pragma mark Contact database manager

- (FMDatabaseQueue *)database
{
    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
#ifdef DEBUG
    NSString *dbPath = [docsPath stringByAppendingPathComponent:@"ringmail_contacts_dev"];
#else
    NSString *dbPath = [docsPath stringByAppendingPathComponent:@"ringmail_contacts"];
#endif
    dbPath = [docsPath stringByAppendingPathComponent:@"_v1.0.db"];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    return queue;
}

- (void)setupDatabase
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NSArray *setup = [NSArray arrayWithObjects:
                          //@"DROP TABLE contacts;",
                          @"CREATE TABLE IF NOT EXISTS contacts (apple_id INT NOT NULL, ringmail_enabled BOOL DEFAULT 0, contact_data TEXT);",
                          @"CREATE UNIQUE INDEX IF NOT EXISTS apple_id_1 ON contacts (apple_id);",
                          nil];
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
}

- (void)dropTables
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        NSArray *setup = [NSArray arrayWithObjects:
                          @"DROP TABLE contacts;",
                          nil];
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
}

@end
