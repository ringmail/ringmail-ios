//
//  UIContactDetailsOptions.h
//  ringmail
//
//  Created by Mark Baxter on 5/24/17.
//
//

#import <UIKit/UIKit.h>

@interface UIContactDetailsOptions : UIViewController

@property (nonatomic, strong) IBOutlet UIButton *inviteButton;
@property (nonatomic, strong) IBOutlet UIButton *shareContactButton;
@property (nonatomic, strong) IBOutlet UIButton *shareLocationButton;

- (IBAction)onActionInvite:(id)event;
- (IBAction)onActionShareContact:(id)event;
- (IBAction)onActionShareLocation:(id)event;

+ (CGFloat)height;

@end
