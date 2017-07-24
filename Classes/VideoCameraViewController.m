#import "VideoCameraViewController.h"
#import "ViewUtils.h"
#import "Utils.h"
#import "PhoneMainView.h"
#import "LLSimpleCamera.h"
#import "RingKit.h"
#import "ThumbnailFactory.h"

@implementation VideoCameraViewController
{
	int count;
	double progress;
}

@synthesize timer;
@synthesize timerBar;
@synthesize timerView;
@synthesize seconds;
@synthesize steps;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"VideoCameraViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		self.timerBar = [[M13ProgressViewSegmentedBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 10.0)];
		self.seconds = 60;
		self.steps = 120;
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
		compositeDescription = [[UICompositeViewDescription alloc] init:@"VideoCamera"
																content:@"VideoCameraViewController"
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
	
	CGRect screenRect = [[UIScreen mainScreen] bounds];
	
    // ----- initialize camera -------- //
    
    // create camera vc
    self.camera = [[LLSimpleCamera alloc] initWithQuality:AVCaptureSessionPresetHigh
                                                 position:LLCameraPositionRear
                                             videoEnabled:YES];
    
    // attach to a view controller
    [self.camera attachToViewController:self withFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    
    // read: http://stackoverflow.com/questions/5427656/ios-uiimagepickercontroller-result-image-orientation-after-upload
    // you probably will want to set this to YES, if you are going view the image outside iOS.
    /// self.camera.fixOrientationAfterCapture = NO;
    self.camera.fixOrientationAfterCapture = YES;
    self.camera.useDeviceOrientation = YES;
    
    // take the required actions on a device change
    __weak VideoCameraViewController* weakSelf = self;
    [self.camera setOnDeviceChange:^(LLSimpleCamera *camera, AVCaptureDevice * device) {
        
        NSLog(@"Device changed.");
        
        // device changed, check if flash is available
        if([camera isFlashAvailable]) {
            weakSelf.flashButton.hidden = NO;
            if(camera.flash == LLCameraFlashOff) {
                weakSelf.flashButton.selected = NO;
            }
            else {
                weakSelf.flashButton.selected = YES;
            }
        }
        else {
            weakSelf.flashButton.hidden = YES;
        }
    }];
    
    [self.camera setOnError:^(LLSimpleCamera *camera, NSError *error) {
        NSLog(@"Camera error: %@", error);
        
        if([error.domain isEqualToString:LLSimpleCameraErrorDomain]) {
            if(error.code == LLSimpleCameraErrorCodeCameraPermission ||
               error.code == LLSimpleCameraErrorCodeMicrophonePermission) {
                
                if(weakSelf.errorLabel) {
                    [weakSelf.errorLabel removeFromSuperview];
                }
                
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                label.text = @"We need permission for the camera.\nPlease go to your settings.";
                label.numberOfLines = 2;
                label.lineBreakMode = NSLineBreakByWordWrapping;
                label.backgroundColor = [UIColor clearColor];
                label.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:13.0f];
                label.textColor = [UIColor whiteColor];
                label.textAlignment = NSTextAlignmentCenter;
                [label sizeToFit];
                label.center = CGPointMake(screenRect.size.width / 2.0f, screenRect.size.height / 2.0f);
                weakSelf.errorLabel = label;
                [weakSelf.view addSubview:weakSelf.errorLabel];
            }
        }
    }];
	
	[self.camera setOnStartRecording:^(LLSimpleCamera* camera) {
        weakSelf.snapButton.layer.borderColor = [UIColor greenColor].CGColor;
        weakSelf.snapButton.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
	}];

    // ----- camera buttons -------- //
    
    // snap button to capture image
    self.snapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.snapButton.frame = CGRectMake(0, 0, 70.0f, 70.0f);
    self.snapButton.clipsToBounds = YES;
    self.snapButton.layer.cornerRadius = 35.0f;
    self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.snapButton.layer.borderWidth = 2.0f;
    self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.snapButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.snapButton.layer.shouldRasterize = YES;
    [self.snapButton addTarget:self action:@selector(snapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.snapButton];
    
    // button to toggle flash
    self.flashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.flashButton.frame = CGRectMake(0, 0, 16.0f + 20.0f, 24.0f + 20.0f);
    self.flashButton.tintColor = [UIColor whiteColor];
    [self.flashButton setImage:[UIImage imageNamed:@"camera-flash.png"] forState:UIControlStateNormal];
    self.flashButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.flashButton addTarget:self action:@selector(flashButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.flashButton];
    
    if([LLSimpleCamera isFrontCameraAvailable] && [LLSimpleCamera isRearCameraAvailable]) {
        // button to toggle camera positions
        self.switchButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.switchButton.frame = CGRectMake(0, 0, 29.0f + 20.0f, 22.0f + 20.0f);
        self.switchButton.tintColor = [UIColor whiteColor];
        [self.switchButton setImage:[UIImage imageNamed:@"camera-switch.png"] forState:UIControlStateNormal];
        self.switchButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
        [self.switchButton addTarget:self action:@selector(switchButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.switchButton];
    }
	
	self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(0, 0, 32.0f + 20.0f, 24.0f + 32.0f);
    self.closeButton.tintColor = [UIColor whiteColor];
    [self.closeButton setImage:[UIImage imageNamed:@"camera-cancel.png"] forState:UIControlStateNormal];
    self.closeButton.imageEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    [self.closeButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
	
	timerBar.primaryColor = [UIColor blackColor];
	timerBar.secondaryColor = [UIColor whiteColor];
	timerBar.segmentShape = M13ProgressViewSegmentedBarSegmentShapeCircle;
	timerBar.progressDirection = M13ProgressViewSegmentedBarProgressDirectionLeftToRight;

	[timerView addSubview:timerBar];
	[timerView removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
    [super viewWillAppear:animated];
	
	[timerBar setProgress:0.0 animated:NO];
	[timerView setHidden:YES];
	
    // start the camera
    [self.camera start];
	
	[self.view addSubview:timerView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark - Camera Functions

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL*)documentURL:(NSString*)mainUuid
{
	NSURL* url = [self applicationDocumentsDirectory];
	NSString* urlStr = [url absoluteString];
	urlStr = [urlStr stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov", mainUuid]];
	url = [NSURL URLWithString:urlStr];
	return url;
}

- (void)switchButtonPressed:(UIButton *)button
{
    [self.camera togglePosition];
}

- (void)flashButtonPressed:(UIButton *)button
{
    if(self.camera.flash == LLCameraFlashOff) {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOn];
        if(done) {
            self.flashButton.selected = YES;
            self.flashButton.tintColor = [UIColor yellowColor];
        }
    }
    else {
        BOOL done = [self.camera updateFlashMode:LLCameraFlashOff];
        if(done) {
            self.flashButton.selected = NO;
            self.flashButton.tintColor = [UIColor whiteColor];
        }
    }
}

- (void)snapButtonPressed:(UIButton *)button
{
    if (self.camera.isRecording)
	{
		[self timerStop];
		[self stopRecording];
	}
	else
	{
        self.flashButton.hidden = YES;
        self.switchButton.hidden = YES;

        self.snapButton.layer.borderColor = [UIColor blueColor].CGColor;
        self.snapButton.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];

		[self timerStart];
		
		// start recording
		__block NSString* mainUuid = [[NSUUID UUID] UUIDString];
		__block NSURL *outputURL = [self documentURL:mainUuid];
		__block __weak VideoCameraViewController* weakSelf = self;
		[self.camera startRecordingWithOutputUrl:outputURL didRecord:^(LLSimpleCamera *camera, NSURL *outputFileUrl, NSError *error) {
			[weakSelf doneRecording:outputURL uuid:mainUuid];
		}];
   }
}

- (void)stopRecording
{
    self.flashButton.hidden = NO;
    self.switchButton.hidden = NO;

    self.snapButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.snapButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
	[self.camera stopRecording];
}

- (void)doneRecording:(NSURL*)outputURL uuid:(NSString*)mainUuid
{
	NSLog(@"Done Recording: %@", outputURL);
	AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:outputURL options:nil];
	CGFloat scale = [UIScreen mainScreen].scale;
	UIImage* thumb = [ThumbnailFactory thumbnailForVideoAsset:asset size:CGSizeMake(90 * scale, 90 * scale)];
	RgMainViewController* ctl = DYNAMIC_CAST(
		[[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription] push:FALSE],
		RgMainViewController
	);
	[ctl addMedia:@{
		@"file": [outputURL path],
		@"mediaType": @"video/mp4",
		@"localPath": [NSString stringWithFormat:@"%@.mov", mainUuid],
		@"thumbnail": thumb,
	}];
}

- (void)timerStart
{
	dispatch_async(dispatch_get_main_queue(), ^{ // Always run timer on main queue
    	[timerBar setProgress:0.0 animated:NO];
    	[timerView setHidden:NO];
    	self->count = 0;
    	self->progress = 0.0f;
    	double stepsize = ((double)seconds / (double)steps);
    	timer = [NSTimer scheduledTimerWithTimeInterval:stepsize target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
	});
}

- (void)timerStop
{
	dispatch_async(dispatch_get_main_queue(), ^{
    	[timerView setHidden:YES];
    	if (timer != nil)
    	{
    		[timer invalidate];
    		timer = nil;
    	}
	});
}

- (void)timerUpdate:(NSTimer*)ct
{
	NSLog(@"%s Step %d of %ld", __PRETTY_FUNCTION__, self->count, (long)steps);
	self->count++;
	self->progress = (double)self->count / (double)steps;
	dispatch_async(dispatch_get_main_queue(), ^{
		[timerBar setProgress:self->progress animated:NO];
	});
	if (self->count >= steps)
	{
		[timer invalidate];
		timer = nil;
		
		// Stop recording and close
		if (self.camera.isRecording)
    	{
    		[self stopRecording];
    	}
	}
}

- (void)closeButtonPressed:(UIButton *)button
{
	NSLog(@"Close button pressed");
	[self timerStop];
	[self.camera stop];
	[[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription] push:FALSE];
}

/* other lifecycle methods */

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
	
    self.camera.view.frame = self.view.contentBounds;
    
    self.snapButton.center = self.view.contentCenter;
    self.snapButton.bottom = self.view.height - 15.0f;
    
    self.flashButton.center = self.view.contentCenter;
    self.flashButton.top = 5.0f;
    
    self.switchButton.top = 5.0f;
    self.switchButton.right = self.view.width - 5.0f;
	
	self.closeButton.bottom = self.view.height - 5.0f;
	self.closeButton.left = 5.0f;
}

@end
