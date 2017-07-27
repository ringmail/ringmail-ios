/* ContactDetailsTableViewController.m
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

#import "ContactDetailsTableViewController.h"
#import "PhoneMainView.h"
#import "UIEditableTableViewCell.h"
#import "UACellBackgroundView.h"
#import "OrderedDictionary.h"
#import "FastAddressBook.h"
#import "DTAlertView.h"
#import "Utils.h"
#import "RKContactStore.h"

@interface Entry : NSObject

@property(assign) ABMultiValueIdentifier identifier;

@end

@implementation Entry

@synthesize identifier;

#pragma mark - Lifecycle Functions

- (id)initWithData:(ABMultiValueIdentifier)aidentifier {
	self = [super init];
	if (self != NULL) {
		[self setIdentifier:aidentifier];
	}
	return self;
}

@end

@implementation ContactDetailsTableViewController

static const ContactSections_e contactSections[ContactSections_MAX] = {ContactSections_None, ContactSections_Email, ContactSections_Number, ContactSections_Options};

@synthesize footerController;
@synthesize headerController;
@synthesize optionsController;
@synthesize contactDetailsDelegate;
@synthesize contact;

#pragma mark - Lifecycle Functions

- (void)initContactDetailsTableViewController {
	dataCache = [[NSMutableArray alloc] init];

	// pre-fill the data-cache with empty arrays
	for (int i = ContactSections_Number; i < ContactSections_MAX; i++) {
		[dataCache addObject:@[]];
	}

	labelArray = [[NSMutableArray alloc]
		initWithObjects:[NSString stringWithString:(NSString *)kABPersonPhoneMainLabel],
                        @"work",
						[NSString stringWithString:(NSString *)kABPersonPhoneMobileLabel],
                        nil];
	editingIndexPath = nil;
	self.member = NO;
}

- (id)init {
	self = [super init];
	if (self) {
		[self initContactDetailsTableViewController];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initContactDetailsTableViewController];
	}
	return self;
}

- (void)dealloc {
	if (contact != nil && ABRecordGetRecordID(contact) == kABRecordInvalidID) {
		CFRelease(contact);
	}
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];
	[headerController view]; // Force view load
	[footerController view]; // Force view load
    [optionsController view]; // Force view load
    
	self.tableView.accessibilityIdentifier = @"Contact numbers table";
    
}

#pragma mark -

- (BOOL)isValid {
	return [headerController isValid];
}

- (void)updateModification {
	[contactDetailsDelegate onModification:nil];
}

- (NSMutableArray *)getSectionData:(NSInteger)section {
	if (contactSections[section] == ContactSections_Number) {
		return [dataCache objectAtIndex:0];
	} else if (contactSections[section] == ContactSections_Email) {
		return [dataCache objectAtIndex:1];
	}
	return nil;
}

- (ABPropertyID)propertyIDForSection:(ContactSections_e)section {
	switch (section) {
	case ContactSections_Number:
		return kABPersonPhoneProperty;
	case ContactSections_Email:
		return kABPersonEmailProperty;
	default:
		return kABInvalidPropertyType;
	}
}

- (NSDictionary *)getLocalizedLabels {
	OrderedDictionary *dict = [[OrderedDictionary alloc] initWithCapacity:[labelArray count]];
	for (NSString *str in labelArray) {
		[dict setObject:[FastAddressBook localizedLabel:str] forKey:str];
	}
	return dict;
}

- (void)loadData {
	[dataCache removeAllObjects];

	if (contact == NULL)
		return;

	LOGI(@"Load data from contact %p", contact);
	// Phone numbers
	{
		ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonPhoneProperty);
		NSMutableArray *subArray = [NSMutableArray array];
		if (lMap) {
			for (int i = 0; i < ABMultiValueGetCount(lMap); ++i) {
				ABMultiValueIdentifier identifier = ABMultiValueGetIdentifierAtIndex(lMap, i);
				Entry *entry = [[Entry alloc] initWithData:identifier];
				[subArray addObject:entry];
			}
			CFRelease(lMap);
		}
		[dataCache addObject:subArray];
	}
    
	// Email
	{
		ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonEmailProperty);
		NSMutableArray *subArray = [NSMutableArray array];
		if (lMap) {
			for (int i = 0; i < ABMultiValueGetCount(lMap); ++i) {
				ABMultiValueIdentifier identifier = ABMultiValueGetIdentifierAtIndex(lMap, i);
				//CFDictionaryRef lDict = ABMultiValueCopyValueAtIndex(lMap, i);
				Entry *entry = [[Entry alloc] initWithData:identifier];
				[subArray addObject:entry];
				//CFRelease(lDict);
			}
			CFRelease(lMap);
		}
		[dataCache addObject:subArray];
	}
    
    //NSLog(@"RingMail: Data Cache: %@", dataCache);

	if (contactDetailsDelegate != nil) {
		[contactDetailsDelegate onModification:nil];
	}
	[self.tableView reloadData];
}

- (Entry *)setOrCreateSipContactEntry:(Entry *)entry withValue:(NSString *)value {
	ABMultiValueRef lcMap = ABRecordCopyValue(contact, kABPersonInstantMessageProperty);
	ABMutableMultiValueRef lMap;
	if (lcMap != NULL) {
		lMap = ABMultiValueCreateMutableCopy(lcMap);
		CFRelease(lcMap);
	} else {
		lMap = ABMultiValueCreateMutable(kABStringPropertyType);
	}
	ABMultiValueIdentifier index;
	CFErrorRef error = NULL;

	NSDictionary *lDict = @{
		(NSString *)kABPersonInstantMessageUsernameKey : value, (NSString *)
		kABPersonInstantMessageServiceKey : [LinphoneManager instance].contactSipField
	};

	if (entry) {
		index = (int)ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
		ABMultiValueReplaceValueAtIndex(lMap, (__bridge CFTypeRef)(lDict), index);
	} else {
		CFStringRef label = (__bridge CFStringRef)[labelArray objectAtIndex:0];
		ABMultiValueAddValueAndLabel(lMap, (__bridge CFTypeRef)lDict, label, &index);
	}

	if (!ABRecordSetValue(contact, kABPersonInstantMessageProperty, lMap, &error)) {
		LOGI(@"Can't set contact with value [%@] cause [%@]", value, [(__bridge NSError *)error localizedDescription]);
		CFRelease(lMap);
	} else {
		if (entry == nil) {
			entry = [[Entry alloc] initWithData:index];
		}
		CFRelease(lMap);
        
		/*check if message type is kept or not*/
		lcMap = ABRecordCopyValue(contact, kABPersonInstantMessageProperty);
		lMap = ABMultiValueCreateMutableCopy(lcMap);
		CFRelease(lcMap);
		index = (int)ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
		lDict = CFBridgingRelease(ABMultiValueCopyValueAtIndex(lMap, index));

		if ([lDict objectForKey:(__bridge NSString *)kABPersonInstantMessageServiceKey] == nil) {
			/*too bad probably a gtalk number, storing uri*/
			NSString *username = [lDict objectForKey:(NSString *)kABPersonInstantMessageUsernameKey];
			LinphoneAddress *address = linphone_core_interpret_url([LinphoneManager getLc], [username UTF8String]);
			if (address) {
				char *uri = linphone_address_as_string_uri_only(address);
				NSDictionary *dict2 = @{
					(NSString *)kABPersonInstantMessageUsernameKey :
									[NSString stringWithCString:uri encoding:[NSString defaultCStringEncoding]],
								(NSString *)
					kABPersonInstantMessageServiceKey : [LinphoneManager instance].contactSipField
				};

				ABMultiValueReplaceValueAtIndex(lMap, (__bridge CFTypeRef)(dict2), index);

				if (!ABRecordSetValue(contact, kABPersonInstantMessageProperty, lMap, &error)) {
					LOGI(@"Can't set contact with value [%@] cause [%@]", value,
						 [(__bridge NSError *)error localizedDescription]);
				}
				linphone_address_destroy(address);
				ms_free(uri);
			}
		}
		CFRelease(lMap);
	}

	return entry;
}

- (void)setSipContactEntry:(Entry *)entry withValue:(NSString *)value {
	[self setOrCreateSipContactEntry:entry withValue:value];
}

- (void)addEntry:(UITableView *)tableview section:(NSInteger)section animated:(BOOL)animated {
	[self addEntry:tableview section:section animated:animated value:@""];
}

- (void)addEntry:(UITableView *)tableview section:(NSInteger)section animated:(BOOL)animated value:(NSString *)value {
	NSMutableArray *sectionArray = [self getSectionData:section];
	NSUInteger count = [sectionArray count];
	CFErrorRef error = NULL;
	bool added = TRUE;
	if (contactSections[section] == ContactSections_Number) {
		ABMultiValueIdentifier identifier;
		ABMultiValueRef lcMap = ABRecordCopyValue(contact, kABPersonPhoneProperty);
		ABMutableMultiValueRef lMap;
		if (lcMap != NULL) {
			lMap = ABMultiValueCreateMutableCopy(lcMap);
			CFRelease(lcMap);
		} else {
			lMap = ABMultiValueCreateMutable(kABStringPropertyType);
		}
		CFStringRef label = (__bridge CFStringRef)[labelArray objectAtIndex:0];
		if (!ABMultiValueAddValueAndLabel(lMap, (__bridge CFTypeRef)(value), label, &identifier)) {
			added = false;
		}

		if (added && ABRecordSetValue(contact, kABPersonPhoneProperty, lMap, &error)) {
			Entry *entry = [[Entry alloc] initWithData:identifier];
			[sectionArray addObject:entry];
		} else {
			added = false;
			LOGI(@"Can't add entry: %@", [(__bridge NSError *)error localizedDescription]);
		}
		CFRelease(lMap);
	} else if (contactSections[section] == ContactSections_Email) {
		ABMultiValueIdentifier identifier;
		ABMultiValueRef lcMap = ABRecordCopyValue(contact, kABPersonEmailProperty);
		ABMutableMultiValueRef lMap;
		if (lcMap != NULL) {
			lMap = ABMultiValueCreateMutableCopy(lcMap);
			CFRelease(lcMap);
		} else {
			lMap = ABMultiValueCreateMutable(kABStringPropertyType);
		}
		CFStringRef label = (__bridge CFStringRef)[labelArray objectAtIndex:0];
		if (!ABMultiValueAddValueAndLabel(lMap, (__bridge CFTypeRef)(value), label, &identifier)) {
			added = false;
		}

		if (added && ABRecordSetValue(contact, kABPersonEmailProperty, lMap, &error)) {
			Entry *entry = [[Entry alloc] initWithData:identifier];
			[sectionArray addObject:entry];
		} else {
			added = false;
			LOGI(@"Can't add entry: %@", [(__bridge NSError *)error localizedDescription]);
		}
		CFRelease(lMap);
	}

	if (added && animated) {
		// Update accessory
		if (count > 0) {
			[tableview reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:count - 1
																						  inSection:section]]
							 withRowAnimation:FALSE];
		}
		[tableview
			insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:count inSection:section]]
				  withRowAnimation:UITableViewRowAnimationFade];
	}
	if (contactDetailsDelegate != nil) {
		[contactDetailsDelegate onModification:nil];
	}
}

- (void)removeEmptyEntry:(UITableView *)tableview section:(NSInteger)section animated:(BOOL)animated {
	NSMutableArray *sectionDict = [self getSectionData:section];
	NSInteger row = [sectionDict count] - 1;
	if (row >= 0) {
		Entry *entry = [sectionDict objectAtIndex:row];

		ABPropertyID property = [self propertyIDForSection:contactSections[section]];
		if (property != kABInvalidPropertyType) {
			ABMultiValueRef lMap = ABRecordCopyValue(contact, property);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			CFTypeRef valueRef = ABMultiValueCopyValueAtIndex(lMap, index);
			CFTypeRef toRelease = nil;
			NSString *value = nil;
			if (property == kABPersonInstantMessageProperty) {
				// when we query the instanteMsg property we get a dictionary instead of a value
				toRelease = valueRef;
				value = CFDictionaryGetValue(valueRef, kABPersonInstantMessageUsernameKey);
			} else {
				value = CFBridgingRelease(valueRef);
			}

			if (value.length == 0) {
				[self removeEntry:tableview path:[NSIndexPath indexPathForRow:row inSection:section] animated:animated];
			}
			if (toRelease != nil) {
				CFRelease(toRelease);
			}

			CFRelease(lMap);
		}
	}
	if (contactDetailsDelegate != nil) {
		[contactDetailsDelegate onModification:nil];
	}
}

- (void)removeEntry:(UITableView *)tableview path:(NSIndexPath *)indexPath animated:(BOOL)animated {
	NSMutableArray *sectionArray = [self getSectionData:[indexPath section]];
	Entry *entry = [sectionArray objectAtIndex:[indexPath row]];
	ABPropertyID property = [self propertyIDForSection:contactSections[indexPath.section]];

	if (property != kABInvalidPropertyType) {
		ABMultiValueRef lcMap = ABRecordCopyValue(contact, property);
		ABMutableMultiValueRef lMap = ABMultiValueCreateMutableCopy(lcMap);
		CFRelease(lcMap);
		NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
		ABMultiValueRemoveValueAndLabelAtIndex(lMap, index);
		ABRecordSetValue(contact, property, lMap, nil);
		CFRelease(lMap);
	}

	[sectionArray removeObjectAtIndex:[indexPath row]];

	NSArray *tagInsertIndexPath = [NSArray arrayWithObject:indexPath];
	if (animated) {
		[tableview deleteRowsAtIndexPaths:tagInsertIndexPath withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - Property Functions

- (void)setContact:(ABRecordRef)acontact {
	if (contact != nil && ABRecordGetRecordID(contact) == kABRecordInvalidID) {
		CFRelease(contact);
	}
	contact = acontact;
	NSString* contactID = [[NSNumber numberWithInteger:ABRecordGetRecordID((ABRecordRef)contact)] stringValue];
    self.member = [[RKContactStore sharedInstance] contactEnabled:contactID];
    [self loadData];
    [headerController setRgMember:self.member];
    [headerController setContact:contact];
    [optionsController setRgMember:self.member];
    [optionsController setContact:contact];
}

- (void)addPhoneField:(NSString *)number {
	int i = 0;
	while (i < ContactSections_MAX && contactSections[i] != ContactSections_Number)
		++i;
	[self addEntry:[self tableView] section:i animated:FALSE value:number];
}

- (void)addEmailField:(NSString *)address {
	int i = 0;
	while (i < ContactSections_MAX && contactSections[i] != ContactSections_Email)
		++i;
	[self addEntry:[self tableView] section:i animated:FALSE value:address];
}

-(NSString*) capFirstLtr:(NSString *)sIn
{
    return [NSString stringWithFormat:@"%@%@",[[sIn substringToIndex:1] capitalizedString],[sIn substringFromIndex:1]];
}

#pragma mark - UITableViewDataSource Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return ContactSections_MAX;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self getSectionData:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *kCellId = @"ContactDetailsCell";
	UIEditableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
	if (cell == nil) {
		cell = [[UIEditableTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kCellId];
		[cell.detailTextField setDelegate:self];
		[cell.detailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
		[cell.detailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
		[cell setBackgroundColor:[UIColor whiteColor]];
        
		// Background View
		UACellBackgroundView *selectedBackgroundView = [[UACellBackgroundView alloc] initWithFrame:CGRectZero];
		cell.selectedBackgroundView = selectedBackgroundView;
		[selectedBackgroundView setBackgroundColor:LINPHONE_TABLE_CELL_BACKGROUND_COLOR];
	}
    
	NSMutableArray *sectionDict = [self getSectionData:[indexPath section]];
	Entry *entry = [sectionDict objectAtIndex:[indexPath row]];

	NSString *value = @"";
	// default label is our app name
	NSString *label = [FastAddressBook localizedLabel:[labelArray objectAtIndex:0]];
    
	if (contactSections[[indexPath section]] == ContactSections_Number) {
		ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonPhoneProperty);
		NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
		NSString *labelRef = CFBridgingRelease(ABMultiValueCopyLabelAtIndex(lMap, index));
		if (labelRef != NULL) {
            //NSLog(@"RingMail: Label Ref - %@", labelRef);
			label = [FastAddressBook localizedLabel:labelRef];
		}
		NSString *valueRef = CFBridgingRelease(ABMultiValueCopyValueAtIndex(lMap, index));
		value = [RgManager formatPhoneNumber:valueRef];
		CFRelease(lMap);
	} else if (contactSections[[indexPath section]] == ContactSections_Email) {
		ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonEmailProperty);
		NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
		NSString *labelRef = CFBridgingRelease(ABMultiValueCopyLabelAtIndex(lMap, index));
		if (labelRef != NULL) {
			label = [FastAddressBook localizedLabel:labelRef];
		}
		NSString *valueRef = CFBridgingRelease(ABMultiValueCopyValueAtIndex(lMap, index));
		if (valueRef != NULL) {
			value = [FastAddressBook localizedLabel:valueRef];
		}
		CFRelease(lMap);
	}
    
    NSString *capLabel = [self capFirstLtr:label];
    
	[cell.textLabel setText:capLabel];
    cell.textAlignment = NSTextAlignmentLeft;
	[cell.detailTextLabel setText:value];
	[cell.detailTextField setText:value];
	if (contactSections[[indexPath section]] == ContactSections_Number) {
		[cell.detailTextField setKeyboardType:UIKeyboardTypePhonePad];
		[cell.detailTextField setPlaceholder:NSLocalizedString(@"Phone number", nil)];
	} else if (contactSections[[indexPath section]] == ContactSections_Email) {
		[cell.detailTextField setKeyboardType:UIKeyboardTypeASCIICapable];
		[cell.detailTextField setPlaceholder:NSLocalizedString(@"Email address", nil)];
	}
    
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	NSMutableArray *sectionDict = [self getSectionData:[indexPath section]];
	Entry *entry = [sectionDict objectAtIndex:[indexPath row]];
	if (![self isEditing]) {
 
	} else {
		NSString *key = nil;
		ABPropertyID property = [self propertyIDForSection:contactSections[indexPath.section]];

		if (property != kABInvalidPropertyType) {
			ABMultiValueRef lMap = ABRecordCopyValue(contact, property);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			NSString *labelRef = CFBridgingRelease(ABMultiValueCopyLabelAtIndex(lMap, index));
			if (labelRef != NULL) {
				key = (NSString *)(labelRef);
			}
			CFRelease(lMap);
		}
		if (key != nil) {
			editingIndexPath = indexPath;
			ContactDetailsLabelViewController *controller = DYNAMIC_CAST(
				[[PhoneMainView instance] changeCurrentView:[ContactDetailsLabelViewController compositeViewDescription]
													   push:TRUE],
				ContactDetailsLabelViewController);
			if (controller != nil) {
				[controller setDataList:[self getLocalizedLabels]];
				[controller setSelectedData:key];
				[controller setDelegate:self];
			}
		}
	}
}

- (void)tableView:(UITableView *)tableView
	commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
	 forRowAtIndexPath:(NSIndexPath *)indexPath {
	[LinphoneUtils findAndResignFirstResponder:[self tableView]];
	if (editingStyle == UITableViewCellEditingStyleInsert) {
		[tableView beginUpdates];
		[self addEntry:tableView section:[indexPath section] animated:TRUE];
		[tableView endUpdates];
	} else if (editingStyle == UITableViewCellEditingStyleDelete) {
		[tableView beginUpdates];
		[self removeEntry:tableView path:indexPath animated:TRUE];
		[tableView endUpdates];
	}
}


#pragma mark - Mail Compose Delegate Functions

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"sent");
    }
    [[PhoneMainView instance] dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITableViewDelegate Functions

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	// Resign keyboard
	if (!editing) {
		[LinphoneUtils findAndResignFirstResponder:[self tableView]];
	}

	[headerController setEditing:editing animated:animated];
	[footerController setEditing:editing animated:animated];

	if (animated) {
		[self.tableView beginUpdates];
	}
	if (editing) {
		// add phony entries so that the user can add new data
		for (int section = 0; section < [self numberOfSectionsInTableView:[self tableView]]; ++section) {
			if (contactSections[section] == ContactSections_Number ||
				(contactSections[section] == ContactSections_Email)) {
				[self addEntry:self.tableView section:section animated:animated];
			}
		}
	} else {
		for (int section = 0; section < [self numberOfSectionsInTableView:[self tableView]]; ++section) {
			// remove phony entries that were not filled by the user
			if (contactSections[section] == ContactSections_Number ||
				(contactSections[section] == ContactSections_Email)) {

				[self removeEmptyEntry:self.tableView section:section animated:animated];
				if ([[self getSectionData:section] count] == 0 && animated) { // the section is empty -> remove titles
					[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
								  withRowAnimation:UITableViewRowAnimationFade];
				}
			}
		}
	}
	if (animated) {
		[self.tableView endUpdates];
	}

	[super setEditing:editing animated:animated];
	if (contactDetailsDelegate != nil) {
		[contactDetailsDelegate onModification:nil];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
		   editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger last_index = [[self getSectionData:[indexPath section]] count] - 1;
	if (indexPath.row == last_index) {
		return UITableViewCellEditingStyleInsert;
	}
	return UITableViewCellEditingStyleDelete;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

	if (section == ContactSections_None) {
		return [headerController view];
	} else if (section == ContactSections_Options) {
        return [optionsController view];
    } else {
        
        UIView *tmp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 46)];
        tmp.backgroundColor = UIColor.whiteColor;
        
        UILabel *phoneLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 30, self.view.bounds.size.width - 40, 16)];
        phoneLabel.font = [UIFont fontWithName:@"SFUIText-Medium" size:16];
        phoneLabel.numberOfLines = 1;
        phoneLabel.backgroundColor = [UIColor whiteColor];
        phoneLabel.textColor = [UIColor colorWithHex:@"#444444"];
        phoneLabel.textAlignment = NSTextAlignmentLeft;
        
        if (section == ContactSections_Email)
            phoneLabel.text = NSLocalizedString(@"Email Addresses", nil);
        else if (section == ContactSections_Number)
            phoneLabel.text = NSLocalizedString(@"Phone Numbers", nil);
        
        [tmp addSubview:phoneLabel];
        return tmp;
	}
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if (section == (ContactSections_MAX - 2)) {
		if (ABRecordGetRecordID(contact) != kABRecordInvalidID) {
			return [footerController view];
		}
	}
	return nil;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == ContactSections_None) {
		return [UIContactDetailsHeader height:[headerController isEditing] member:self.member];
	} else if (section == ContactSections_Options) {
        return [UIContactDetailsOptions height];
    } else if (section == ContactSections_Number) {
        if ([[dataCache objectAtIndex:0] count] > 0) {
            return 46;
        } else {
            return 0.000001f;
        }
    } else if (section == ContactSections_Email) {
        if ([[dataCache objectAtIndex:1] count] > 0) {
            return 46;
        } else {
            return 0.000001f;
        }
    } else
        return 0.000001f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if (section == (ContactSections_MAX - 2)) {
		if (ABRecordGetRecordID(contact) != kABRecordInvalidID) {
			return [UIContactDetailsFooter height:[footerController isEditing]];
		} else {
			return 0.000001f; // Hack UITableView = 0
		}
	} else if (section == ContactSections_None) {
		return 0.000001f; // Hack UITableView = 0
	}
//	return 10.0f;
    return 0.000001f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}

#pragma mark - ContactDetailsLabelDelegate Functions

- (void)changeContactDetailsLabel:(NSString *)value {
	if (value != nil) {
		NSInteger section = editingIndexPath.section;
		NSMutableArray *sectionDict = [self getSectionData:section];
		ABPropertyID property = [self propertyIDForSection:(int)section];
		Entry *entry = [sectionDict objectAtIndex:editingIndexPath.row];

		if (property != kABInvalidPropertyType) {
			ABMultiValueRef lcMap = ABRecordCopyValue(contact, kABPersonPhoneProperty);
			ABMutableMultiValueRef lMap = ABMultiValueCreateMutableCopy(lcMap);
			CFRelease(lcMap);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			ABMultiValueReplaceLabelAtIndex(lMap, (__bridge CFStringRef)(value), index);
			ABRecordSetValue(contact, kABPersonPhoneProperty, lMap, nil);
			CFRelease(lMap);
		}

		[self.tableView beginUpdates];
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:editingIndexPath] withRowAnimation:FALSE];
		[self.tableView reloadSectionIndexTitles];
		[self.tableView endUpdates];
	}
	editingIndexPath = nil;
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
	if (contactDetailsDelegate != nil) {
		[self performSelector:@selector(updateModification) withObject:nil afterDelay:0];
	}
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	UIView *view = [textField superview];
	// Find TableViewCell
	while (view != nil && ![view isKindOfClass:[UIEditableTableViewCell class]])
		view = [view superview];
	if (view != nil) {
		UIEditableTableViewCell *cell = (UIEditableTableViewCell *)view;
		NSIndexPath *path = [self.tableView indexPathForCell:cell];
		NSMutableArray *sectionDict = [self getSectionData:[path section]];
		Entry *entry = [sectionDict objectAtIndex:[path row]];
		ContactSections_e sect = contactSections[[path section]];

		ABPropertyID property = [self propertyIDForSection:sect];
		NSString *value = [textField text];

		if (property != kABInvalidPropertyType) {
			ABMultiValueRef lcMap = ABRecordCopyValue(contact, property);
			ABMutableMultiValueRef lMap = ABMultiValueCreateMutableCopy(lcMap);
			CFRelease(lcMap);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			ABMultiValueReplaceValueAtIndex(lMap, (__bridge CFStringRef)value, index);
			ABRecordSetValue(contact, property, lMap, nil);
			CFRelease(lMap);
		}
        
		[cell.detailTextLabel setText:value];
	} else {
		LOGE(@"Not valid UIEditableTableViewCell");
	}
	if (contactDetailsDelegate != nil) {
		[self performSelector:@selector(updateModification) withObject:nil afterDelay:0];
	}
	return TRUE;
}

@end
