/* FastAddressBook.h
 *
 * Copyright (C) 2011  Belledonne Comunications, Grenoble, France
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

#import "FastAddressBook.h"
#import "LinphoneManager.h"
#import "RgContactManager.h"
#import "NBPhoneNumberUtil.h"
#import "NBPhoneNumber.h"
#import "RegexKitLite/RegexKitLite.h"

@implementation FastAddressBook

static void sync_address_book(ABAddressBookRef addressBook, CFDictionaryRef info, void *context);

+ (NSString *)getContactDisplayName:(ABRecordRef)contact {
	NSString *retString = nil;
	if (contact) {
		retString = CFBridgingRelease(ABRecordCopyCompositeName(contact));
	}
	return retString;
}

+ (UIImage *)squareImageCrop:(UIImage *)image {
	UIImage *ret = nil;

	// This calculates the crop area.

	float originalWidth = image.size.width;
	float originalHeight = image.size.height;

	float edge = fminf(originalWidth, originalHeight);

	float posX = (originalWidth - edge) / 2.0f;
	float posY = (originalHeight - edge) / 2.0f;

	CGRect cropSquare = CGRectMake(posX, posY, edge, edge);

	CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropSquare);
	ret = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];

	CGImageRelease(imageRef);

	return ret;
}

+ (UIImage *)getContactImage:(ABRecordRef)contact thumbnail:(BOOL)thumbnail {
	UIImage *retImage = nil;
	if (contact && ABPersonHasImageData(contact)) {
		NSData *imgData = CFBridgingRelease(ABPersonCopyImageDataWithFormat(
			contact, thumbnail ? kABPersonImageFormatThumbnail : kABPersonImageFormatOriginalSize));

		retImage = [UIImage imageWithData:imgData];

		if (retImage != nil && retImage.size.width != retImage.size.height) {
			LOGI(@"Image is not square : cropping it.");
			return [self squareImageCrop:retImage];
		}
	}

	return retImage;
}

- (ABRecordRef)getContact:(NSString *)address {
	@synchronized(addressBookMap) {
		return (__bridge ABRecordRef)[addressBookMap objectForKey:address];
	}
}

- (ABRecordRef)getContactById:(NSNumber *)appleId {
	@synchronized(addressBookMap) {
		return ABAddressBookGetPersonWithRecordID(addressBook, [appleId intValue]);
	}
}

+ (BOOL)isSipURI:(NSString *)address {
	return [address hasPrefix:@"sip:"] || [address hasPrefix:@"sips:"];
}

+ (NSString *)appendCountryCodeIfPossible:(NSString *)number {
    return number;
	/*if (![number hasPrefix:@"+"] && ![number hasPrefix:@"00"]) {
		NSString *lCountryCode = [[LinphoneManager instance] lpConfigStringForKey:@"countrycode_preference"];
		if (lCountryCode && [lCountryCode length] > 0) {
			// append country code
			return [lCountryCode stringByAppendingString:number];
		}
	}
	return number;*/
}

+ (NSString *)normalizePhoneNumber:(NSString *)addr {
	addr = [addr stringByReplacingOccurrencesOfRegex:@"\\D" withString:@""];
	if ([addr length] == 0)
	{
		return @"";
	}
	NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
	NSError *anError = nil;
	NBPhoneNumber *myNumber = [phoneUtil parse:addr defaultRegion:@"US" error:&anError];
	NSString *res = addr;
	if (anError == nil)
	{
		if ([phoneUtil isValidNumber:myNumber])
		{
			res = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&anError];
		}
	}
	return res;
}

+ (BOOL)isAuthorized {
	return ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized;
}

- (FastAddressBook *)init {
	if ((self = [super init]) != nil) {
		addressBookMap = [NSMutableDictionary dictionary];
		addressBook = nil;
		[self reload];
	}
	return self;
}

- (void)saveAddressBook {
	if (addressBook != nil) {
		if (!ABAddressBookSave(addressBook, nil)) {
			LOGW(@"Couldn't save Address Book");
		}
	}
}

- (void)reload {
	CFErrorRef error;

	// create if it doesn't exist
	if (addressBook == nil) {
		addressBook = ABAddressBookCreateWithOptions(NULL, &error);
	}

	if (addressBook != nil) {
		__weak FastAddressBook *weakSelf = self;
		ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
		  if (!granted) {
			  LOGE(@"Permission for address book acces was denied: %@", [(__bridge NSError *)error description]);
			  return;
		  }

		  ABAddressBookRegisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(weakSelf));
		  [weakSelf loadData];

		});
	} else {
		LOGE(@"Create AddressBook failed, reason: %@", [(__bridge NSError *)error localizedDescription]);
	}
}

- (void)loadData {
	@synchronized(addressBookMap) {
        ABAddressBookRevert(addressBook);
		[addressBookMap removeAllObjects];

		CFArrayRef lContacts = ABAddressBookCopyArrayOfAllPeople(addressBook);
		CFIndex count = CFArrayGetCount(lContacts);
		for (CFIndex idx = 0; idx < count; idx++) {
			ABRecordRef lPerson = CFArrayGetValueAtIndex(lContacts, idx);
			// Phone
			{
				ABMultiValueRef lMap = ABRecordCopyValue(lPerson, kABPersonPhoneProperty);
				if (lMap) {
					for (int i = 0; i < ABMultiValueGetCount(lMap); i++) {
						CFStringRef lValue = ABMultiValueCopyValueAtIndex(lMap, i);

						NSString *lNormalizedKey = [FastAddressBook normalizePhoneNumber:(__bridge NSString *)(lValue)];

						[addressBookMap setObject:(__bridge id)(lPerson)forKey:lNormalizedKey];

						CFRelease(lValue);
					}
					CFRelease(lMap);
				}
			}

			// SIP
			/*{
				ABMultiValueRef lMap = ABRecordCopyValue(lPerson, kABPersonInstantMessageProperty);
				if (lMap) {
					for (int i = 0; i < ABMultiValueGetCount(lMap); ++i) {
						CFDictionaryRef lDict = ABMultiValueCopyValueAtIndex(lMap, i);
						BOOL add = false;
						if (CFDictionaryContainsKey(lDict, kABPersonInstantMessageServiceKey)) {
							if (CFStringCompare((CFStringRef)[LinphoneManager instance].contactSipField,
												CFDictionaryGetValue(lDict, kABPersonInstantMessageServiceKey),
												kCFCompareCaseInsensitive) == 0) {
								add = true;
							}
						} else {
							add = true;
						}
						if (add) {
							NSString *lValue =
								(__bridge NSString *)CFDictionaryGetValue(lDict, kABPersonInstantMessageUsernameKey);
								[addressBookMap setObject:(__bridge id)(lPerson)forKey:lValue];
							}
						}
						CFRelease(lDict);
					}
					CFRelease(lMap);
				}
			}*/
            
            // Email
            {
                ABMultiValueRef lMap = ABRecordCopyValue(lPerson, kABPersonEmailProperty);
                if (lMap) {
                    for (int i = 0; i < ABMultiValueGetCount(lMap); ++i) {
                        NSString *valueRef = CFBridgingRelease(ABMultiValueCopyValueAtIndex(lMap, i));
                        //NSLog(@"Add Email Key: %@", valueRef);
                        [addressBookMap setObject:(__bridge id)(lPerson)forKey:valueRef];
                    }
                    CFRelease(lMap);
                }
            }
		}
		CFRelease(lContacts);
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneAddressBookUpdate object:self];
}

void sync_address_book(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
    NSLog(@"FastAddressBook Change Detected");
    [[[LinphoneManager instance] contactManager] sendContactData];
	FastAddressBook *fastAddressBook = (__bridge FastAddressBook *)context;
	[fastAddressBook loadData];
}

- (void)dealloc {
	ABAddressBookUnregisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
	CFRelease(addressBook);
}

#pragma mark - Tools

+ (NSString *)localizedLabel:(NSString *)label {
	if (label != nil) {
		return CFBridgingRelease(ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)(label)));
	}
	return @"";
}

#pragma mark - RingMail

- (NSArray *)getContactsArray
{
	@synchronized(addressBookMap) {
        ABAddressBookRevert(addressBook);
		return (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
	}
}

- (NSArray *)getEmailArray:(ABRecordRef)lPerson
{
	@synchronized(addressBookMap) {
		NSMutableArray *res = [NSMutableArray array];
	    ABMultiValueRef emailMap = ABRecordCopyValue((ABRecordRef)lPerson, kABPersonEmailProperty);
        if (emailMap)
		{
            for(int i = 0; i < ABMultiValueGetCount(emailMap); ++i)
			{
                NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emailMap, i));
                if (val)
                {
					[res addObject:val];
                }
            }
            CFRelease(emailMap);
        }
		return res;
	}
}

- (NSArray *)getPhoneArray:(ABRecordRef)lPerson
{
	@synchronized(addressBookMap) {
		NSMutableArray *res = [NSMutableArray array];
	    ABMultiValueRef phoneMap = ABRecordCopyValue((ABRecordRef)lPerson, kABPersonPhoneProperty);
        if (phoneMap)
		{
            for(int i = 0; i < ABMultiValueGetCount(phoneMap); ++i)
			{
                NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneMap, i));
                if (val)
                {
					[res addObject:val];
                }
            }
            CFRelease(phoneMap);
        }
		return res;
	}
}

- (NSDate *)getModDate:(ABRecordRef)person
{
	@synchronized(addressBookMap) {
		return CFBridgingRelease(ABRecordCopyValue(person, kABPersonModificationDateProperty));
	}
}

- (NSMutableDictionary *)contactItem:(ABRecordRef)lPerson
{
    @synchronized(addressBookMap) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        ABMultiValueRef emailMap = ABRecordCopyValue((ABRecordRef)lPerson, kABPersonEmailProperty);
        NSMutableArray *emailArray = [NSMutableArray array];
        if (emailMap) {
            for(int i = 0; i < ABMultiValueGetCount(emailMap); ++i) {
                NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emailMap, i));
                if (val)
                {
                    val = [[val lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    val = [[NSString stringWithFormat:@"r!ng:%@", val] SHA256];
                    [emailArray addObject:val];
                }
            }
            CFRelease(emailMap);
        }
        ABMultiValueRef phoneMap = ABRecordCopyValue((ABRecordRef)lPerson, kABPersonPhoneProperty);
        NSMutableArray *phoneArray = [NSMutableArray array];
        NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
        if (phoneMap) {
            for(int i = 0; i < ABMultiValueGetCount(phoneMap); ++i) {
                NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneMap, i));
                if (val)
                {
                    NSError *anError = nil;
                    NBPhoneNumber *myNumber = [phoneUtil parse:val defaultRegion:@"US" error:&anError];
                    if (anError == nil && [phoneUtil isValidNumber:myNumber])
                    {
                        val = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&anError];
                        val = [[NSString stringWithFormat:@"r!ng:%@", val] SHA256];
                        [phoneArray addObject:val];
                    }
                }
            }
            CFRelease(phoneMap);
        }
        NSDate *modDate = CFBridgingRelease(ABRecordCopyValue((ABRecordRef)lPerson, kABPersonModificationDateProperty));
        NSString *modDateGMT = [dateFormatter stringFromDate:modDate];
        NSNumber *recordId = [NSNumber numberWithInteger:ABRecordGetRecordID((ABRecordRef)lPerson)];
        NSString *recordStr = [NSString stringWithFormat:@"%@", recordId];
        NSDictionary *contactBase = @{ @"em": emailArray, @"ph": phoneArray, @"ts": modDateGMT, @"id": recordStr };
        NSMutableDictionary *contact = [NSMutableDictionary dictionaryWithDictionary:contactBase];
        
        NSString *lFirstName = CFBridgingRelease(ABRecordCopyValue(lPerson, kABPersonFirstNameProperty));
    	NSString *lLocalizedFirstName = [FastAddressBook localizedLabel:lFirstName];
    	NSString *lLastName = CFBridgingRelease(ABRecordCopyValue(lPerson, kABPersonLastNameProperty));
    	NSString *lLocalizedLastName = [FastAddressBook localizedLabel:lLastName];
    	NSString *lOrganization = CFBridgingRelease(ABRecordCopyValue(lPerson, kABPersonOrganizationProperty));
    	NSString *lLocalizedlOrganization = [FastAddressBook localizedLabel:lOrganization];
        
        if (lLocalizedFirstName != nil)
        {
            [contact setObject:(NSString*)lLocalizedFirstName forKey:@"fn"];
        }
        if (lLocalizedLastName != nil)
        {
            [contact setObject:(NSString*)lLocalizedLastName forKey:@"ln"];
        }
        if (lLocalizedlOrganization != nil)
        {
            [contact setObject:(NSString*)lLocalizedlOrganization forKey:@"co"];
        }
        return contact;
    }
}

- (NSDictionary *)contactData:(ABRecordRef)lPerson
{
    @synchronized(addressBookMap) {
        ABMultiValueRef emailMap = ABRecordCopyValue((ABRecordRef)lPerson, kABPersonEmailProperty);
        NSMutableArray *emailArray = [NSMutableArray array];
        if (emailMap) {
            for(int i = 0; i < ABMultiValueGetCount(emailMap); ++i) {
                NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emailMap, i));
                if (val)
                {
                    val = [[val lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    [emailArray addObject:val];
                }
            }
            CFRelease(emailMap);
        }
        ABMultiValueRef phoneMap = ABRecordCopyValue((ABRecordRef)lPerson, kABPersonPhoneProperty);
        NSMutableArray *phoneArray = [NSMutableArray array];
        NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
        if (phoneMap) {
            for(int i = 0; i < ABMultiValueGetCount(phoneMap); ++i) {
                NSString* val = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phoneMap, i));
                if (val)
                {
                    NSError *anError = nil;
                    NBPhoneNumber *myNumber = [phoneUtil parse:val defaultRegion:@"US" error:&anError];
                    if (anError == nil && [phoneUtil isValidNumber:myNumber])
                    {
                        val = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&anError];
                        [phoneArray addObject:val];
                    }
                }
            }
            CFRelease(phoneMap);
        }
        NSNumber *recordId = [NSNumber numberWithInteger:ABRecordGetRecordID((ABRecordRef)lPerson)];
        NSString *recordStr = [NSString stringWithFormat:@"%@", recordId];
        NSDictionary *contactBase = @{ @"email": emailArray, @"phone": phoneArray, @"id": recordStr };
        NSMutableDictionary *contact = [NSMutableDictionary dictionaryWithDictionary:contactBase];
        
        NSString *lFirstName = CFBridgingRelease(ABRecordCopyValue(lPerson, kABPersonFirstNameProperty));
    	NSString *lLocalizedFirstName = [FastAddressBook localizedLabel:lFirstName];
    	NSString *lLastName = CFBridgingRelease(ABRecordCopyValue(lPerson, kABPersonLastNameProperty));
    	NSString *lLocalizedLastName = [FastAddressBook localizedLabel:lLastName];
    	NSString *lOrganization = CFBridgingRelease(ABRecordCopyValue(lPerson, kABPersonOrganizationProperty));
    	NSString *lLocalizedlOrganization = [FastAddressBook localizedLabel:lOrganization];
        
        if (lLocalizedFirstName != nil)
        {
            [contact setObject:(NSString*)lLocalizedFirstName forKey:@"first_name"];
        }
        if (lLocalizedLastName != nil)
        {
            [contact setObject:(NSString*)lLocalizedLastName forKey:@"last_name"];
        }
        if (lLocalizedlOrganization != nil)
        {
            [contact setObject:(NSString*)lLocalizedlOrganization forKey:@"company"];
        }
        return contact;
    }
}

- (NSNumber *)getContactId:(ABRecordRef)lPerson
{
    @synchronized(addressBookMap) {
		NSNumber *recordId = [NSNumber numberWithInteger:ABRecordGetRecordID((ABRecordRef)lPerson)];
		return recordId;
	}
}

@end
