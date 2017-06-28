//
//  RKContactStore.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import "FMDatabase.h"
#import "FMDatabaseQueue.h"
#import "FMResultSet.h"
#import "Utils.h"

#import <AddressBook/AddressBook.h>
#import <Foundation/Foundation.h>

@interface RKContactStore : NSObject {

@private
	NSDateFormatter *dateFormatter;
    NSLocale *enUSPOSIXLocale;
}

@property (nonatomic, retain) FMDatabaseQueue *dbqueue;

+ (instancetype)sharedInstance;

- (void)setupDatabase;
- (void)setupTables;
- (void)updateMatches:(NSArray*)rgMatches;
- (BOOL)updateDetails:(NSArray*)rgUsers;
- (BOOL)isEnabled:(NSString*)addr;
- (NSDictionary*)getEnabledContacts;
- (NSString*)defaultPrimaryAddress:(ABRecordRef)lPerson;
- (NSString*)defaultPrimaryAddress:(ABRecordRef)lPerson current:(NSString*)cur;
- (NSString*)getPrimaryAddress:(NSNumber*)contactID;

@end
