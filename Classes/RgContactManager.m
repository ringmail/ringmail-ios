//
//  RgContactManager.m
//  ringmail
//
//  Created by Mike Frager on 12/3/15.
//
//

#import <UIKit/UIKit.h>
#import <NSHash/NSString+NSHash.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MessageUI.h>
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "RgNetwork.h"
#import "RgContactManager.h"
#import "RgManager.h"
#import "DTActionSheet.h"
#import "PhoneMainView.h"

@implementation RgContactManager

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super init];
    if (self) {
        //addressBook = ABAddressBookCreateWithOptions(nil, nil);
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

//- (void)dealloc {
//    //ABAddressBookUnregisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
//    CFRelease(addressBook);
//}

#pragma mark - Manage Contact Syncing

- (NSArray*)getContactList
{
    return [self getContactList:0];
}

- (NSArray*)getContactList:(BOOL)reload
{
    if (reload || contacts == nil)
    {
//        ABAddressBookRevert(addressBook);
//        contacts = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
		contacts = [[[LinphoneManager instance] fastAddressBook] getContactsArray];
    }
    return contacts;
}

- (NSDictionary *)getAddressBookStats:(NSArray*)contactList
{
	FastAddressBook *fab = [[LinphoneManager instance] fastAddressBook];
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSString *lastMod = nil;
    NSDate *maxDate = nil;
    int counter = 0;
    for (id person in contacts)
    {
        counter++;
        NSDate *modDate = [fab getModDate:(__bridge ABRecordRef)person];
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
    //NSLog(@"Max Date: %@", maxDate);
    if (maxDate)
    {
        [result setObject:maxDate forKey:@"date_update"];
        lastMod = [dateFormatter stringFromDate:maxDate];
        //NSLog(@"Last Mod: %@", lastMod);
    }
    if (lastMod == nil)
    {
        lastMod = @"";
    }
    [result setObject:lastMod forKey:@"ts_update"];
    NSNumber *count = [NSNumber numberWithInt:counter];
    [result setObject:count forKey:@"count"];
    return result;
}

- (NSMutableDictionary *)contactItem:(ABRecordRef)lPerson
{
    FastAddressBook *fab = [[LinphoneManager instance] fastAddressBook];
	return [fab contactItem:lPerson];
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

- (NSString*)getRingMailAddress:(ABRecordRef)lPerson
{
	FastAddressBook *fab = [[LinphoneManager instance] fastAddressBook];
	NSArray *emailList = [fab getEmailArray:lPerson];
    NSString *res = nil;
	for (NSString *val in emailList)
	{
        NSString *nval = [[val lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([self dbIsEnabled:nval])
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
            if ([self dbIsEnabled:nval])
            {
                res = nval;
                break;
            }
        }
    }
    return res;
}

- (NSString*)getRingMailAddress:(ABRecordRef)lPerson current:(NSString*)cur
{
	FastAddressBook *fab = [[LinphoneManager instance] fastAddressBook];
    BOOL found = NO;
    NSString *res = nil;
	NSArray *emailList = [fab getEmailArray:lPerson];
	for (NSString *val in emailList)
	{
        NSString *nval = [[val lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([self dbIsEnabled:nval])
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
            if ([self dbIsEnabled:nval])
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

- (void)inviteToRingMail:(ABRecordRef)contact
{
    DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:NSLocalizedString(@"Invite To RingMail", nil)];

    if ([MFMailComposeViewController canSendMail])
    {
        ABMultiValueRef emailMap = ABRecordCopyValue((ABRecordRef)contact, kABPersonEmailProperty);
        if (emailMap)
        {
            for(int i = 0; i < ABMultiValueGetCount(emailMap); ++i)
            {
                NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emailMap, i));
                if (val)
                {
                    [sheet addButtonWithTitle:val block:^() {
                        MFMailComposeViewController *mail = [[MFMailComposeViewController alloc] init];
                        mail.mailComposeDelegate = self;
                        [mail setSubject:@"You're Invited To RingMail"];
                        [mail setMessageBody:@"You are invited to explore RingMail. Make free calls/text now. https://ringmail.com/dl" isHTML:NO];
                        [mail setToRecipients:@[val]];
                        [[PhoneMainView instance] presentViewController:mail animated:YES completion:NULL];
                    }];
                }
            }
            CFRelease(emailMap);
        }
    }
    if([MFMessageComposeViewController canSendText])
    {
        ABMultiValueRef phoneMap = ABRecordCopyValue((ABRecordRef)contact, kABPersonPhoneProperty);
        NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
        if (phoneMap) {
            for(int i = 0; i < ABMultiValueGetCount(phoneMap); ++i) {
                __block NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneMap, i));
                if (val)
                {
                    NSError *anError = nil;
                    NBPhoneNumber *myNumber = [phoneUtil parse:val defaultRegion:@"US" error:&anError];
                    if (anError == nil && [phoneUtil isValidNumber:myNumber])
                    {
                        val = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&anError];
                        [sheet addButtonWithTitle:val block:^() {
                            MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
                            controller.body = @"You are invited to explore RingMail. Make free calls/text now. https://ringmail.com/dl";
                            controller.recipients = @[val];
                            controller.messageComposeDelegate = self;
                            [[PhoneMainView instance] presentModalViewController:controller animated:YES];
                        }];
                    }
                }
            }
            CFRelease(phoneMap);
        }
    }

    [sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:^{}];
    [sheet showInView:[PhoneMainView instance].view];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [[PhoneMainView instance] dismissModalViewControllerAnimated:YES];
    if (result == MessageComposeResultCancelled)
    {
        NSLog(@"Message cancelled");
    }
    else if (result == MessageComposeResultSent)
    {
        NSLog(@"Message sent");
    }
    else
    {
        NSLog(@"Message failed");
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result) {
        case MFMailComposeResultSent:
            NSLog(@"You sent the email.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"You saved a draft of this email");
            break;
        case MFMailComposeResultCancelled:
            NSLog(@"You cancelled sending this email.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed:  An error occurred when trying to compose this email");
            break;
        default:
            NSLog(@"An error occurred when trying to compose this email");
            break;
    }
    
    [[PhoneMainView instance] dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark Remote API calls

- (void)sendContactData
{
    NSArray *contactList = [self getContactList];
    [self sendContactData:contactList];
}

- (void)sendContactData:(NSArray*)contactList
{
    NSArray *ctd = [self getContactData:contactList];
    //NSLog(@"RingMail: Send Contact Data: %@", ctd);
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:ctd options:0 error:nil];
    NSString *ctdjson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [[RgNetwork instance] updateContacts:@{@"contacts": ctdjson} callback:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary* res = responseObject;
        NSString *ok = [res objectForKey:@"result"];
        if ([ok isEqualToString:@"ok"])
        {
            NSArray *rgMatches = [res objectForKey:@"rg_matches"];
            if (rgMatches)
            {
                //NSLog(@"RingMail: Updated Matches: %@", rgMatches);
                [self dbUpdateMatches:rgMatches];
            }
            NSArray *rgContacts = [res objectForKey:@"rg_contacts"];
            if (rgContacts)
            {
                //NSLog(@"RingMail: Updated Contacts: %@", rgContacts);
                [self dbUpdateEnabled:rgContacts];
                [[NSNotificationCenter defaultCenter] postNotificationName:kRgContactsUpdated object:self userInfo:@{}];
            }
        }
        else
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
    NSString *dbPath = [docsPath stringByAppendingPathComponent:@"ringmail_contact_dev"];
#else
    NSString *dbPath = [docsPath stringByAppendingPathComponent:@"ringmail_contact"];
#endif
    dbPath = [docsPath stringByAppendingPathComponent:@"_v0.1.db"];
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

            @"CREATE TABLE IF NOT EXISTS contact_match ("
              "id INTEGER PRIMARY KEY NOT NULL,"
              "item_hash text NOT NULL"
            ");",

            @"CREATE UNIQUE INDEX IF NOT EXISTS item_hash_1 ON contact_match (item_hash);",
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

- (void)dbUpdateMatches:(NSArray*)rgMatches
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        // Get current ringmail users
        NSMutableDictionary *cur = [NSMutableDictionary dictionary];
        FMResultSet *rs = [db executeQuery:@"SELECT item_hash FROM contact_match"];
        while ([rs next])
        {
            NSString *match = [rs objectForColumnIndex:0];
            [cur setObject:@(1) forKey:match];
        }
        [rs close];
        
        for (NSString *newMatch in rgMatches)
        {
			if ([cur objectForKey:newMatch] != nil) // Found
			{
				[cur removeObjectForKey:newMatch];
			}
			else
			{
                [db executeUpdate:@"INSERT INTO contact_match (item_hash) VALUES (?)", newMatch];
			}
        }
        
        // Purge contacts that are no longer RingMail users :(
        [cur enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            //NSLog(@"RingMail: Contact Deactivate: %@", key);
            [db executeUpdate:@"DELETE FROM contact_match WHERE item_hash=?", key];
        }];
    }];
    [dbq close];
}

- (BOOL)dbIsEnabled:(NSString*)item
{
    FMDatabaseQueue *dbq = [self database];
    __block NSString *data = [[NSString stringWithFormat:@"r!ng:%@", item] SHA256];
    __block BOOL matched = NO;
    [dbq inDatabase:^(FMDatabase *db) {
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
    [dbq close];
	return matched;
}

- (void)dbUpdateEnabled:(NSArray *)rgUsers
{
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        // Get current ringmail users
        NSMutableDictionary *cur = [NSMutableDictionary dictionary];
        NSMutableDictionary *addrs = [NSMutableDictionary dictionary];
        FMResultSet *rs = [db executeQuery:@"SELECT apple_id, contact_data FROM contacts WHERE ringmail_enabled = 1"];
        while ([rs next])
        {
            NSNumber *contactID = [rs objectForColumnIndex:0];
            [cur setObject:contactID forKey:[contactID stringValue]];
            [addrs setObject:[rs objectForColumnIndex:1] forKey:[contactID stringValue]];
        }
        [rs close];
        
        for (NSString *contactID in rgUsers)
        {
            FMResultSet *rs = [db executeQuery:@"SELECT count(oid) FROM contacts WHERE apple_id=?", contactID];
            if ([rs next])
            {
                NSNumber *count = [rs objectForColumnIndex:0];
                //NSLog(@"RingMail: Contact Activate: %@ -> %@", contactID, count);
                if ([count intValue] == 0) // Insert
                {
                    [db executeUpdate:@"INSERT INTO contacts (apple_id, ringmail_enabled, contact_data) VALUES (?, 1, '')", contactID];
                }
                else if ([count intValue] == 1) // Update
                {
                    [db executeUpdate:@"UPDATE contacts SET ringmail_enabled=1 WHERE apple_id=?", contactID];
                }
            }
            [rs close];
            ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContactById:[cur objectForKey:contactID]];
            NSString *firstAddr = [self getRingMailAddress:contact current:[addrs objectForKey:contactID]];
            //NSLog(@"RingMail Set Contact %@ -> %@", contactID, firstAddr);
            if (! [firstAddr isEqualToString:[addrs objectForKey:contactID]])
            {
                //NSLog(@"RingMail Update Contact %@ -> %@", contactID, firstAddr);
                [db executeUpdate:@"UPDATE contacts SET contact_data=? WHERE apple_id=?", firstAddr, contactID];
            }
            [cur removeObjectForKey:contactID];
        }
        
        // Purge contacts that are no longer RingMail users :(
        [cur enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            //NSLog(@"RingMail: Contact Deactivate: %@", key);
            [db executeUpdate:@"UPDATE contacts SET ringmail_enabled=0 WHERE apple_id=?", key];
        }];
    }];
    [dbq close];
}

- (NSDictionary*)dbGetRgContacts
{
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    FMDatabaseQueue *dbq = [self database];
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT apple_id FROM contacts WHERE ringmail_enabled = 1"];
        while ([rs next])
        {
            NSNumber *contactID = [rs objectForColumnIndex:0];
            //NSLog(@"RingMail: Contact Item: %@", contactID);
            [res setObject:@"" forKey:[contactID stringValue]];
        }
        [rs close];
    }];
    [dbq close];
    return res;
}

- (BOOL)dbHasRingMail:(NSString*)contactID
{
    FMDatabaseQueue *dbq = [self database];
    __block BOOL res = NO;
    [dbq inDatabase:^(FMDatabase *db) {
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
    [dbq close];
    return res;
}

- (NSString*)dbGetPrimaryAddress:(NSString*)contactID
{
    FMDatabaseQueue *dbq = [self database];
    __block NSString* addr = @"";
    [dbq inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:@"SELECT contact_data FROM contacts WHERE apple_id = ?", contactID];
        while ([rs next])
        {
            addr = [rs objectForColumnIndex:0];
        }
        [rs close];
    }];
    [dbq close];
    return addr;
}

@end
