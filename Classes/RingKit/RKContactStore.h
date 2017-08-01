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
	FMDatabase *database;
}

@property (nonatomic, retain) FMDatabaseQueue *dbqueue;

+ (instancetype)sharedInstance;

- (void)setupDatabase;
- (void)setupTables;
- (void)updateMatches:(NSArray*)rgMatches;
- (BOOL)updateDetails:(NSArray*)rgUsers;
- (BOOL)isEnabled:(NSString*)addr;
- (BOOL)contactEnabled:(NSString*)contactID;
- (NSDictionary*)getEnabledContacts;
- (NSString*)defaultPrimaryAddress:(ABRecordRef)lPerson;
- (NSString*)defaultPrimaryAddress:(ABRecordRef)lPerson current:(NSString*)cur;
- (NSString*)getPrimaryAddress:(NSString*)contactID;

- (BOOL)isFavorite:(NSString*)contactID;
- (void)addFavorite:(NSString*)contactID;
- (void)removeFavorite:(NSString*)contactID;
- (NSDictionary*)getFavorites;
- (void)updateFavorites;

@end
