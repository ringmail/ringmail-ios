/* RgFavoriteViewController.h
 */

#import <UIKit/UIKit.h>

#import "UICompositeViewController.h"
#import "FavoriteCollectionViewController.h"

#import "UICallButton.h"
#import "UIMessageButton.h"
#import "UIDigitButton.h"

@interface RgFavoriteViewController : UIViewController <UICompositeViewDelegate> {
}

@property (nonatomic, strong) IBOutlet UIView* mainView;
@property (nonatomic, retain) FavoriteCollectionViewController* mainViewController;
@property (nonatomic, assign) BOOL needsRefresh;
@property (nonatomic, assign) BOOL visible;

@end
