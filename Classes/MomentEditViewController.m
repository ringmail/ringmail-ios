#import "MomentEditViewController.h"
#import "MomentCameraViewController.h"
#import "ViewUtils.h"
#import "Utils.h"
#import "PhoneMainView.h"
#import "CLImageEditor.h"

@implementation MomentEditViewController

@synthesize image;
@synthesize editMode;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"MomentEditViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		image = nil;
		editMode = RgSendMediaEditModeDefault;
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	self.image = [[PhoneMainView instance] momentImage];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark - Operations

- (void)editImage:(UIImage*)img
{
	image = img;
	CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:image delegate:self];
	[self presentViewController:editor animated:NO completion:nil];
}

- (UIImage *)makeThumbnail:(UIImage *)inputImg size:(CGSize)size
{
    CGFloat scale = size.width/image.size.width;
    if ((size.height/image.size.height) > scale)
	{
		scale = size.height/image.size.height;
	}
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [inputImg drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - CLImageEditor delegate

- (void)imageEditor:(CLImageEditor *)editor didFinishEdittingWithImage:(UIImage *)newImage
{
	//NSLog(@"Edit Complete");
	__block UIImage* thumb = [self makeThumbnail:newImage size:CGSizeMake(180, 180)];
	
	// Write file
    NSString* imageUUID = [[NSUUID UUID] UUIDString];
    __block NSString* tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", imageUUID]];
    [UIImagePNGRepresentation(newImage) writeToFile:tmpfile atomically:YES];
	
	RgSendMediaEditMode mode = editMode;
	[editor dismissViewControllerAnimated:YES completion:^(void){
    	if (mode == RgSendMediaEditModeDefault) // Back to send panel
    	{
    		RgMainViewController* ctl = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription] push:FALSE], RgMainViewController);
    		[ctl addMedia:@{
    			@"file": tmpfile,
    			@"thumbnail": thumb,
    		}];
    	}
	}];
}

- (void)imageEditorDidCancel:(CLImageEditor*)editor;
{
	//NSLog(@"Cancel Moment Edit");
    [editor dismissViewControllerAnimated:NO completion:nil];
	[[PhoneMainView instance] changeCurrentView:[MomentCameraViewController compositeViewDescription] push:FALSE];
}

@end
