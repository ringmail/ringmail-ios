//
//  RgOptionsModalViewController.h
//  ringmail
//
//  Created by Mark Baxter on 5/3/17.
//
//

#import <UIKit/UIKit.h>

@interface RgOptionsModalViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIButton* contactButton;
@property (nonatomic, strong) IBOutlet UIImageView* avatarImg;
@property (nonatomic, strong) IBOutlet UILabel* nameLabel;
@property (nonatomic, strong) IBOutlet UILabel* numberLabel;

-(IBAction) onContact:(id)event;
-(IBAction) onText:(id)event;
-(IBAction) onCall:(id)event;
-(IBAction) onVideoChat:(id)event;
-(IBAction) onCancel:(id)event;

@end
