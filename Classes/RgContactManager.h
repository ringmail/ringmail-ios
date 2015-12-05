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

@interface RgContactManager : NSObject {
    @private
    ABAddressBookRef addressBook;
    NSDateFormatter *dateFormatter;
    NSLocale *enUSPOSIXLocale;
    NSArray *contacts;
}

- (NSArray*)getContactList;
- (NSArray*)getContactList:(BOOL)reload;
- (NSMutableDictionary *)getAddressBookStats:(NSArray*)contactList;
- (NSArray*)getContactData:(NSArray*)contactList;
- (void)sendContactData;

@end
