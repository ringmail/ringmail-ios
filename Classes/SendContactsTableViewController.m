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

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"
#import "UIColor+Hex.h"


@implementation SendContactsTableViewController

static void sync_address_book(ABAddressBookRef addressBook, CFDictionaryRef info, void *context);

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
        ringMailContacts = [[[LinphoneManager instance] contactManager] dbGetRgContacts];
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
        [selectedBackgroundView setBackgroundColor:[UIColor colorWithHex:@"#D3D3D3"]];  // mrkbxt
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
    
//    // mrkbxt
//    if([selectedContacts containsObject:indexPath]) {
//        //        cell.accessoryType = UITableViewCellAccessoryCheckmark;
//    } else {
//        //        cell.accessoryType = UITableViewCellAccessoryNone;
//    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [addressBookMap keyAtIndex:section];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

//    NSNumber* contactId = [[[LinphoneManager instance] fastAddressBook] getContactId:lPerson];

    if(cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
//        [selectedContacts addObject:indexPath]; 
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
//        [selectedContacts removeObject:indexPath];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OrderedDictionary *subDic = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
    ABRecordRef lPerson = (__bridge ABRecordRef)([subDic objectForKey:[subDic keyAtIndex:[indexPath row]]]);
    
    NSMutableDictionary* contact = [[[LinphoneManager instance] fastAddressBook] contactItem:lPerson];
    NSArray* emails = [[[LinphoneManager instance] fastAddressBook] getEmailArray:lPerson];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kRgSendComponentSelectContact object:nil userInfo:@{
       @"contact": contact, @"emails": emails
    }];
    
    [[PhoneMainView instance] popCurrentView];
}

#pragma mark - UITableViewDelegate Functions

-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor colorWithHex:@"#222222"]];
    [header.textLabel setFont:[UIFont fontWithName:@"SFUIText-Bold" size:20]];
    header.contentView.backgroundColor = [UIColor colorWithHex:@"#FFFFFF"];
    UIImageView * imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background_contacts_header.png"]];
    [header.contentView addSubview:imageView];
}

@end
