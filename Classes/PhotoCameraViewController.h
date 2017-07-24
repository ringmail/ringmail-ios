#import <UIKit/UIKit.h>

#import "UIToggleButton.h"
#import "UICompositeViewController.h"
#import "LLSimpleCamera.h"
#import "BaseCameraViewController.h"
#import "ImageEditViewController.h"

@interface PhotoCameraViewController : BaseCameraViewController<UICompositeViewDelegate> {
}

@property (strong, nonatomic) LLSimpleCamera *camera;
@property (strong, nonatomic) UILabel *errorLabel;
@property (strong, nonatomic) UIButton *snapButton;
@property (strong, nonatomic) UIButton *switchButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *closeButton;
@property (nonatomic) RgSendMediaEditMode editMode;

@end
