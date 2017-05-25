/* MessagesViewController.h
 */

#import <UIKit/UIKit.h>

#import "UICompositeViewController.h"
#import "MessageListViewController.h"

#import "UICallButton.h"
#import "UIMessageButton.h"
#import "UIDigitButton.h"

@interface MessagesViewController : UIViewController <UICompositeViewDelegate> {
}

@property (nonatomic, strong) IBOutlet UIView* mainView;
@property (nonatomic, retain) MessageListViewController* mainViewController;
@property (nonatomic, retain) IBOutlet UIImageView* backgroundImageView;
@property (nonatomic, assign) BOOL needsRefresh;
@property (nonatomic, assign) BOOL visible;

@end
