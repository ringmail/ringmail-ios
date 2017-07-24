#import "ImageEditViewController.h"
#import "MomentCameraViewController.h"
#import "ViewUtils.h"
#import "Utils.h"
#import "PhoneMainView.h"
#import "CLImageEditor.h"
#import "ThumbnailFactory.h"
#import "RgMomentDelegate.h"

@implementation ImageEditViewController

@synthesize image;
@synthesize imageView;
@synthesize editMode;
@synthesize editor;
@synthesize currentFile;

#pragma mark - Lifecycle Functions

- (id)initWithImage:(UIImage*)img editMode:(RgSendMediaEditMode)inputMode
{
	self = [super initWithNibName:@"ImageEditViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
        currentFile = @"";
		image = img;
		editMode = inputMode;
		editor = nil;
	}
	return self;
}

- (id)initWithFilePath:(NSString*)imgPath editMode:(RgSendMediaEditMode)inputMode
{
    self = [super initWithNibName:@"ImageEditViewController" bundle:[NSBundle mainBundle]];
    if (self != nil) {
        currentFile = imgPath;
        image = [UIImage imageWithContentsOfFile:imgPath];
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
	editor.editMode = self.editMode;
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
        __block NSString* tmpfile;
		
    	// Set file path
        if ([currentFile isEqual: @""])
        {
            tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", [[NSUUID UUID] UUIDString]]];
        }
        else
        {
            tmpfile = currentFile;
        }
        // Write file
        [UIImagePNGRepresentation(newImage) writeToFile:tmpfile atomically:YES];
    	
    	RgSendMediaEditMode mode = editMode;
    	if (mode == RgSendMediaEditModeSendPanel) // Back to send panel
    	{
			UIImage* thumb = [ThumbnailFactory thumbnailForImage:newImage size:CGSizeMake(180, 180)];
    		RgMainViewController* ctl = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription] push:NO], RgMainViewController);
    		[ctl addMedia:@{
    			@"file": tmpfile,
    			@"mediaType": @"image/png",
    			@"thumbnail": thumb,
    		}];
    	}
		else if (mode == RgSendMediaEditModeMoment)
		{
		    SendContactsViewController *vc = [[SendContactsViewController alloc] initWithSelectionMode:SendContactSelectionModeMulti];
			RgMomentDelegate* md = [RgMomentDelegate sharedInstance];
			[md setFile:tmpfile];
			vc.delegate = md;
			[[PhoneMainView instance] changeCurrentView:[SendContactsViewController compositeViewDescription] content:vc push:YES];
		}
		else if (mode == RgSendMediaEditModeMessage)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:kRgAddMessageMedia object:nil userInfo:@{
    			@"file": tmpfile,
    			@"mediaType": @"image/png",
			}];
			[[PhoneMainView instance] changeCurrentView:[MessageViewController compositeViewDescription] push:NO];
		}
	}
}

@end
