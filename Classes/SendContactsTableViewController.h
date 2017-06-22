//
//  SendContactsTableViewController.h
//  ringmail
//
//  Created by Mark Baxter on 6/21/17.
//
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "OrderedDictionary.h"

@interface SendContactsTableViewController : UITableViewController {
@private
    OrderedDictionary* addressBookMap;
    NSDictionary* ringMailContacts;
    NSMutableDictionary* avatarMap;
    NSMutableArray* selectedContacts;
    ABAddressBookRef addressBook;
}

- (void)loadData;

@end
