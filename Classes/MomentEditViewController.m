#import "MomentEditViewController.h"
#import "ViewUtils.h"
#import "Utils.h"
#import "PhoneMainView.h"
#import "CLImageEditor.h"

@implementation MomentEditViewController

@synthesize image;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"MomentEditViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		image = nil;
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"MomentEdit"
																content:@"MomentEditViewController"
															   stateBar:nil
														stateBarEnabled:false
                                                                 navBar:nil
																 tabBar:nil
                                                          navBarEnabled:false
														  tabBarEnabled:false
															 fullscreen:true
														  landscapeMode:false
														   portraitMode:true
                                                                segLeft:@""
                                                               segRight:@""];
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor blackColor];
	
	//CGRect screenRect = [[UIScreen mainScreen] bounds];
	
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)setImage:(UIImage*)newImage
{
	image = newImage;
	CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:image delegate:self];
	[self presentViewController:editor animated:NO completion:nil];
}

#pragma mark - CLImageEditor delegate

- (void)imageEditor:(CLImageEditor *)editor didFinishEdittingWithImage:(UIImage *)newImage
{
    image = newImage;
    //[editor dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageEditor:(CLImageEditor *)editor willDismissWithImageView:(UIImageView *)imageView canceled:(BOOL)canceled
{
}

@end
