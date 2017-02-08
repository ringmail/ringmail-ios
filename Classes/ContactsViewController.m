/* ContactsViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "ContactsViewController.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "UIColor+Hex.h"

#import <AddressBook/ABPerson.h>

@implementation ContactSelection

static ContactSelectionMode sSelectionMode = ContactSelectionModeNone;
static NSString *sAddAddress = nil;
static NSString *sSipFilter = nil;
static BOOL sEnableEmailFilter = FALSE;
static NSString *sNameOrEmailFilter;

+ (void)setSelectionMode:(ContactSelectionMode)selectionMode {
	sSelectionMode = selectionMode;
}

+ (ContactSelectionMode)getSelectionMode {
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

@implementation ContactsViewController

@synthesize tableController;
@synthesize tableView;

@synthesize sysViewController;

@synthesize allButton;
@synthesize linphoneButton;
@synthesize backButton;
@synthesize addButton;
@synthesize toolBar;
@synthesize searchField;
@synthesize searchButton;

typedef enum _HistoryView { History_All, History_Linphone, History_Search, History_MAX } HistoryView;

#pragma mark - Lifecycle Functions

- (id)init {
	return [super initWithNibName:@"ContactsViewController" bundle:[NSBundle mainBundle]];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Contacts"
																content:@"ContactsViewController"
															   stateBar:nil
														stateBarEnabled:false
                                                                 navBar:@"UINavBar"
																 tabBar:@"UIMainBar"
                                                          navBarEnabled:true
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true
                                                                segLeft:@""
                                                               segRight:@""];
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RgSegmentControl" object:nil];
}

- (void)relayoutTableView {
	CGRect subViewFrame = self.view.frame;
	// let the toolBar be visible
	subViewFrame.origin.y += self.toolBar.frame.size.height;
	subViewFrame.size.height -= self.toolBar.frame.size.height;
    self.tableView.frame = subViewFrame;
	/*[UIView animateWithDuration:0.2
					 animations:^{
					   
					 }];*/
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    self.tableController = [[ContactsTableViewController alloc] init];
    self.tableView = [[UITableView alloc] init];
    
    self.tableController.view = self.tableView;
    
    [self relayoutTableView];
    
    self.tableView.dataSource = self.tableController;
    self.tableView.delegate = self.tableController;
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
    UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    self.tableView.sectionIndexColor = [UIColor colorWithHex:@"#0077c2"];
    self.tableView.sectionIndexBackgroundColor = [UIColor colorWithHex:@"#F4F4F4"];
    
    [self.view addSubview:tableView];
    [self update];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactsUpdated:)
                                                 name:kRgContactsUpdated
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSegControl)
                                                 name:@"RgSegmentControl"
                                               object:nil];
    
    NSString *intro = @"Contact Name";
    NSAttributedString *placeHolderString = [[NSAttributedString alloc] initWithString:intro
    attributes:@{
                 NSForegroundColorAttributeName:[UIColor colorWithHex:@"#222222"],
                 NSFontAttributeName:[UIFont fontWithName:@"SFUIText-Light" size:16]
                 }];
    searchField.attributedPlaceholder = placeHolderString;
    searchField.font = [UIFont fontWithName:@"SFUIText-Light" size:16];
    searchField.textColor = [UIColor colorWithHex:@"#222222"];

}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	if (![FastAddressBook isAuthorized]) {
		UIAlertView *error = [[UIAlertView alloc]
				initWithTitle:NSLocalizedString(@"Address book", nil)
					  message:NSLocalizedString(@"You must authorize the application to have access to address book.\n"
												 "Toggle the application in Settings > Privacy > Contacts",
												nil)
					 delegate:nil
			cancelButtonTitle:NSLocalizedString(@"Continue", nil)
			otherButtonTitles:nil];
		[error show];
		[[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription]];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[self changeView:History_All];

	[linphoneButton.titleLabel setAdjustsFontSizeToFitWidth:TRUE];

	// Set selected+over background: IB lack !
	[linphoneButton setBackgroundImage:[UIImage imageNamed:@"contacts_linphone_selected.png"]
							  forState:(UIControlStateHighlighted | UIControlStateSelected)];

	[linphoneButton setTitle:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]
					forState:UIControlStateNormal];

	[LinphoneUtils buttonFixStates:linphoneButton];

	// Set selected+over background: IB lack !
	[allButton setBackgroundImage:[UIImage imageNamed:@"contacts_all_selected.png"]
						 forState:(UIControlStateHighlighted | UIControlStateSelected)];

	[LinphoneUtils buttonFixStates:allButton];

	[tableController.tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
	[tableController.tableView setBackgroundView:nil];					 // Can't do it in Xib: issue with ios4
    
    UITapGestureRecognizer* tapBackground = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [tapBackground setNumberOfTapsRequired:1];
    [tapBackground setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tapBackground];
    
    searchField.returnKeyType = UIReturnKeyDone;

}

#pragma mark -

- (void)changeView:(HistoryView)view {
	if (view == History_All) {
		[ContactSelection setSipFilter:nil];
		[ContactSelection enableEmailFilter:FALSE];
		[tableController loadData];
		allButton.selected = TRUE;
	} else {
		allButton.selected = FALSE;
	}

	if (view == History_Linphone) {
		[ContactSelection setSipFilter:[LinphoneManager instance].contactFilter];
		[ContactSelection enableEmailFilter:FALSE];
		[tableController loadData];
		linphoneButton.selected = TRUE;
	} else {
		linphoneButton.selected = FALSE;
	}
}

- (void)refreshButtons {
	switch ([ContactSelection getSelectionMode]) {
	case ContactSelectionModePhone:
	case ContactSelectionModeMessage:
		//[addButton setHidden:TRUE];
		[backButton setHidden:FALSE];
		break;
	default:
		//[addButton setHidden:FALSE];
		[backButton setHidden:TRUE];
		break;
	}
	if ([ContactSelection getSipFilter]) {
		allButton.selected = FALSE;
		linphoneButton.selected = TRUE;
	} else {
		allButton.selected = TRUE;
		linphoneButton.selected = FALSE;
	}
}

- (void)update {
	[self refreshButtons];
	[tableController loadData];
}

#pragma mark - Action Functions

- (IBAction)onAllClick:(id)event {
	[self changeView:History_All];
}

- (IBAction)onLinphoneClick:(id)event {
	[self changeView:History_Linphone];
}

- (IBAction)onAddContactClick:(id)event {
	// Go to Contact details view
	ContactDetailsViewController *controller = DYNAMIC_CAST(
		[[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE],
		ContactDetailsViewController);
	if (controller != nil) {
		if ([ContactSelection getAddAddress] == nil) {
			[controller newContact];
		} else {
			[controller newContact:[ContactSelection getAddAddress]];
		}
	}
}

- (IBAction)onBackClick:(id)event {
	[[PhoneMainView instance] popCurrentView];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[self searchBar:searchBar textDidChange:@""];
	[searchBar resignFirstResponder];
}

- (IBAction)onSearch:(id)sender {
    [searchField becomeFirstResponder];
}


- (void)handleSegControl {
    printf("contacts segement controller hit\n");
}

#pragma mark - Rotation handling

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	// the searchbar overlaps the subview in most rotation cases, we have to re-layout the view manually:
	[self relayoutTableView];
}

#pragma mark - ABPeoplePickerDelegate

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
	[[PhoneMainView instance] popCurrentView];
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

	/*CFTypeRef multiValue = ABRecordCopyValue(person, property);
	CFIndex valueIdx = ABMultiValueGetIndexForIdentifier(multiValue, identifier);
	NSString *phoneNumber = (NSString *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(multiValue, valueIdx));
	// Go to dialer view
	RgMainViewController *controller =
		DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription]],
					 RgMainViewController);
	if (controller != nil) {
		[controller call:phoneNumber displayName:(NSString *)CFBridgingRelease(ABRecordCopyCompositeName(person))];
	}
	CFRelease(multiValue);*/
	return false;
}


#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string {
    //[textField performSelector:@selector() withObject:nil afterDelay:0];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == searchField) {
        [searchField resignFirstResponder];
    }
    return YES;
}

#pragma mark - Text Field Functions

- (IBAction)dismissKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

- (IBAction)onSearchChange:(id)sender
{
    NSString *searchText = [searchField text];
    NSLog(@"Search: %@", searchText);
    [ContactSelection setNameOrEmailFilter:searchText];
    [tableController loadData];
}

#pragma mark - searchField delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	// display searchtext in UPPERCASE
	// searchBar.text = [searchText uppercaseString];
	searchBar.showsCancelButton = (searchText.length > 0);
	[ContactSelection setNameOrEmailFilter:searchText];
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
	[self setToolBar:nil];
	[super viewDidUnload];
}

- (void)contactsUpdated:(NSNotification *)notif {
	[tableController loadData];
}

@end
