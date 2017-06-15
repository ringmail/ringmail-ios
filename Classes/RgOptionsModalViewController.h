//
//  RgOptionsModalViewController.h
//  ringmail
//
//  Created by Mark Baxter on 5/3/17.
//
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@interface RgOptionsModalViewController : UIViewController

@property (nonatomic, copy) NSDictionary* modalData;

@property (nonatomic, strong) IBOutlet UIView* contactView;
@property (nonatomic, strong) IBOutlet UIView* invalidView;

@property (nonatomic, strong) IBOutlet UIButton* contactButton;
@property (nonatomic, strong) IBOutlet UIImageView* avatarImg;
@property (nonatomic, strong) IBOutlet UILabel* nameLabel;
@property (nonatomic, strong) IBOutlet UILabel* numberLabel;
@property (nonatomic, strong) IBOutlet UILabel* contactLabel;
@property (nonatomic, strong) IBOutlet NSNumber* contactNew;

- (id)initWithData:(NSDictionary*)param;
- (IBAction)onContact:(id)event;
- (IBAction)onText:(id)event;
- (IBAction)onCall:(id)event;
- (IBAction)onVideoChat:(id)event;
- (IBAction)onCancel:(id)event;

@end
