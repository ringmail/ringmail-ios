/* ChatViewController.h
 */

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "ChatViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

@implementation ChatViewController

@synthesize mainView;
@synthesize chatRoom;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"ChatViewController" bundle:[NSBundle mainBundle]];
	return self;
}

- (void)dealloc {

	// Remove all observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Chat"
																content:@"ChatViewController"
															   stateBar:@"UIStateBar"
														stateBarEnabled:true
                                                                 navBar:@"UINavBar"
																 tabBar:@"UIMainBar"
                                                          navBarEnabled:true
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true
                                                                segLeft:@"All"
                                                               segRight:@"Missed"];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidLoad {
	[super viewDidLoad];

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:0];
    
    ChatRoomCollectionViewController *mainController = [[ChatRoomCollectionViewController alloc] initWithCollectionViewLayout:flowLayout chatThreadID:[[LinphoneManager instance] chatSession]];
    
    [[mainController collectionView] setBounces:YES];
    [[mainController collectionView] setAlwaysBounceVertical:YES];
    
    CGRect r = mainView.frame;
    r.origin.y = 0;
    [mainController.view setFrame:r];
    [mainView addSubview:mainController.view];
    [self addChildViewController:mainController];
    [mainController didMoveToParentViewController:self];
    chatRoom = mainController;
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshEvent:) name:kRgTextReceived object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshEvent:) name:kRgTextUpdate object:nil];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgTextReceived object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgTextUpdate object:nil];
}

#pragma mark - Event Functions

- (void)refreshEvent:(NSNotification *)notif {
}

@end
