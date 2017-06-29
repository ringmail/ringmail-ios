#import "ImageEditViewController.h"
#import "MomentCameraViewController.h"
#import "ViewUtils.h"
#import "Utils.h"
#import "PhoneMainView.h"
#import "CLImageEditor.h"
#import "ThumbnailFactory.h"


@implementation ImageEditViewController

@synthesize image;
@synthesize imageView;
@synthesize editMode;
@synthesize editor;

#pragma mark - Lifecycle Functions

- (id)initWithImage:(UIImage*)img editMode:(RgSendMediaEditMode)inputMode
{
	self = [super initWithNibName:@"ImageEditViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		image = img;
		editMode = inputMode;
		editor = nil;
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
			content:@"ImageEditViewController"
		   stateBar:nil
	stateBarEnabled:false
             navBar:nil
			 tabBar:nil
      navBarEnabled:false
	  tabBarEnabled:false
		 fullscreen:true
	  landscapeMode:false
	   portraitMode:true];
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor blackColor];
	imageView.image = image;
	imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
	editor = [[CLImageEditor alloc] init];
	editor.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[editor showInViewController:self withImageView:imageView];
}

#pragma mark - CLImageEditorTransition delegate

- (void)imageEditor:(CLImageEditor*)edit didDismissWithImageView:(UIImageView*)imgView canceled:(BOOL)canceled
{
	if (canceled)
	{
    	NSLog(@"Edit Cancelled");
		[[PhoneMainView instance] changeCurrentView:[MomentCameraViewController compositeViewDescription] push:FALSE];
	}
	else
	{
    	NSLog(@"Edit Complete");
		UIImage* newImage = [imgView image];
    	__block UIImage* thumb = [ThumbnailFactory thumbnailForImage:newImage size:CGSizeMake(180, 180)];
		
    	// Write file
        NSString* imageUUID = [[NSUUID UUID] UUIDString];
        __block NSString* tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", imageUUID]];
        [UIImagePNGRepresentation(newImage) writeToFile:tmpfile atomically:YES];
    	
    	RgSendMediaEditMode mode = editMode;
    	if (mode == RgSendMediaEditModeDefault) // Back to send panel
    	{
    		RgMainViewController* ctl = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription] push:NO], RgMainViewController);
    		[ctl addMedia:@{
    			@"file": tmpfile,
    			@"mediaType": @"image/png",
    			@"thumbnail": thumb,
    		}];
    	}
		else if (mode == RgSendMediaEditModeMoment)
		{
//	    	RgMainViewController* ctl = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription] push:NO], RgMainViewController);
//    		[ctl addMedia:@{
//    			@"file": tmpfile,
//    			@"mediaType": @"image/png",
//    			@"thumbnail": thumb,
//				@"moment": @1,
//    		}];
            /*[[NSNotificationCenter defaultCenter] postNotificationName:kRgSendComponentDisplayContacts object:nil userInfo:@{
                 @"mode": @"multi",
                 @"file": tmpfile,
                 @"mediaType": @"image/png",
                 @"thumbnail": thumb,
                 @"moment": @1,
            }];*/
		}
	}
}

@end
