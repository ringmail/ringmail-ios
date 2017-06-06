#import <UIKit/UIKit.h>

#import "UIToggleButton.h"
#import "UICompositeViewController.h"
#import "CLImageEditor.h"

typedef NS_ENUM(NSInteger, RgSendMediaEditMode) {
        RgSendMediaEditModeDefault,
        RgSendMediaEditModeMoment
};

@interface MomentEditViewController : UIViewController<UICompositeViewDelegate, CLImageEditorDelegate, CLImageEditorTransitionDelegate, CLImageEditorThemeDelegate> {
}

@property (nonatomic, strong) UIImage* image;
@property (nonatomic) RgSendMediaEditMode editMode;

- (void)editImage:(UIImage*)img;

- (void)imageEditor:(CLImageEditor*)editor didFinishEdittingWithImage:(UIImage*)image;
- (void)imageEditorDidCancel:(CLImageEditor*)editor;

@end
