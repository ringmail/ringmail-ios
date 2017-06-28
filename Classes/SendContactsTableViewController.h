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


typedef enum _SendContactSelectionMode {
    SendContactSelectionModeSingle,
    SendContactSelectionModeMulti
} SendContactSelectionMode;


@class SendContactsTableViewController;

@protocol SendContactsTableViewControllerDelegate <NSObject>
- (void)didSelectSingleSendContact:(NSArray*)emails;
- (void)didSelectMultiSendContact:(NSMutableArray*)contacts;
@end


@interface SendContactsTableViewController : UITableViewController {
@private
    OrderedDictionary* addressBookMap;
    NSDictionary* ringMailContacts;
    NSMutableDictionary* avatarMap;
    NSMutableArray* selectedContacts;
    ABAddressBookRef addressBook;
}

- (void)loadData;

@property (nonatomic, weak) id <SendContactsTableViewControllerDelegate> delegate;
@property (nonatomic) SendContactSelectionMode selectionMode;

@end
