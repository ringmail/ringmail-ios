/* ImageCountdownViewController.h
 *
 */ 

#import <UIKit/UIKit.h>

#import "UICompositeViewController.h"
#import "M13ProgressViewSegmentedBar.h"

@interface ImageCountdownViewController : UIViewController<UICompositeViewDelegate>

@property (copy) void (^onComplete)(void);
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIView *timerView;
@property (nonatomic, strong) UIImage  *image;
@property (nonatomic, strong) M13ProgressViewSegmentedBar* timerBar;
@property (nonatomic, strong) NSTimer* timer;
@property (nonatomic) NSInteger seconds;
@property (nonatomic) NSInteger steps;

- (instancetype)initWithImage:(UIImage*)img complete:(void(^)(void))complete;

- (IBAction)onImageTap:(id)sender;

@end
