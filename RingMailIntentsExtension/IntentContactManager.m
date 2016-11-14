//
//  IntentContactManager.m
//  ringmail
//
//  Created by Mark Baxter on 10/11/16.
//
//

#import "IntentContactManager.h"

@implementation IntentContactManager

@synthesize contact;

- (void)initIntentContactManager {
    addressBookMap = [[OrderedDictionary alloc] init];
    ringMailContacts = [NSDictionary dictionary];
    addressBook = ABAddressBookCreateWithOptions(nil, nil);
//    avatarMap = [[NSMutableDictionary alloc] init];
//    ABAddressBookRegisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
}

- (id)init {
    self = [super init];
    if (self) {
        [self initIntentContactManager];
    }
    return self;
}

//- (id)initWithCoder:(NSCoder *)decoder {
//    self = [super initWithCoder:decoder];
//    if (self) {
//        [self initIntentContactManager];
//    }
//    return self;
//}

static int ms_strcmpfuz(const char *fuzzy_word, const char *sentence) {
    if (!fuzzy_word || !sentence) {
        return fuzzy_word == sentence;
    }
    const char *c = fuzzy_word;
    const char *within_sentence = sentence;
    for (; c != NULL && *c != '\0' && within_sentence != NULL; ++c) {
        within_sentence = strchr(within_sentence, *c);
        // Could not find c character in sentence. Abort.
        if (within_sentence == NULL) {
            break;
        }
        // since strchr returns the index of the matched char, move forward
        within_sentence++;
    }
    
    // If the whole fuzzy was found, returns 0. Otherwise returns number of characters left.
    return (int)(within_sentence != NULL ? 0 : fuzzy_word + strlen(fuzzy_word) - c);
}

- (BOOL)contactHasValidSipDomain:(ABRecordRef)person {
    // Check if one of the contact' sip URI matches the expected SIP filter
    ABMultiValueRef personSipAddresses = ABRecordCopyValue(person, kABPersonInstantMessageProperty);
    BOOL match = false;
    NSString *filter = [ContactSelection getSipFilter];
    
    for (int i = 0; i < ABMultiValueGetCount(personSipAddresses) && !match; ++i) {
        CFDictionaryRef lDict = ABMultiValueCopyValueAtIndex(personSipAddresses, i);
        if (CFDictionaryContainsKey(lDict, kABPersonInstantMessageServiceKey)) {
            CFStringRef serviceKey = CFDictionaryGetValue(lDict, kABPersonInstantMessageServiceKey);
            
            if (CFStringCompare((CFStringRef)[LinphoneManager instance].contactSipField, serviceKey,
                                kCFCompareCaseInsensitive) == 0) {
                match = true;
            }
        } else {
            // check domain
            LinphoneAddress *address = linphone_address_new(
                                                            [(NSString *)CFDictionaryGetValue(lDict, kABPersonInstantMessageUsernameKey) UTF8String]);
            
            if (address) {
                const char *dom = linphone_address_get_domain(address);
                if (dom != NULL) {
                    NSString *domain = [NSString stringWithCString:dom encoding:[NSString defaultCStringEncoding]];
                    
                    if (([filter compare:@"*" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
                        ([filter compare:domain options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
                        match = true;
                    }
                }
                linphone_address_destroy(address);
            }
        }
        CFRelease(lDict);
    }
    CFRelease(personSipAddresses);
    return match;
}


- (void)loadData {
    LOGI(@"Load contact list");
    @synchronized(addressBookMap) {
        
        // Reset Address book
        [addressBookMap removeAllObjects];
        
        // Read RingMail Contacts
        ringMailContacts = [[[LinphoneManager instance] contactManager] dbGetRgContacts];
        //NSLog(@"RingMail Enabled Contact IDs: %@", ringMailContacts);
        
        NSArray *lContacts = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
        for (id lPerson in lContacts) {
            BOOL add = true;
            ABRecordRef person = (__bridge ABRecordRef)lPerson;
            
            // Do not add the contact directly if we set some filter
            if ([ContactSelection getSipFilter] || [ContactSelection emailFilterEnabled]) {
                add = false;
            }
            if ([ContactSelection getSipFilter] && [self contactHasValidSipDomain:person]) {
                add = true;
            }
            if (!add && [ContactSelection emailFilterEnabled]) {
                ABMultiValueRef personEmailAddresses = ABRecordCopyValue(person, kABPersonEmailProperty);
                // Add this contact if it has an email
                add = (ABMultiValueGetCount(personEmailAddresses) > 0);
                
                CFRelease(personEmailAddresses);
            }

            if (add) {
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
                
                if (name != nil && [name length] > 0) {
                    // Add the contact only if it fuzzy match filter too (if any)
                    if ([ContactSelection getNameOrEmailFilter] == nil ||
                        (ms_strcmpfuz([[[ContactSelection getNameOrEmailFilter] lowercaseString] UTF8String],
                                      [[name lowercaseString] UTF8String]) == 0)) {
                        
                        // Sort contacts by first letter. We need to translate the name to ASCII first, because of UTF-8
                        // issues. For instance
                        // we expect order:  Alberta(A tilde) before ASylvano.
                        NSData *name2ASCIIdata =
                        [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
                        NSString *name2ASCII =
                        [[NSString alloc] initWithData:name2ASCIIdata encoding:NSASCIIStringEncoding];
                        NSString *firstChar = [[name2ASCII substringToIndex:1] uppercaseString];
                        
                        // Put in correct subDic
                        if ([firstChar characterAtIndex:0] < 'A' || [firstChar characterAtIndex:0] > 'Z') {
                            firstChar = @"#";
                        }
                        OrderedDictionary *subDic = [addressBookMap objectForKey:firstChar];
                        if (subDic == nil) {
                            subDic = [[OrderedDictionary alloc] init];
                            [addressBookMap insertObject:subDic
                                                  forKey:firstChar
                                                selector:@selector(caseInsensitiveCompare:)];
                        }
                        [subDic insertObject:lPerson forKey:name2ASCII selector:@selector(caseInsensitiveCompare:)];
                    }
                }
            }
        }
    }
//    [self.tableView reloadData];
}

- (void)update {
//    if (contact == NULL) {
//        LOGW(@"Cannot update contact cell: null contact");
//        return;
//    }
    
    NSString *lFirstName = CFBridgingRelease(ABRecordCopyValue(contact, kABPersonFirstNameProperty));
    NSString *lLocalizedFirstName = [FastAddressBook localizedLabel:lFirstName];
    
    NSString *lLastName = CFBridgingRelease(ABRecordCopyValue(contact, kABPersonLastNameProperty));
    NSString *lLocalizedLastName = [FastAddressBook localizedLabel:lLastName];
    
    NSString *lOrganization = CFBridgingRelease(ABRecordCopyValue(contact, kABPersonOrganizationProperty));
    NSString *lLocalizedOrganization = [FastAddressBook localizedLabel:lOrganization];
    
    NSLog(@"CONTACT: FIRST NAME: %@",lFirstName);
    
//    [firstNameLabel setText:lLocalizedFirstName];
//    [lastNameLabel setText:lLocalizedLastName];
//    
//    if (
//        (lLocalizedFirstName == nil && lLocalizedLastName == nil) ||
//        ([lLocalizedFirstName isEqualToString:@""] && [lLocalizedLastName isEqualToString:@""])
//        ) {
//        [firstNameLabel setText:(NSString *)(lLocalizedOrganization)];
//    }
}

@end

//OrderedDictionary *subDic = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
//
//NSString *key = [[subDic allKeys] objectAtIndex:[indexPath row]];
//ABRecordRef contact = (__bridge ABRecordRef)([subDic objectForKey:key]);
