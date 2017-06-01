/* MessagesViewController.h
 */

#import <UIKit/UIKit.h>

#import "UICompositeViewController.h"
#import "MessageListViewController.h"

@interface MessagesViewController : UIViewController <UICompositeViewDelegate> {
}

@property (nonatomic, strong) IBOutlet UIView* mainView;
@property (nonatomic, retain) IBOutlet UIImageView* backgroundImageView;
@property (nonatomic, retain) MessageListViewController* mainViewController;

@end
