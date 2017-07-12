#import <UIKit/UIKit.h>

#import "UIToggleButton.h"
#import "UICompositeViewController.h"
#import "CLImageEditor.h"

typedef NS_ENUM(NSInteger, RgSendMediaEditMode) {
        RgSendMediaEditModeDefault,
        RgSendMediaEditModeMoment
};

@interface ImageEditViewController : UIViewController<UICompositeViewDelegate, CLImageEditorTransitionDelegate, CLImageEditorThemeDelegate> {
}

@property (nonatomic, strong) IBOutlet UIImageView* imageView;
@property (nonatomic, strong) NSString* currentFile;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) CLImageEditor* editor;
@property (nonatomic) RgSendMediaEditMode editMode;

- (id)initWithImage:(UIImage*)img editMode:(RgSendMediaEditMode)editMode;
- (id)initWithFilePath:(NSString*)imgPath editMode:(RgSendMediaEditMode)inputMode;

- (void)imageEditor:(CLImageEditor*)editor didDismissWithImageView:(UIImageView*)imageView canceled:(BOOL)canceled;

@end
