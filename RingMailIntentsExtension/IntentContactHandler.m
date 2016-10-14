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

-(BOOL)findContact:(INPerson*)name
{
    __block BOOL found = FALSE;
    
    if([CNContactStore class]) {
        NSError* contactError;
        CNContactStore* addressBook = [[CNContactStore alloc]init];
        [addressBook containersMatchingPredicate:[CNContainer predicateForContainersWithIdentifiers: @[addressBook.defaultContainerIdentifier]] error:&contactError];
        NSArray * keysToFetch =@[CNContactEmailAddressesKey, CNContactPhoneNumbersKey, CNContactFamilyNameKey, CNContactGivenNameKey, CNContactPostalAddressesKey];
        CNContactFetchRequest * request = [[CNContactFetchRequest alloc]initWithKeysToFetch:keysToFetch];
        
        [addressBook enumerateContactsWithFetchRequest:request error:&contactError usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop){
            NSComparisonResult resultDisplayName = [contact.givenName caseInsensitiveCompare:name.displayName];
            
            if (resultDisplayName == NSOrderedSame) {
                [foundContacts addObject:contact];
                found = TRUE;
            }
        }];
    }
    return found;
}

@end
