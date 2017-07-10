//
//  SendContactsTableViewController.m
//  ringmail
//
//  Created by Mark Baxter on 6/21/17.
//
//

#import "SendContactsTableViewController.h"

#import "UIContactCell.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UACellBackgroundView.h"
#import "Utils.h"
#import "RgContactManager.h"
#import "RKContactStore.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "UIColor+Hex.h"


@implementation SendContactsTableViewController

static void sync_address_book(ABAddressBookRef addressBook, CFDictionaryRef info, void *context);

@synthesize delegate;
@synthesize selectionMode;

#pragma mark - Lifecycle Functions

- (void)initContactsTableViewController {
    addressBookMap = [[OrderedDictionary alloc] init];
    avatarMap = [[NSMutableDictionary alloc] init];
    ringMailContacts = [NSDictionary dictionary];
    
    selectedContacts = [[NSMutableArray alloc] init];
    
    addressBook = ABAddressBookCreateWithOptions(nil, nil);
    
    ABAddressBookRegisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
}

- (id)init {
    self = [super init];
    if (self) {
        [self initContactsTableViewController];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        [self initContactsTableViewController];
    }
    return self;
}

- (void)dealloc {
    ABAddressBookUnregisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
    CFRelease(addressBook);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectMulti:) name:kRgSendContactSelectDone object:nil];
}

- (void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSendContactSelectDone object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -

- (void)loadData {
    LOGI(@"Load contact list");
    @synchronized(addressBookMap) {
        
        // Reset Address book
        [addressBookMap removeAllObjects];
        
        // Read RingMail Contacts
        ringMailContacts = [[RKContactStore sharedInstance] getEnabledContacts];
        //NSLog(@"RingMail Enabled Contact IDs: %@", ringMailContacts);
        
        NSArray *lContacts = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
        for (id lPerson in lContacts)
		{
            ABRecordRef person = (__bridge ABRecordRef)lPerson;

            NSString *lFirstName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
            NSString *lLocalizedFirstName = [FastAddressBook localizedLabel:lFirstName];
            NSString *lLastName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
            NSString *lLocalizedLastName = [FastAddressBook localizedLabel:lLastName];
            NSString *lOrganization = CFBridgingRelease(ABRecordCopyValue(person, kABPersonOrganizationProperty));
            NSString *lLocalizedlOrganization = [FastAddressBook localizedLabel:lOrganization];
            
            NSString *name = nil;
            if (lLocalizedFirstName.length && lLocalizedLastName.length) {
                name = [NSString stringWithFormat:@"%@ %@", lLocalizedFirstName, lLocalizedLastName];
            } else if (lLocalizedLastName.length) {
                name = [NSString stringWithFormat:@"%@", lLocalizedLastName];
            } else if (lLocalizedFirstName.length) {
                name = [NSString stringWithFormat:@"%@", lLocalizedFirstName];
            } else if (lLocalizedlOrganization.length) {
                name = [NSString stringWithFormat:@"%@", lLocalizedlOrganization];
            }
            
            if (name != nil && [name length] > 0)
			{
                // Sort contacts by first letter. We need to translate the name to ASCII first, because of UTF-8
                // issues. For instance
                // we expect order:  Alberta(A tilde) before ASylvano.
                NSData *name2ASCIIdata =
                [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
                NSString *name2ASCII =
                [[NSString alloc] initWithData:name2ASCIIdata encoding:NSASCIIStringEncoding];
                NSString *firstChar = [[name2ASCII substringToIndex:1] uppercaseString];
                
                // Put in correct subDic
                if ([firstChar characterAtIndex:0] < 'A' || [firstChar characterAtIndex:0] > 'Z')
				{
                    firstChar = @"#";
                }
                
                NSNumber *recordId = [NSNumber numberWithInteger:ABRecordGetRecordID(person)];
                if ([ringMailContacts objectForKey:[recordId stringValue]])
                {
                    OrderedDictionary *subDic = [addressBookMap objectForKey:firstChar];
                    if (subDic == nil)
					{
                        subDic = [[OrderedDictionary alloc] init];
                        [addressBookMap insertObject:subDic forKey:firstChar selector:@selector(caseInsensitiveCompare:)];
                    }
                    [subDic insertObject:lPerson forKey:name2ASCII selector:@selector(caseInsensitiveCompare:)];
                }
            }
        }
    }
    [self.tableView reloadData];
}

static void sync_address_book(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    //NSLog(@"ContactsTableViewController Change Detected");
    SendContactsTableViewController *controller = (__bridge SendContactsTableViewController *)context;
    ABAddressBookRevert(addressBook);
    [controller->avatarMap removeAllObjects];
    [controller loadData];
}

#pragma mark - UITableViewDataSource Functions

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [addressBookMap allKeys];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [addressBookMap count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [(OrderedDictionary *)[addressBookMap objectForKey:[addressBookMap keyAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellId = @"UIContactCell";
    UIContactCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
    if (cell == nil) {
        cell = [[UIContactCell alloc] initWithIdentifier:kCellId];
        
        // Background View
        UACellBackgroundView *selectedBackgroundView = [[UACellBackgroundView alloc] initWithFrame:CGRectZero];
        cell.selectedBackgroundView = selectedBackgroundView;
        [selectedBackgroundView setBackgroundColor:LINPHONE_TABLE_CELL_BACKGROUND_COLOR];  // mrkbxt
    }
    OrderedDictionary *subDic = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
    
    NSString *key = [[subDic allKeys] objectAtIndex:[indexPath row]];
    ABRecordRef contact = (__bridge ABRecordRef)([subDic objectForKey:key]);
    
    // Cached avatar
    UIImage *image = nil;
    id data = [avatarMap objectForKey:[NSNumber numberWithInt:ABRecordGetRecordID(contact)]];
    if (data == nil) {
        image = [FastAddressBook getContactImage:contact thumbnail:false];
        image = [image thumbnailImage:64 transparentBorder:0 cornerRadius:32 interpolationQuality:kCGInterpolationHigh];
        if (image != nil) {
            [avatarMap setObject:image forKey:[NSNumber numberWithInt:ABRecordGetRecordID(contact)]];
        } else {
            [avatarMap setObject:[NSNull null] forKey:[NSNumber numberWithInt:ABRecordGetRecordID(contact)]];
        }
    } else if (data != [NSNull null]) {
        image = data;
    }
    if (image == nil) {
        image = [UIImage imageNamed:@"avatar_unknown_small.png"];
        image = [image thumbnailImage:64 transparentBorder:0 cornerRadius:32 interpolationQuality:kCGInterpolationHigh];
        // future: cache the default image
    }
    [[cell avatarImage] setImage:image];
    
    [[cell inviteButton] setHidden:YES];  // mrkbxt
    cell.sendContactsTVC=TRUE;
    
    NSNumber *recordId = [NSNumber numberWithInteger:ABRecordGetRecordID(contact)];
    if ([ringMailContacts objectForKey:[recordId stringValue]])
    {
        //NSLog(@"Found Contact: %@", recordId);
        //		[[cell inviteButton] setHidden:YES];
        [[cell rgImage] setHidden:NO];
    }
    else
    {
        //		[[cell inviteButton] setHidden:NO];
        [[cell rgImage] setHidden:YES];
    }
    
    [cell setContact:contact];
    
    
    if([selectedContacts containsObject:indexPath])
    {
        cell.tempSelected = YES;
        [[cell selectImage] setHidden:NO];
    } else {
        cell.tempSelected = NO;
        [[cell selectImage] setHidden:YES];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [addressBookMap keyAtIndex:section];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIContactCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OrderedDictionary *subDic = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
    ABRecordRef lPerson = (__bridge ABRecordRef)([subDic objectForKey:[subDic keyAtIndex:[indexPath row]]]);
	
	// TODO: change to get primary RingMail address
    NSArray* emails = [[[LinphoneManager instance] fastAddressBook] getEmailArray:lPerson];
    
    cell.sendContactsTVC=TRUE;
    
    if (selectionMode == SendContactSelectionModeSingle)
	{
		if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectSingleContact:)])
    	{
			[delegate didSelectSingleContact:emails[0]];
    	}
        [[PhoneMainView instance] popCurrentView];
    }
    else
	{
        if (cell.isTempSelected)
		{
            [selectedContacts removeObject:indexPath];
            [[cell selectImage] setHidden:YES];
            cell.tempSelected = NO;
        }
        else
		{
            [selectedContacts addObject:indexPath];
            [[cell selectImage] setHidden:NO];
            cell.tempSelected = YES;
        }
    }
}

#pragma mark - UITableViewDelegate Functions

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 26.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 26)];
    [view setBackgroundColor:[UIColor colorWithHex:@"#FFFFFF"]];
    
    UIImageView * imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background_contacts_header.png"]];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [view addSubview:imageView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 4, 30, 20)];
    [label setFont:[UIFont fontWithName:@"SFUIText-Bold" size:20]];
    [label setTextColor:[UIColor colorWithHex:@"#222222"]];
    
    NSString *string = [self tableView:tableView titleForHeaderInSection:section];
    
    [label setText:string];
    [view addSubview:label];
    return view;
}


#pragma mark -

- (void)selectMulti:(NSNotification*)notif
{
    NSMutableArray* contacts = [[NSMutableArray alloc] init];
    for (NSIndexPath* indexPath in selectedContacts)
	{
        OrderedDictionary *subDic = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
        ABRecordRef lPerson = (__bridge ABRecordRef)([subDic objectForKey:[subDic keyAtIndex:[indexPath row]]]);
        NSArray* emails = [[[LinphoneManager instance] fastAddressBook] getEmailArray:lPerson];
        if ([emails count])
		{
            [contacts addObject:emails[0]];
		}
    }
	if ([contacts count] > 0)
	{
    	if (self.delegate && [delegate respondsToSelector:@selector(didSelectMultipleContacts:)])
    	{
    		[delegate didSelectMultipleContacts:contacts];
    	}
	}
}

@end
