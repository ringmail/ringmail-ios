//
//  SendContactsViewController.m
//  ringmail
//
//  Created by Mark Baxter on 6/21/17.
//
//

#import "SendContactsViewController.h"

#import "PhoneMainView.h"
#import "Utils.h"
#import "UIColor+Hex.h"

#import <AddressBook/ABPerson.h>

#import "RgContactSearchViewController.h"

@implementation SendContactsSelection

static SendContactSelectionMode sSelectionMode = SendContactSelectionModeNone;
static NSString *sAddAddress = nil;
static NSString *sSipFilter = nil;
static BOOL sEnableEmailFilter = FALSE;
static NSString *sNameOrEmailFilter;

+ (void)setSelectionMode:(SendContactSelectionMode)selectionMode {
    sSelectionMode = selectionMode;
}

+ (SendContactSelectionMode)getSelectionMode {
    return sSelectionMode;
}

+ (void)setAddAddress:(NSString *)address {
    if (sAddAddress != nil) {
        sAddAddress = nil;
    }
    if (address != nil) {
        sAddAddress = address;
    }
}

+ (NSString *)getAddAddress {
    return sAddAddress;
}

+ (void)setSipFilter:(NSString *)domain {
    sSipFilter = domain;
}

+ (NSString *)getSipFilter {
    return sSipFilter;
}

+ (void)enableEmailFilter:(BOOL)enable {
    sEnableEmailFilter = enable;
}

+ (BOOL)emailFilterEnabled {
    return sEnableEmailFilter;
}

+ (void)setNameOrEmailFilter:(NSString *)fuzzyName {
    sNameOrEmailFilter = fuzzyName;
}

+ (NSString *)getNameOrEmailFilter {
    return sNameOrEmailFilter;
}

@end


@interface SendContactsViewController()
@property BOOL isSearchBarVisible;
@property (strong, nonatomic) RgContactSearchViewController *searchBarViewController;
@end


@implementation SendContactsViewController

@synthesize tableController;
@synthesize tableView;


typedef enum _HistoryView { History_All, History_Linphone, History_Search, History_MAX } HistoryView;

#pragma mark - Lifecycle Functions

- (id)init {
    return [super initWithNibName:@"ContactsViewController" bundle:[NSBundle mainBundle]];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Select Contacts"
                                                                content:@"SendContactsViewController"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 navBar:@"UINavBar"
                                                                 tabBar:@"UIMainBar"
                                                          navBarEnabled:true
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
    }
    return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

- (void)relayoutTableView {
    CGRect subViewFrame = self.view.frame;
    // let the searchBar be visible
    subViewFrame.origin.y += 50;
    subViewFrame.size.height -= 50;
    self.tableView.frame = subViewFrame;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableController = [[SendContactsTableViewController alloc] init];
    self.tableView = [[UITableView alloc] init];

    self.tableController.view = self.tableView;

    [self relayoutTableView];

    self.tableView.dataSource = self.tableController;
    self.tableView.delegate = self.tableController;

    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    self.tableView.sectionIndexColor = [UIColor colorWithHex:@"#0A60FF"];
    self.tableView.sectionIndexBackgroundColor = [UIColor colorWithHex:@"#FFFFFF" alpha:0.33f];
    
    
    [self.view addSubview:tableView];
    [self update];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchBarViewController = [[RgContactSearchViewController alloc] init];
    self.searchBarViewController.view.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 50);
    self.isSearchBarVisible = YES;
    [self.searchBarViewController.searchField addTarget:self action:@selector(onSearchChange:) forControlEvents:UIControlEventEditingChanged];
    [self addChildViewController:self.searchBarViewController];
    [self.view addSubview:self.searchBarViewController.view];
    
    [tableController.tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
    [tableController.tableView setBackgroundView:nil];					 // Can't do it in Xib: issue with ios4

    UITapGestureRecognizer* tapBackground = [[UITapGestureRecognizer alloc] initWithTarget:self.searchBarViewController action:@selector(dismissKeyboard:)];
    [tapBackground setNumberOfTapsRequired:1];
    [tapBackground setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tapBackground];
    
}

#pragma mark -

//- (void)changeView:(HistoryView)view {
//
//}
//
//- (void)refreshButtons {
//}

- (void)update {
    [tableController loadData];
}

#pragma mark - Rotation handling

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    // the searchbar overlaps the subview in most rotation cases, we have to re-layout the view manually:
    
    [self relayoutTableView];
}

#pragma mark - ABPeoplePickerDelegate

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    return;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person {
    return true;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier {
    return false;
}


#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    return YES;
}



#pragma mark - Text Field Functions

- (IBAction)dismissKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)onSearchChange:(id)sender
{
    NSString *searchText =  [self.searchBarViewController.searchField text];
    NSLog(@"Search: %@", searchText);
    [SendContactsSelection setNameOrEmailFilter:searchText];
    [tableController loadData];
}


#pragma mark - searchField delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // display searchtext in UPPERCASE
    searchBar.text = [searchText uppercaseString];
    searchBar.showsCancelButton = (searchText.length > 0);
    [SendContactsSelection setNameOrEmailFilter:searchText];
    [tableController loadData];
}


- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:FALSE animated:TRUE];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:TRUE animated:TRUE];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)contactsUpdated:(NSNotification *)notif {
    [tableController loadData];
}

@end
