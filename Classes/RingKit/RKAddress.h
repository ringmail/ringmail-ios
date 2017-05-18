//
//  RKAddress.h
//  ringmail
//
//  Created by Mike Frager on 5/18/17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, RKAddressType) {
	RKAddressTypeEmail,
	RKAddressTypePhone,
	RKAddressTypeDomain,
	RKAddressTypeHashtag
};

@class RKContact;

@interface RKAddress : NSObject

@property (nonatomic, strong) NSString* address;
@property (nonatomic, strong) NSString* displayName;
@property (nonatomic, strong) UIImage* avatarImage;
@property (nonatomic, weak) RKContact* contact;

+ (instancetype)newWithData:(NSDictionary*)param;
+ (BOOL)validEmailAddress:(NSString *)checkString;
+ (BOOL)validAddress:(NSString*)address;

- (RKAddressType)getAddressType;
- (BOOL)isEmail;
- (BOOL)isPhone;
- (BOOL)isDomain;
- (BOOL)isHashtag;
- (BOOL)isEqual:(RKAddress*)object;

@end
