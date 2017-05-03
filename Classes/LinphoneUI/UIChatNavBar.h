#import <UIKit/UIKit.h>
#import "TPMultiLayoutViewController.h"

@interface UIChatNavBar : TPMultiLayoutViewController

@property (nonatomic, strong) IBOutlet UIImageView* background;
@property (nonatomic, strong) IBOutlet UIImageView* avatarImage;
@property (nonatomic, strong) IBOutlet UIButton* backButton;
@property (nonatomic, strong) IBOutlet UILabel* headerLabel;


- (IBAction)onBackClick:(id) event;

- (void)setInstance:(int)widthIn;
- (void)updateLabelsBtns:(NSNotification *) notification;

@end
