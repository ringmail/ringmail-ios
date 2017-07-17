/* UIContactDetailsHeader.m
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
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "UIContactDetailsHeader.h"
#import "Utils.h"
#import "UIEditableTableViewCell.h"
#import "FastAddressBook.h"
#import "PhoneMainView.h"
#import "DTActionSheet.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "RKContactStore.h"

#import <MobileCoreServices/UTCoreTypes.h>

@implementation UIContactDetailsHeader

@synthesize avatarImage;
@synthesize avatarEditImage;
@synthesize addressLabel;
@synthesize contact;
@synthesize normalView;
@synthesize editView;
@synthesize tableView;
@synthesize contactDetailsDelegate;
@synthesize popoverController;
@synthesize rgInvite;
@synthesize rgMember;
@synthesize callButton;
@synthesize chatButton;
@synthesize videoButton;
@synthesize favoriteButton;

#pragma mark - Lifecycle Functions

- (void)initUIContactDetailsHeader {
	propertyList = [[NSArray alloc] initWithObjects:[NSNumber numberWithInt:kABPersonFirstNameProperty],
													[NSNumber numberWithInt:kABPersonLastNameProperty],
													[NSNumber numberWithInt:kABPersonOrganizationProperty], nil];
	editing = FALSE;
	rgMember = FALSE;
}

- (id)init {
	self = [super init];
	if (self != nil) {
		[self initUIContactDetailsHeader];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self != nil) {
		[self initUIContactDetailsHeader];
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self != nil) {
		[self initUIContactDetailsHeader];
	}
	return self;
}

#pragma mark - ViewController  Functions

- (void)viewDidLoad {
	[super viewDidLoad];
	[tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
	[tableView setBackgroundView:nil];					 // Can't do it in Xib: issue with ios4
	[normalView setAlpha:1.0f];
	[editView setAlpha:0.0f];
	[tableView setEditing:TRUE animated:false];
	tableView.accessibilityIdentifier = @"Contact Name Table";
}


#pragma mark - Propery Functions

- (void)setContact:(ABRecordRef)acontact {
	contact = acontact;
	[self update];
}

#pragma mark -

- (BOOL)isValid {
	for (int i = 0; i < [propertyList count]; ++i) {
		UIEditableTableViewCell *cell =
			(UIEditableTableViewCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
		if ([cell.detailTextField.text length] > 0)
			return true;
	}
	return false;
}

- (void)update {
	if (contact == NULL) {
		LOGW(@"Cannot update contact details header: null contact");
		return;
	}
	
	NSNumber* contactNum = [NSNumber numberWithInteger:ABRecordGetRecordID((ABRecordRef)contact)];
    NSString* contactID = [contactNum stringValue];
    rgMember = [[RKContactStore sharedInstance] contactEnabled:contactID];
    NSLog(@"RingMail: Contact ID: %@ - has rg:%d", contactID, rgMember);
    if (rgMember)
    {
        BOOL fav = NO;
        NSString *rgAddress = [[RKContactStore sharedInstance] getPrimaryAddress:contactID];
        if (! [rgAddress isEqualToString:@""])
        {
			NSDictionary *sessionData = [[[LinphoneManager instance] chatManager] dbGetSessionID:rgAddress to:nil contact:contactNum uuid:nil];
            fav = [[[LinphoneManager instance] chatManager] dbIsFavorite:sessionData[@"id"]];
        }
        
        if (fav)
        {
            [favoriteButton setImage:[UIImage imageNamed:@"ringmail_favorite.png"] forState:UIControlStateNormal];
        }
        else
        {
            [favoriteButton setImage:[UIImage imageNamed:@"ringmail_favorite-pressed.png"] forState:UIControlStateNormal];
        }
        
        [favoriteButton setHidden:NO];
        [chatButton setHidden:NO];
        [callButton setHidden:NO];
        [videoButton setHidden:NO];
        [rgInvite setHidden:YES];
    }
    else
    {
        [favoriteButton setHidden:YES];
        [chatButton setHidden:YES];
        [callButton setHidden:YES];
        [videoButton setHidden:YES];
        [rgInvite setHidden:NO];
    }

	// Avatar image
	{
		UIImage *image = [FastAddressBook getContactImage:contact thumbnail:false];
		if (image == nil) {
			image = [UIImage imageNamed:@"avatar_unknown_small.png"];
		}
		
		[avatarImage setImage:[image thumbnailImage:200 transparentBorder:0 cornerRadius:100 interpolationQuality:kCGInterpolationHigh]];

        [avatarEditImage setImage:[image thumbnailImage:160 transparentBorder:0 cornerRadius:80 interpolationQuality:kCGInterpolationHigh]];
	}

	// Contact label
	{ [addressLabel setText:[FastAddressBook getContactDisplayName:contact]]; }
    
	[tableView reloadData];
}

+ (CGFloat)height:(BOOL)editing member:(BOOL)member
{
	if (editing)
	{
		return 280.0f;
	}
	else
	{
        return 280.0f;
		/*if (member)
		{
			return 200.0f;
		}
		else
		{
			return 160.0f;
		}*/
	}
}

- (void)setEditing:(BOOL)aediting animated:(BOOL)animated {
	editing = aediting;
	// Resign keyboard
	if (!editing) {
		[LinphoneUtils findAndResignFirstResponder:[self tableView]];
		[self update];
	}
	if (animated) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
	}
	if (editing) {
		[editView setAlpha:1.0f];
		[normalView setAlpha:0.0f];
	} else {
		[editView setAlpha:0.0f];
		[normalView setAlpha:1.0f];
	}
	if (animated) {
		[UIView commitAnimations];
	}
}

- (void)setEditing:(BOOL)aediting {
	[self setEditing:aediting animated:FALSE];
}

- (BOOL)isEditing {
	return editing;
}

- (void)updateModification {
	[contactDetailsDelegate onModification:nil];
}

#pragma mark - UITableViewDataSource Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [propertyList count];
}

- (UITableViewCell *)tableView:(UITableView *)atableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *kCellId = @"ContactDetailsHeaderCell";
	UIEditableTableViewCell *cell = [atableView dequeueReusableCellWithIdentifier:kCellId];
	if (cell == nil) {
		cell = [[UIEditableTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kCellId];
		[cell.detailTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
		[cell.detailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
		[cell.detailTextField setKeyboardType:UIKeyboardTypeDefault];
		[cell setBackgroundColor:[UIColor clearColor]];
    }
    
	// setup placeholder
	ABPropertyID property = [[propertyList objectAtIndex:[indexPath row]] intValue];
	if (property == kABPersonFirstNameProperty) {
		NSAttributedString *str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"First Name", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithHex:@"#939393"] }];
		cell.detailTextField.attributedPlaceholder = str;
        cell.detailTextField.textColor = [UIColor whiteColor];
	} else if (property == kABPersonLastNameProperty) {
		NSAttributedString *str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Last Name", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithHex:@"#939393"] }];
		cell.detailTextField.attributedPlaceholder = str;
        cell.detailTextField.textColor = [UIColor whiteColor];
	} else if (property == kABPersonOrganizationProperty) {
		NSAttributedString *str = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Company", nil) attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithHex:@"#939393"] }];
		cell.detailTextField.attributedPlaceholder = str;
        cell.detailTextField.textColor = [UIColor whiteColor];
	}
    
	[cell.detailTextField setKeyboardType:UIKeyboardTypeDefault];

	// setup values, if they exist
	if (contact) {
		NSString *lValue = CFBridgingRelease(ABRecordCopyValue(contact, property));
		if (lValue != NULL) {
			[cell.detailTextLabel setText:lValue];
			[cell.detailTextField setText:lValue];
		} else {
			[cell.detailTextLabel setText:@""];
			[cell.detailTextField setText:@""];
		}
	}
	[cell.detailTextField setDelegate:self];

	return cell;
}

#pragma mark - Action Functions

- (IBAction)onAvatarClick:(id)event {
	if (self.isEditing) {
		void (^showAppropriateController)(UIImagePickerControllerSourceType) =
			^(UIImagePickerControllerSourceType type) {
			  UICompositeViewDescription *description = [ImagePickerViewController compositeViewDescription];
			  ImagePickerViewController *controller;
			  if ([LinphoneManager runningOnIpad]) {
				  controller = DYNAMIC_CAST(
					  [[PhoneMainView instance].mainViewController getCachedController:description.content],
					  ImagePickerViewController);
				  // keep a reference to this controller so that in case of memory pressure we keep it
				  self.popoverController = controller;
			  } else {
				  controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:description push:TRUE],
											ImagePickerViewController);
			  }
			  if (controller != nil) {
				  controller.sourceType = type;

				  // Displays a control that allows the user to choose picture or
				  // movie capture, if both are available:
				  controller.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];

				  // Hides the controls for moving & scaling pictures, or for
				  // trimming movies. To instead show the controls, use YES.
				  controller.allowsEditing = NO;
				  controller.imagePickerDelegate = self;

				  if ([LinphoneManager runningOnIpad]) {
					  [controller.popoverController presentPopoverFromRect:[avatarImage frame]
																	inView:self.view
												  permittedArrowDirections:UIPopoverArrowDirectionAny
																  animated:FALSE];
				  }
			  }
			};
		DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:NSLocalizedString(@"Select picture source", nil)];
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
			[sheet addButtonWithTitle:NSLocalizedString(@"Camera", nil)
								block:^() {
								  showAppropriateController(UIImagePickerControllerSourceTypeCamera);
								}];
		}
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
			[sheet addButtonWithTitle:NSLocalizedString(@"Photo library", nil)
								block:^() {
								  showAppropriateController(UIImagePickerControllerSourceTypePhotoLibrary);
								}];
		}
		if ([FastAddressBook getContactImage:contact thumbnail:true] != nil) {
			[sheet addDestructiveButtonWithTitle:NSLocalizedString(@"Remove", nil)
										   block:^() {
											 CFErrorRef error = NULL;
											 if (!ABPersonRemoveImageData(contact, (CFErrorRef *)&error)) {
												 LOGI(@"Can't remove entry: %@",
													  [(__bridge NSError *)error localizedDescription]);
											 }
											 [self update];
										   }];
		}
		[sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil)
								  block:^{
									self.popoverController = nil;
								  }];

		[sheet showInView:[PhoneMainView instance].view];
	}
}

- (IBAction)onActionChat:(id)event {
   	if (contact == NULL)
    {
        LOGW(@"Cannot access contact: null contact");
        return;
    }
    NSString *rgAddress = [[RKContactStore sharedInstance] defaultPrimaryAddress:contact];
    if (rgAddress != nil)
    {
		RKCommunicator* comm = [RKCommunicator sharedInstance];
		RKAddress* address = [RKAddress newWithString:rgAddress];
		RKThread* thread = [comm getThreadByAddress:address];
		[comm startMessageView:thread];
    }
}

- (IBAction)onActionCall:(id)event {
    if (contact == NULL)
    {
        LOGW(@"Cannot access contact: null contact");
        return;
    }
	NSString *rgAddress = [[RKContactStore sharedInstance] defaultPrimaryAddress:contact];
    if (rgAddress != nil)
    {
		RKCommunicator* comm = [RKCommunicator sharedInstance];
		RKAddress* address = [RKAddress newWithString:rgAddress];
		[comm startCall:address video:NO];
    }
}

- (IBAction)onActionVideo:(id)event {
    if (contact == NULL)
    {
        LOGW(@"Cannot access contact: null contact");
        return;
    }
	NSString *rgAddress = [[RKContactStore sharedInstance] defaultPrimaryAddress:contact];
    if (rgAddress != nil)
    {
		RKCommunicator* comm = [RKCommunicator sharedInstance];
		RKAddress* address = [RKAddress newWithString:rgAddress];
		[comm startCall:address video:YES];
    }	
}

- (IBAction)onActionFavorite:(id)event {
	if (contact == NULL) {
		LOGW(@"Cannot update favorite: null contact");
		return;
	}
    
	NSNumber *contactNum = [NSNumber numberWithInteger:ABRecordGetRecordID((ABRecordRef)contact)];
    NSString *contactID = [contactNum stringValue];
    BOOL member = [[RKContactStore sharedInstance] contactEnabled:contactID];
    if (member)
    {
        BOOL fav = NO;
		NSString *rgAddress = [[RKContactStore sharedInstance] defaultPrimaryAddress:contact];
		NSDictionary *sessionData = [[[LinphoneManager instance] chatManager] dbGetSessionID:rgAddress to:nil contact:contactNum uuid:nil];
		NSNumber *session = sessionData[@"id"];
        
        LOGI(@"RingMail: Get Session ID: %@ | %@ -> %@", rgAddress, contactNum, session);
        
        if (! [rgAddress isEqualToString:@""])
        {
            fav = [[[LinphoneManager instance] chatManager] dbIsFavorite:session];
        }
        
        if (fav)
        {
            [[[LinphoneManager instance] chatManager] dbDeleteFavorite:session];
            [favoriteButton setImage:[UIImage imageNamed:@"ringmail_favorite-pressed.png"] forState:UIControlStateNormal];
        }
        else
        {
            [[[LinphoneManager instance] chatManager] dbAddFavorite:session];
            [favoriteButton setImage:[UIImage imageNamed:@"ringmail_favorite.png"] forState:UIControlStateNormal];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kRgMainRefresh object:self userInfo:nil];
    }
}

#pragma mark - ContactDetailsImagePickerDelegate Functions

- (void)imagePickerDelegateImage:(UIImage *)image info:(NSDictionary *)info {
	// Dismiss popover on iPad
	if ([LinphoneManager runningOnIpad]) {
		UICompositeViewDescription *description = [ImagePickerViewController compositeViewDescription];
		ImagePickerViewController *controller =
			DYNAMIC_CAST([[PhoneMainView instance].mainViewController getCachedController:description.content],
						 ImagePickerViewController);
		if (controller != nil) {
			[controller.popoverController dismissPopoverAnimated:TRUE];
			self.popoverController = nil;
		}
	}
	FastAddressBook *fab = [LinphoneManager instance].fastAddressBook;
	CFErrorRef error = NULL;
	if (!ABPersonRemoveImageData(contact, (CFErrorRef *)&error)) {
		LOGI(@"Can't remove entry: %@", [(__bridge NSError *)error localizedDescription]);
	}
	NSData *dataRef = UIImageJPEGRepresentation(image, 0.9f);
	CFDataRef cfdata = CFDataCreate(NULL, [dataRef bytes], [dataRef length]);

	[fab saveAddressBook];

	if (!ABPersonSetImageData(contact, cfdata, (CFErrorRef *)&error)) {
		LOGI(@"Can't add entry: %@", [(__bridge NSError *)error localizedDescription]);
	} else {
		[fab saveAddressBook];
	}

	CFRelease(cfdata);

	[self update];
}

#pragma mark - UITableViewDelegate Functions

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
		   editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView
shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
	if (contactDetailsDelegate != nil) {
		// add a mini delay to have the text updated BEFORE notifying the selector
		[self performSelector:@selector(updateModification) withObject:nil afterDelay:0.1];
	}
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	UIView *view = [textField superview];
	// Find TableViewCell
	while (view != nil && ![view isKindOfClass:[UIEditableTableViewCell class]])
		view = [view superview];

	if (view != nil) {
		UIEditableTableViewCell *cell = (UIEditableTableViewCell *)view;
		NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
		ABPropertyID property = [[propertyList objectAtIndex:[indexPath row]] intValue];
		[cell.detailTextLabel setText:[textField text]];
		CFErrorRef error = NULL;
		ABRecordSetValue(contact, property, (__bridge CFTypeRef)([textField text]), (CFErrorRef *)&error);
		if (error != NULL) {
			LOGE(@"Error when saving property %i in contact %p: Fail(%@)", property, contact,
				 [(__bridge NSError *)error localizedDescription]);
		}
	} else {
		LOGW(@"Not valid UIEditableTableViewCell");
	}
	if (contactDetailsDelegate != nil) {
		// add a mini delay to have the text updated BEFORE notifying the selector
		[self performSelector:@selector(updateModification) withObject:nil afterDelay:0.1];
	}
	return TRUE;
}


- (IBAction)onInvite:(id)event {
    [[[LinphoneManager instance] contactManager] inviteToRingMail:contact];
}

@end
