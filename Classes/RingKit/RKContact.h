//
//  RKContact.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

@class RKAddress;

@interface RKContact : NSObject

@property (nonatomic, strong) NSNumber* contactId;
@property (nonatomic, strong) NSMutableDictionary* contactDetails;
@property (nonatomic, strong) NSMutableArray* addressList;
@property (nonatomic, strong) RKAddress* primaryAddress;

+ (instancetype)newWithContactId:(NSNumber*)ct;
+ (instancetype)newWithData:(NSDictionary*)param;
+ (instancetype)newByMatchingAddress:(RKAddress*)address;

- (void)readContactDetails;
- (void)applyDetails:(RKAddress*)address;
- (void)addAddress:(RKAddress*)address;
- (void)setPrimaryAddress:(RKAddress*)address;

@end
