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
    SendContactSelectionModeNone,
    SendContactSelectionModeEdit,
    SendContactSelectionModePhone,
    SendContactSelectionModeMessage
} SendContactSelectionMode;

@interface SendContactsSelection : NSObject <UISearchBarDelegate> {
}

+ (void)setSelectionMode:(SendContactSelectionMode)selectionMode;
+ (SendContactSelectionMode)getSelectionMode;
+ (void)setAddAddress:(NSString*)address;
+ (NSString*)getAddAddress;
/*!
 * Filters contacts by SIP domain.
 * @param domain SIP domain to filter. Use @"*" or nil to disable it.
 */
+ (void)setSipFilter:(NSString*) domain;

/*!
 * Weither contacts are filtered by SIP domain or not.
 * @return the filter used, or nil if none.
 */
+ (NSString*)getSipFilter;

/*!
 * Weither always keep contacts with an email address or not.
 * @param enable TRUE if you want to always keep contacts with an email.
 */
+ (void)enableEmailFilter:(BOOL)enable;

/*!
 * Weither always keep contacts with an email address or not.
 * @return TRUE if this behaviour is enabled.
 */
+ (BOOL)emailFilterEnabled;

/*!
 * Filters contacts by name and/or email fuzzy matching pattern.
 * @param fuzzyName fuzzy word to match. Use nil to disable it.
 */
+ (void)setNameOrEmailFilter:(NSString*)fuzzyName;

/*!
 * Weither contacts are filtered by name and/or email.
 * @return the filter used, or nil if none.
 */
+ (NSString*)getNameOrEmailFilter;

@end

@interface SendContactsViewController : UIViewController<UICompositeViewDelegate,ABPeoplePickerNavigationControllerDelegate,UITextFieldDelegate> {
    BOOL use_systemView;
}

@property (nonatomic, strong) IBOutlet SendContactsTableViewController* tableController;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
//@property (nonatomic, strong) IBOutlet UINavigationController* sysViewController;
////@property (strong, nonatomic) IBOutlet UIView *toolBar;
//@property (nonatomic, strong) IBOutlet UIButton* allButton;
//@property (nonatomic, strong) IBOutlet UIButton* linphoneButton;
//@property (nonatomic, strong) IBOutlet UIButton *backButton;
//@property (nonatomic, strong) IBOutlet UIButton *addButton;


@end
