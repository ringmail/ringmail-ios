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
#import <Intents/Intents.h>

@interface IntentContactManager : NSObject {
    @public
    NSMutableArray *foundContacts;
}

- (BOOL)findContact:(INPerson*)name;
- (NSMutableArray*)getFoundContacts;

@end
