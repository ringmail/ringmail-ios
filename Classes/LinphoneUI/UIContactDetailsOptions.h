//
//  UIContactDetailsOptions.h
//  ringmail
//
//  Created by Mark Baxter on 5/24/17.
//
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@interface UIContactDetailsOptions : UIViewController

@property (nonatomic, strong) IBOutlet UIButton *inviteButton;
@property (nonatomic, strong) IBOutlet UIButton *shareContactButton;
@property (nonatomic, strong) IBOutlet UIButton *shareLocationButton;
@property (nonatomic, strong) IBOutlet UIButton *favoriteButton;

@property (nonatomic, assign) ABRecordRef contact;
@property (nonatomic) BOOL rgMember;
@property (nonatomic) BOOL disableUserFeatures;
@property (nonatomic) NSString* contactID;

- (IBAction)onActionInvite:(id)event;
- (IBAction)onActionShareContact:(id)event;
- (IBAction)onActionShareLocation:(id)event;
- (IBAction)onActionFavorite:(id)event;

+ (CGFloat)height;

@end
