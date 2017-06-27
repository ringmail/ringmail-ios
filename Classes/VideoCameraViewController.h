#import <UIKit/UIKit.h>

#import "UIToggleButton.h"
#import "UICompositeViewController.h"
#import "LLSimpleCamera.h"
#import "BaseCameraViewController.h"
#import "M13ProgressViewSegmentedBar.h"

@interface VideoCameraViewController : BaseCameraViewController<UICompositeViewDelegate> {
}

@property (strong, nonatomic) LLSimpleCamera *camera;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) UIButton *snapButton;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *closeButton;
@property (nonatomic, strong) IBOutlet UIView *timerView;
@property (nonatomic, strong) M13ProgressViewSegmentedBar* timerBar;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic) NSInteger seconds;
@property (nonatomic) NSInteger steps;

@end
