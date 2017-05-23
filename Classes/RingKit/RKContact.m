//
//  RKContact.m
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "RKContact.h"
#import "RKAddress.h"
#import "LinphoneManager.h"

@implementation RKContact

@synthesize contactDetails;
@synthesize contactId;
@synthesize addressList;
@synthesize primaryAddress;

+ (instancetype)newWithData:(NSDictionary*)param
{
	RKContact *item = [[RKContact alloc] init];
	if (param[@"primaryAddress"])
	{
		NSAssert([param[@"primaryAddress"] isKindOfClass:[RKAddress class]], @"primaryAddress is not RKAddress object");
		item.primaryAddress = param[@"primaryAddress"];
	}
	else if ([param[@"addressList"] count] > 0)
	{
		NSAssert([param[@"addressList"][0] isKindOfClass:[RKAddress class]], @"addressList element is not RKAddress object");
		item.primaryAddress = item.addressList[0];
	}
	if (param[@"contactId"])
	{
		item.contactId = param[@"contactId"];
		[item readContactDetails];
	}
	else
	{
		item.contactId = nil;
	}
	BOOL foundPrimary = NO;
	item.addressList = [NSMutableArray array];
	if ([param[@"addressList"] count] == 0)
	{
		foundPrimary = YES;
	}
	for (id i in param[@"addressList"])
	{
		NSAssert([i isKindOfClass:[RKAddress class]], @"addressList element is not RKAddress object");
		if (item.contactId)
		{
			[item applyDetails:i];
		}
		[item.addressList addObject:i];
		if (i == item.primaryAddress)
		{
			foundPrimary = YES;
		}
	}
	NSAssert(foundPrimary, @"primaryAddress is not a member of addressList");
	return item;
}

+ (instancetype)newWithContactId:(NSNumber*)ct
{
	return [RKContact newWithData:@{
		@"contactId": ct,
	}];
}

+ (instancetype)newByMatchingAddress:(RKAddress*)address
{
	NSMutableDictionary *param = [NSMutableDictionary dictionary];
	param[@"addressList"] = @[address];
	RKAddressType addressType = [address getAddressType];
	if (
		addressType == RKAddressTypeEmail ||
		addressType == RKAddressTypePhone
	) {
		
    	ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address.address];
    	if (contact)
    	{
    		NSNumber *contactId = [[[LinphoneManager instance] fastAddressBook] getContactId:contact];
    		param[@"contactId"] = contactId;
    	}
	}
	return [RKContact newWithData:param];
}

- (void)readContactDetails
{
	NSAssert(contactId, @"No internal contact for object");
	FastAddressBook *addressBook = [[LinphoneManager instance] fastAddressBook];
	NSMutableDictionary *details = [NSMutableDictionary dictionary];
	ABRecordRef contact = [addressBook getContactById:contactId];
	NSAssert(contact, @"Invalid contact id: %@", contactId);
    details[@"displayName"] = [FastAddressBook getContactDisplayName:contact];
    UIImage* avatar = [FastAddressBook getContactImage:contact thumbnail:YES];
	if (avatar)
	{
		details[@"avatarImage"] = avatar;
	}
	self.contactDetails = details;
}

- (void)applyDetails:(RKAddress*)address
{
	[address setContact:self];
	[address setDisplayName:contactDetails[@"displayName"]];
	if (contactDetails[@"avatarImage"])
	{
		[address setAvatarImage:contactDetails[@"avatarImage"]];
	}
	else
	{
		[address setAvatarImage:nil];
	}
}

- (void)addAddress:(RKAddress*)address
{
	NSAssert([address isKindOfClass:[RKAddress class]], @"Not an RKAddress object");
	if (contactId)
	{
		[self applyDetails:address];
	}
	[addressList addObject:address];
}

- (void)setPrimaryAddress:(RKAddress*)address
{
	BOOL foundPrimary = NO;
	for (id i in addressList)
	{
		if (i == address)
		{
			foundPrimary = YES;
		}
	}
	NSAssert(foundPrimary, @"primaryAddress is not a member of addressList");
	primaryAddress = address;
}

@end
