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

@interface RgContactManager : NSObject <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate> {
    @private
    NSDateFormatter *dateFormatter;
    NSLocale *enUSPOSIXLocale;
    NSArray *contacts;
}

- (NSArray*)getContactList;
- (NSArray*)getContactList:(BOOL)reload;
- (NSDictionary*)getAddressBookStats:(NSArray*)contactList;
- (NSArray*)getContactData:(NSArray*)contactList;
- (void)sendContactData;
- (void)sendContactData:(NSArray*)contactList;
- (void)inviteToRingMail:(ABRecordRef)contact;

@end
