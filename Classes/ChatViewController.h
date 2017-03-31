/* ChatViewController.h
 */

#import <UIKit/UIKit.h>

#import "UICompositeViewController.h"
#import "ChatRoomCollectionViewController.h"

@interface ChatViewController : UIViewController <UICompositeViewDelegate> {
}

@property (nonatomic, strong) IBOutlet UIView* mainView;
@property (nonatomic, retain) IBOutlet UIImageView* backgroundImageView;
@property (nonatomic, retain) ChatRoomCollectionViewController* chatRoom;

@end
