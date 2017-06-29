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


@interface SendContactsViewController : UIViewController<UICompositeViewDelegate> {
    BOOL use_systemView;
}

@property (nonatomic, strong) IBOutlet SendContactsTableViewController* tableController;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic) SendContactSelectionMode selectionMode;
@property (nonatomic, weak) id <SendContactSelectDelegate> delegate;

- (instancetype) initWithSelectionMode:(SendContactSelectionMode)mode;

@end
