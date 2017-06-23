#import <UIKit/UIKit.h>
#import "TPMultiLayoutViewController.h"
#import "RingKit.h"

extern NSString *const kChatNavBarUpdate;

@interface UIChatNavBar : TPMultiLayoutViewController

@property (nonatomic, strong) IBOutlet UIImageView* background;
@property (nonatomic, strong) IBOutlet UIImageView* avatarImage;
@property (nonatomic, strong) IBOutlet UIButton* backButton;
@property (nonatomic, strong) IBOutlet UILabel* headerLabel;
@property (nonatomic, strong) RKThread* chatThread;

- (void)updateHeader:(NSNotification *)notification;

- (IBAction)onActionClick:(id)event;
- (IBAction)onBackClick:(id)event;

@end
