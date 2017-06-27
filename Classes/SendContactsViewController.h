//
//  SendContactsViewController.h
//  ringmail
//
//  Created by Mark Baxter on 6/21/17.
//
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/ABPeoplePickerNavigationController.h>

#import "UICompositeViewController.h"
#import "SendContactsTableViewController.h"

typedef enum _SendContactSelectionMode {
    SendContactSelectionModeSingle,
    SendContactSelectionModeMulti
} SendContactSelectionMode;

@interface SendContactsViewController : UIViewController<UICompositeViewDelegate> {
    BOOL use_systemView;
}

@property (nonatomic, strong) IBOutlet SendContactsTableViewController* tableController;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic) SendContactSelectionMode selectionMode;

- (instancetype) initWithSelectionMode:(SendContactSelectionMode)mode;

@end
