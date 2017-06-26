/* ImageCountdownViewController.m
 *
 */

#import "ImageCountdownViewController.h"
#import "PhoneMainView.h"

@implementation ImageCountdownViewController
{
	int count;
	double progress;
}

@synthesize imageView;
@synthesize image;
@synthesize timer;
@synthesize timerBar;
@synthesize timerView;
@synthesize seconds;
@synthesize steps;
@synthesize onComplete;

#pragma mark - Lifecycle Functions

- (instancetype)initWithImage:(UIImage*)img complete:(void(^)(void))complete
{
	self = [super initWithNibName:@"ImageCountdownViewController" bundle:[NSBundle mainBundle]];
	if (self)
	{
		self.image = img;
		self.onComplete = complete;
		self.timerBar = [[M13ProgressViewSegmentedBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 120.0, 10.0)];
		self.seconds = 10;
		self.steps = 20;
	}
	return self;
}


#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"ImageCountdownView"
				content:@"ImageCountdownViewController"
			   stateBar:nil
		stateBarEnabled:false
                 navBar:nil
				 tabBar:nil
          navBarEnabled:false
		  tabBarEnabled:false
			 fullscreen:true
		  landscapeMode:[LinphoneManager runningOnIpad]
		   portraitMode:true];
	}
	return compositeDescription;
}

#pragma mark - View Controller Functions

- (void)viewDidLoad
{
	[super viewDidLoad];
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	[imageView setImage:image];
	
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onImageTap:)];
	gestureRecognizer.cancelsTouchesInView = NO;  // this prevents the gesture recognizers to 'block' touches
	[imageView addGestureRecognizer:gestureRecognizer];
	imageView.userInteractionEnabled = YES;
	
	timerBar.primaryColor = [UIColor blackColor];
	timerBar.secondaryColor = [UIColor whiteColor];
	timerBar.segmentShape = M13ProgressViewSegmentedBarSegmentShapeCircle;
	timerBar.progressDirection = M13ProgressViewSegmentedBarProgressDirectionLeftToRight;
	[timerBar setProgress:0.0 animated:NO];
	[timerView addSubview:timerBar];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	self->count = 0;
	self->progress = 0.0f;
	double stepsize = ((double)seconds / (double)steps);
	timer = [NSTimer scheduledTimerWithTimeInterval:stepsize target:self selector:@selector(timerUpdate:) userInfo:nil repeats:YES];
}

#pragma mark - Action Functions

- (IBAction)onImageTap:(id)sender
{
	if (timer != nil)
	{
		[timer invalidate];
		timer = nil;
	}
	if (self.onComplete != nil)
	{
		self.onComplete();
	}
	if ([[[PhoneMainView instance] currentView] equal:[ImageCountdownViewController compositeViewDescription]])
	{
		[[PhoneMainView instance] popCurrentView];
	}
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
        if (self.onComplete != nil)
        {
			self.onComplete();
        }
		if ([[[PhoneMainView instance] currentView] equal:[ImageCountdownViewController compositeViewDescription]])
    	{
    		[[PhoneMainView instance] popCurrentView];
    	}
	}
}

@end
