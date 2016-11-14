//
//  IntentContactManager.h
//  ringmail
//
//  Created by Mark Baxter on 10/11/16.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Contacts/Contacts.h>
#import <AddressBook/AddressBook.h>
#import <Intents/Intents.h>

@interface IntentContactManager : NSObject {
    @public
    NSMutableArray *foundContacts;
    NSMutableArray *foundContactsID;
}

- (BOOL)findContact:(INPerson*)name;
- (BOOL)findABContactID:(INPerson*)name;
- (NSMutableArray*)getFoundContacts;
- (NSMutableArray*)getFoundContactsID;

@end
