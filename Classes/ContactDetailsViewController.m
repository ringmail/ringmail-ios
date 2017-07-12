/* ContactDetailsViewController.m
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

#import "ContactDetailsViewController.h"
#import "PhoneMainView.h"
#import "RgContactManager.h"
#import "RKContactStore.h"
#import "NSString+NSHash.h"
#import "DeepCopy.h"
#import "RKThreadStore.h"
#import "RgManager.h"

@implementation ContactDetailsViewController

@synthesize tableController;
@synthesize contact;
@synthesize editButton;
@synthesize backButton;
@synthesize cancelButton;
@synthesize background;
@synthesize contactData;
@synthesize contactMD5;

static void sync_address_book(ABAddressBookRef addressBook, CFDictionaryRef info, void *context);

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"ContactDetailsViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		inhibUpdate = FALSE;
		addressBook = ABAddressBookCreateWithOptions(nil, nil);
		ABAddressBookRegisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
		contactData = @{};
		contactMD5 = @"";
	}
	return self;
}

- (void)dealloc {
	ABAddressBookUnregisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
	CFRelease(addressBook);
}

#pragma mark - Event Functions

- (void)contactsUpdated:(NSNotification *)notif {
	dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@"RingMail - Update Contact Details");
    	UIContactDetailsHeader *headerController = [tableController headerController];
    	NSString* contactID = [[NSNumber numberWithInteger:ABRecordGetRecordID((ABRecordRef)contact)] stringValue];
		[headerController setRgMember:[[RKContactStore sharedInstance] contactEnabled:contactID]];
		[headerController update];
	});
}

#pragma mark -

- (void)resetData {
	[self disableEdit:FALSE];
	if (contact == NULL) {
		ABAddressBookRevert(addressBook);
		return;
	}

	LOGI(@"Reset data to contact %p", contact);
	ABRecordID recordID = ABRecordGetRecordID(contact);
	ABAddressBookRevert(addressBook);
	contact = ABAddressBookGetPersonWithRecordID(addressBook, recordID);
	if (contact == NULL) {
		[[PhoneMainView instance] popCurrentView];
		return;
	}
	[tableController setContact:contact];
}

static void sync_address_book(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
	ContactDetailsViewController *controller = (__bridge ContactDetailsViewController *)context;
	if (!controller->inhibUpdate && ![[controller tableController] isEditing]) {
		[controller resetData];
	}
}

- (void)removeContact {
	if (contact == NULL) {
		[[PhoneMainView instance] popCurrentView];
		return;
	}

	// Remove contact from book
	if (ABRecordGetRecordID(contact) != kABRecordInvalidID) {
		CFErrorRef error = NULL;
		ABAddressBookRemoveRecord(addressBook, contact, (CFErrorRef *)&error);
		if (error != NULL) {
			LOGE(@"Remove contact %p: Fail(%@)", contact, [(__bridge NSError *)error localizedDescription]);
		} else {
			LOGI(@"Remove contact %p: Success!", contact);
		}
		contact = NULL;

		// Save address book
		error = NULL;
		inhibUpdate = TRUE;
		ABAddressBookSave(addressBook, (CFErrorRef *)&error);
		inhibUpdate = FALSE;
		if (error != NULL) {
			LOGE(@"Save AddressBook: Fail(%@)", [(__bridge NSError *)error localizedDescription]);
		} else {
			LOGI(@"Save AddressBook: Success!");
            RgContactManager *ct = [[LinphoneManager instance] contactManager];
            NSArray *updated = [ct getContactList:YES];
            [ct sendContactData:updated];
		}
		[[LinphoneManager instance].fastAddressBook reload];
	}
}

- (void)saveData {
	if (contact == NULL) {
		[[PhoneMainView instance] popCurrentView];
		return;
	}

	// Add contact to book
	CFErrorRef error = NULL;
	if (ABRecordGetRecordID(contact) == kABRecordInvalidID) {
		ABAddressBookAddRecord(addressBook, contact, (CFErrorRef *)&error);
		if (error != NULL) {
			LOGE(@"Add contact %p: Fail(%@)", contact, [(__bridge NSError *)error localizedDescription]);
		} else {
			LOGI(@"Add contact %p: Success!", contact);
		}
	}

	// Save address book
	error = NULL;
	inhibUpdate = TRUE;
	ABAddressBookSave(addressBook, (CFErrorRef *)&error);
	inhibUpdate = FALSE;
	if (error != NULL) {
		LOGE(@"Save AddressBook: Fail(%@)", [(__bridge NSError *)error localizedDescription]);
	} else {
		LOGI(@"Save AddressBook: Success!");
        RgContactManager *ct = [[LinphoneManager instance] contactManager];
        NSArray *updated = [ct getContactList:YES];
        [ct sendContactData:updated];
		
		NSString* origMD5 = contactMD5;
		NSDictionary* origData = [contactData deepCopy];
		NSLog(@"Old Contact Data(%@): %@", contactMD5, contactData);
		contactData = [[LinphoneManager instance].fastAddressBook contactData:contact];
		contactMD5 = [[self toJSON:contactData] MD5];
		NSLog(@"New Contact Data(%@): %@", contactMD5, contactData);
		if (! [origMD5 isEqualToString:contactMD5])
		{
			NSDictionary* changes = [self findContactChanges:contactData from:origData];
			NSNumber *recordId = [NSNumber numberWithInteger:ABRecordGetRecordID(contact)];
			NSLog(@"%s: Contact Changes(%@): %@", __PRETTY_FUNCTION__, recordId, changes);
			[[RKThreadStore sharedInstance] updateContact:recordId changes:changes];
			[[RKThreadStore sharedInstance] dumpThreads];
			[[NSNotificationCenter defaultCenter] postNotificationName:kRgContactsUpdated object:self userInfo:@{
				@"id": recordId,
			}];
		}
	}
	[[LinphoneManager instance].fastAddressBook reload];
	
	[tableController.tableView setContentOffset:CGPointZero animated:YES];
}

- (void)selectContact:(ABRecordRef)acontact andReload:(BOOL)reload {
	contact = NULL;
	[self resetData];
	contact = acontact;
	[tableController setContact:contact];
	
	// Load current data
	contactData = [[LinphoneManager instance].fastAddressBook contactData:contact];
	contactMD5 = [[self toJSON:contactData] MD5];
	NSLog(@"%s: Contact Data: %@", __PRETTY_FUNCTION__, contactData);

	if (reload) {
		[self enableEdit:FALSE];
		[[tableController tableView] reloadData];
	}
}

- (void)addCurrentContactContactField:(NSString *)address {
	if ([address rangeOfString:@"@"].length > 0)
    {
		[tableController addEmailField:address];
	}
    else
    {
		[tableController addPhoneField:address];
	}

	[self enableEdit:FALSE];
	[[tableController tableView] reloadData];
}

- (void)newContact {
	[self selectContact:ABPersonCreate() andReload:YES];
}

- (void)newContact:(NSString *)address {
	[self selectContact:ABPersonCreate() andReload:NO];
	//[self addCurrentContactContactField:address];
	if ([address rangeOfString:@"@"].length > 0)
    {
		[tableController addEmailField:address];
	}
    else if (linphone_proxy_config_is_phone_number(NULL, [address UTF8String]))
    {
		[tableController addPhoneField:address];
	}
	[self enableEdit:FALSE];
	[[tableController tableView] reloadData];
}

- (void)editContact:(ABRecordRef)acontact {
	[self selectContact:ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(acontact)) andReload:YES];
}

- (void)editContact:(ABRecordRef)acontact address:(NSString *)address {
	[self selectContact:ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(acontact)) andReload:NO];
	[self addCurrentContactContactField:address];
}

- (void)setContact:(ABRecordRef)acontact {
	[self selectContact:ABAddressBookGetPersonWithRecordID(addressBook, ABRecordGetRecordID(acontact)) andReload:NO];
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];

	// Set selected+over background: IB lack !
	/*[editButton setImage:[UIImage imageNamed:@"ringmail_edit-save-pressed.png"]
						  forState:(UIControlStateHighlighted | UIControlStateSelected)];*/

	// Set selected+disabled background: IB lack !
	//[editButton setImage:[UIImage imageNamed:@"contact_ok_disabled.png"]
	//					  forState:(UIControlStateDisabled | UIControlStateSelected)];

	//[LinphoneUtils buttonFixStates:editButton];
    
    [cancelButton setTitle:[NSString stringWithUTF8String:"\uf053"] forState:UIControlStateNormal];
    [backButton setTitle:[NSString stringWithUTF8String:"\uf053"] forState:UIControlStateNormal];

	[tableController.tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
	[tableController.tableView setBackgroundView:nil];					 // Can't do it in Xib: issue with ios4
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ([ContactSelection getSelectionMode] == ContactSelectionModeEdit ||
		[ContactSelection getSelectionMode] == ContactSelectionModeNone) {
		[editButton setHidden:FALSE];
	} else {
		[editButton setHidden:TRUE];
	}
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactsUpdated:)
                                                 name:kRgContactsUpdated
                                            object:nil];
	
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Contact Details"
																content:@"ContactDetailsViewController"
															   stateBar:nil
														stateBarEnabled:false
                                                                 navBar:nil
																 tabBar:@"UIMainBar"
                                                          navBarEnabled:true
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true];
	}
	return compositeDescription;
}

#pragma mark -

- (void)enableEdit:(BOOL)animated {
	if (![tableController isEditing]) {
		[tableController setEditing:TRUE animated:animated];
	}
	[editButton setTitle:@"Save" forState:UIControlStateNormal];
	[editButton setOn];
	[cancelButton setHidden:FALSE];
	[backButton setHidden:TRUE];
}

- (void)disableEdit:(BOOL)animated {
	if ([tableController isEditing]) {
		[tableController setEditing:FALSE animated:animated];
	}
	[editButton setTitle:@"Edit" forState:UIControlStateNormal];
	[editButton setOff];
	[cancelButton setHidden:TRUE];
	[backButton setHidden:FALSE];
}

#pragma mark - Action Functions

- (IBAction)onCancelClick:(id)event {
	[self disableEdit:TRUE];
	[self resetData];
}

- (IBAction)onBackClick:(id)event {
	if ([ContactSelection getSelectionMode] == ContactSelectionModeEdit) {
		[ContactSelection setSelectionMode:ContactSelectionModeNone];
	}
	[[PhoneMainView instance] popCurrentView];
}

- (IBAction)onEditClick:(id)event {
	if ([tableController isEditing]) {
		if ([tableController isValid]) {
			[self disableEdit:TRUE];
			[self saveData];
		}
	} else {
		[self enableEdit:TRUE];
	}
}

- (void)onRemove:(id)event {
	[self disableEdit:FALSE];
	[self removeContact];
	[[PhoneMainView instance] popCurrentView];
}

- (void)onModification:(id)event {
	if (![tableController isEditing] || [tableController isValid]) {
		[editButton setEnabled:TRUE];
	} else {
		[editButton setEnabled:FALSE];
	}
}

- (NSString*)toJSON:(NSDictionary*)input
{
    NSError *writeError = nil; 
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:input options:NSJSONWritingPrettyPrinted error:&writeError];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]; 
    return jsonString;
}

- (NSDictionary*)findContactChanges:(NSDictionary*)current from:(NSDictionary*)original
{
	// Find removals & additions
	NSMutableDictionary* add_email = [NSMutableDictionary dictionary];
	NSMutableDictionary* del_email = [NSMutableDictionary dictionary];
	for (NSString* s in (NSArray*)original[@"email"])
	{
		del_email[s] = @1;
	}
	for (NSString* s in (NSArray*)current[@"email"])
	{
		if (del_email[s] != nil)
		{
			[del_email removeObjectForKey:s];
		}
		else
		{
			add_email[s] = @1;
		}
	}
	NSMutableDictionary* add_phone = [NSMutableDictionary dictionary];
	NSMutableDictionary* del_phone = [NSMutableDictionary dictionary];
	for (NSString* s in (NSArray*)original[@"phone"])
	{
		del_phone[s] = @1;
	}
	for (NSString* s in (NSArray*)current[@"phone"])
	{
		if (del_phone[s] != nil)
		{
			[del_phone removeObjectForKey:s];
		}
		else
		{
			add_phone[s] = @1;
		}
	}
	
	NSMutableDictionary* changes = [NSMutableDictionary dictionary];
	NSInteger original_emails = [(NSArray*)original[@"email"] count];
	NSInteger current_emails = [(NSArray*)current[@"email"] count];
	NSInteger max_emails = MAX(original_emails, current_emails);
	for (NSInteger i = 0; i < max_emails; i++)
	{
		if (i < original_emails && i < current_emails)
		{
			if (! [original[@"email"][i] isEqualToString:current[@"email"][i]])
			{
				if (del_email[original[@"email"][i]] && add_email[current[@"email"][i]])
				{
    				changes[original[@"email"][i]] = current[@"email"][i];
					[del_email removeObjectForKey:original[@"email"][i]];
					[add_email removeObjectForKey:current[@"email"][i]];
				}
			}
		}
	}	
	NSInteger original_phones = [(NSArray*)original[@"phone"] count];
	NSInteger current_phones = [(NSArray*)current[@"phone"] count];
	NSInteger max_phones = MAX(original_phones, current_phones);
	for (NSInteger i = 0; i < max_phones; i++)
	{
		if (i < original_phones && i < current_phones)
		{
			if (! [original[@"phone"][i] isEqualToString:current[@"phone"][i]])
			{
				if (del_phone[original[@"phone"][i]] && add_phone[current[@"phone"][i]])
				{
    				changes[original[@"phone"][i]] = current[@"phone"][i];
					[del_phone removeObjectForKey:original[@"phone"][i]];
					[add_phone removeObjectForKey:current[@"phone"][i]];
				}
			}
		}
	}
	
	[add_phone addEntriesFromDictionary:add_email];
	[del_phone addEntriesFromDictionary:del_email];
	return @{
		@"change": changes,
		@"add": add_phone,
		@"delete": del_phone,
	};
}

@end
