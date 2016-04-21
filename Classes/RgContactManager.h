//
//  RgContactManager.h
//  ringmail
//
//  Created by Mike Frager on 12/3/15.
//
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

#import "FastAddressBook.h"
#import "Utils.h"

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"

@interface RgContactManager : NSObject <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate> {
    @private
    ABAddressBookRef addressBook;
    NSDateFormatter *dateFormatter;
    NSLocale *enUSPOSIXLocale;
    NSArray *contacts;
}

- (NSArray*)getContactList;
- (NSArray*)getContactList:(BOOL)reload;
- (NSDictionary *)getAddressBookStats:(NSArray*)contactList;
- (NSArray*)getContactData:(NSArray*)contactList;
- (void)inviteToRingMail:(ABRecordRef)contact;
- (void)sendContactData;
- (void)sendContactData:(NSArray*)contactList;
- (void)dbUpdateEnabled:(NSArray *)rgUsers;
- (NSDictionary*)dbGetRgContacts;
- (BOOL)dbHasRingMail:(NSString*)contactID;
- (void)dropTables;

@end
