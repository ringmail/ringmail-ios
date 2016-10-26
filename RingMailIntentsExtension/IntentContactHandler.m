//
//  IntentContactManager.m
//  ringmail
//
//  Created by Mark Baxter on 10/11/16.
//
//

#import "IntentContactManager.h"

@implementation IntentContactManager


- (void)initIntentContactManager {
    foundContacts = [[NSMutableArray alloc] init];
    foundContactsID = [[NSMutableArray alloc] init];
}

- (id)init {
    self = [super init];
    if (self) {
        [self initIntentContactManager];
    }
    return self;
}

-(NSMutableArray*)getFoundContacts {
    return foundContacts;
}

-(NSMutableArray*)getFoundContactsID {
    return foundContactsID;
}

-(BOOL)findContact:(INPerson*)name
{
    __block BOOL found = FALSE;
    
    if([CNContactStore class]) {

        CNContactStore* addressBook = [[CNContactStore alloc]init];
        NSArray *keys = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPhoneNumbersKey, CNContactImageDataKey];
        NSPredicate *predicate = [CNContact predicateForContactsMatchingName:name.nameComponents.givenName];

        NSError *error;
        NSArray *cnContacts = [addressBook unifiedContactsMatchingPredicate:predicate keysToFetch:keys error:&error];
        if (error) {
            NSLog(@"error fetching contacts %@", error);
        } else {
            for (CNContact *contact in cnContacts) {
                NSComparisonResult resultGivenName = [contact.givenName caseInsensitiveCompare:name.nameComponents.givenName];
                NSComparisonResult resultFamilyName = [contact.familyName caseInsensitiveCompare:name.nameComponents.familyName];
                if (resultGivenName == NSOrderedSame && resultFamilyName == NSOrderedSame) {
                    [foundContacts addObject:contact];
                    found = TRUE;
                }
            }
        }
    }
    return found;
}

- (BOOL)findABContactID:(INPerson*)name
{
    NSString *fname = name.nameComponents.givenName;
    NSString *lname = name.nameComponents.familyName;
    
    ABAddressBookRef addressBook = ABAddressBookCreate();
    NSArray *searchResults = CFBridgingRelease(ABAddressBookCopyPeopleWithName(addressBook, (__bridge CFStringRef)fname));
    
    NSInteger numberOfPeople = [searchResults count];
    
    __block BOOL found = FALSE;
    
    for (NSInteger i = 0; i < numberOfPeople; i++) {
        ABRecordRef contact = (__bridge ABRecordRef)searchResults[i];
        
        NSNumber* contactNum = [NSNumber numberWithInteger:ABRecordGetRecordID((ABRecordRef)contact)];
        
        NSString *firstName = CFBridgingRelease(ABRecordCopyValue(contact, kABPersonFirstNameProperty));
        NSString *lastName  = CFBridgingRelease(ABRecordCopyValue(contact, kABPersonLastNameProperty));
        
        NSComparisonResult resultGivenName = [firstName caseInsensitiveCompare:fname];
        NSComparisonResult resultFamilyName = [lastName caseInsensitiveCompare:lname];
        
        if (resultGivenName == NSOrderedSame && resultFamilyName == NSOrderedSame){
            NSString *tempID = [contactNum stringValue];
            [foundContactsID addObject:tempID];
            found = TRUE;
        }
    }
    return found;
}

@end
