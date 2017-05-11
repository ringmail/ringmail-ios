/* PhoneMainView.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioServices.h>

#import "LinphoneAppDelegate.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "DTActionSheet.h"
#import "SVWebViewController.h"
#import "SVModalWebViewController.h"
#import "RgWebViewDelegate.h"
#import "UIColor+Hex.h"
#import "DTActionSheet.h"
#import "RegexKitLite/RegexKitLite.h"


static RootViewManager *rootViewManagerInstance = nil;

@interface SVModalWebViewController ()

@property (nonatomic, strong) SVWebViewController *webViewController;

@end

@implementation RootViewManager {
	PhoneMainView *currentViewController;
}

+ (void)setupWithPortrait:(PhoneMainView *)portrait {
	assert(rootViewManagerInstance == nil);
	rootViewManagerInstance = [[RootViewManager alloc] initWithPortrait:portrait];
}

- (instancetype)initWithPortrait:(PhoneMainView *)portrait {
	self = [super init];
	if (self) {
		self.portraitViewController = portrait;
		self.rotatingViewController = portrait;
        
        // This line creates duplicate linphone cores for some reason
		//self.rotatingViewController = [[PhoneMainView alloc] init];

		self.portraitViewController.name = @"Portrait";
		self.rotatingViewController.name = @"Rotating";

		currentViewController = portrait;
		self.viewDescriptionStack = [NSMutableArray array];
	}
	return self;
}

+ (RootViewManager *)instance {
	if (!rootViewManagerInstance) {
		@throw [NSException exceptionWithName:@"RootViewManager" reason:@"nil instance" userInfo:nil];
	}
	return rootViewManagerInstance;
}

- (PhoneMainView *)currentView {
	return currentViewController;
}

- (PhoneMainView *)setViewControllerForDescription:(UICompositeViewDescription *)description {
	PhoneMainView *newMainView = description.landscapeMode ? self.rotatingViewController : self.portraitViewController;

	if ([LinphoneManager runningOnIpad])
		return currentViewController;

	if (newMainView != currentViewController) {
		PhoneMainView *previousMainView = currentViewController;
		UIInterfaceOrientation nextViewOrientation = newMainView.interfaceOrientation;
		UIInterfaceOrientation previousOrientation = currentViewController.interfaceOrientation;

		LOGI(@"Changing rootViewController: %@ -> %@", currentViewController.name, newMainView.name);
		currentViewController = newMainView;
		LinphoneAppDelegate *delegate = (LinphoneAppDelegate *)[UIApplication sharedApplication].delegate;

		if ([[LinphoneManager instance] lpConfigBoolForKey:@"animations_preference"] == true) { // Disabled animations for RingMail
			[UIView transitionWithView:delegate.window
				duration:0.3
				options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent
				animations:^{
				  delegate.window.rootViewController = newMainView;
				  // when going to landscape-enabled view, we have to get the current portrait frame and orientation,
				  // because it could still have landscape-based size
				  if (nextViewOrientation != previousOrientation && newMainView == self.rotatingViewController) {
					  newMainView.view.frame = previousMainView.view.frame;
					  [newMainView.mainViewController.view setFrame:previousMainView.mainViewController.view.frame];
					  [newMainView willRotateToInterfaceOrientation:previousOrientation duration:0.25];
					  [newMainView willAnimateRotationToInterfaceOrientation:previousOrientation duration:0.25];
					  [newMainView didRotateFromInterfaceOrientation:nextViewOrientation];
				  }
				}
				completion:^(BOOL finished){
				}];
		} else {
			delegate.window.rootViewController = newMainView;
			// when going to landscape-enabled view, we have to get the current portrait frame and orientation,
			// because it could still have landscape-based size
			if (nextViewOrientation != previousOrientation && newMainView == self.rotatingViewController) {
				newMainView.view.frame = previousMainView.view.frame;
				[newMainView.mainViewController.view setFrame:previousMainView.mainViewController.view.frame];
				[newMainView willRotateToInterfaceOrientation:previousOrientation duration:0.];
				[newMainView willAnimateRotationToInterfaceOrientation:previousOrientation duration:0.];
				[newMainView didRotateFromInterfaceOrientation:nextViewOrientation];
			}
		}
	}
	return currentViewController;
}

@end

@implementation PhoneMainView

@synthesize mainViewController;
@synthesize currentView;
@synthesize statusBarBG;
@synthesize volumeView;
@synthesize webDelegate;
@synthesize momentImage;
@synthesize optionsModalViewController;
@synthesize optionsModalBG;

#pragma mark - Lifecycle Functions

- (void)initPhoneMainView {
	currentView = nil;
	inhibitedEvents = [[NSMutableArray alloc] init];
	errorIds = [NSMutableDictionary dictionary];
    webDelegate = [[RgWebViewDelegate alloc] init];
}

- (id)init {
	self = [super init];
	if (self) {
		[self initPhoneMainView];
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		[self initPhoneMainView];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initPhoneMainView];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];

	volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, -100, 16, 16)];
	volumeView.showsRouteButton = false;
	volumeView.userInteractionEnabled = false;
    
    	// Set observers
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(launchBrowser:)
												 name:kRgLaunchBrowser
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callUpdate:)
												 name:kLinphoneCallUpdate
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(registrationUpdate:)
												 name:kLinphoneRegistrationUpdate
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textReceived:)
												 name:kLinphoneTextReceived
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(onGlobalStateChanged:)
												 name:kLinphoneGlobalStateUpdate
											   object:nil];
	[[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(batteryLevelChanged:)
												 name:UIDeviceBatteryLevelDidChangeNotification
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleGoogleSignInStartEvent:)
                                                 name:kRgGoogleSignInStart
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleGoogleSignInCompleteEvent)
                                                 name:kRgGoogleSignInComplete
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(presentOptionsModal)
                                                 name:kRgPresentOptionsModal
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismissOptionsModal)
                                                 name:kRgDismissOptionsModal
                                               object:nil];
    
	[self.view addSubview:mainViewController.view];
    
    optionsModalViewController = [[RgOptionsModalViewController alloc]init];
    optionsModalViewController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    optionsModalBG = [[UIView alloc] initWithFrame:self.view.frame];
    [optionsModalBG setBackgroundColor:[UIColor colorWithHex:@"#212121" alpha:0.65f]];
    optionsModalBG.hidden = YES;
    [self.view addSubview:optionsModalBG];
    
}


- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgGoogleSignInStart object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgGoogleSignInComplete object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgPresentOptionsModal object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgDismissOptionsModal object:nil];
}


#pragma mark - Options Model Functions
- (void)presentOptionsModal {
    optionsModalBG.hidden = NO;
    [self presentViewController:optionsModalViewController animated:YES completion:nil];
}

- (void)dismissOptionsModal {
    optionsModalBG.hidden = YES;
}


- (void)setVolumeHidden:(BOOL)hidden {
	// sometimes when placing a call, the volume view will appear. Inserting a
	// carefully hidden MPVolumeView into the view hierarchy will hide it
	if (hidden) {
		if (!(volumeView.superview == self.view)) {
			[self.view addSubview:volumeView];
		}
	} else {
		if (volumeView.superview == self.view) {
			[volumeView removeFromSuperview];
		}
	}
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
#else
- (NSUInteger)supportedInterfaceOrientations
#endif
{
	if ([LinphoneManager runningOnIpad] || [mainViewController currentViewSupportsLandscape])
		return UIInterfaceOrientationMaskAll;
	else {
		return UIInterfaceOrientationMaskPortrait;
	}
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
								duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[mainViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self orientationUpdate:toInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[mainViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[mainViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (UIInterfaceOrientation)interfaceOrientation {
	return [mainViewController currentOrientation];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	[mainViewController clearCache:[RootViewManager instance].viewDescriptionStack];
}

#pragma mark - Event Functions

- (void)textReceived:(NSNotification *)notif {
	LinphoneAddress *from = [[notif.userInfo objectForKey:@"from_address"] pointerValue];
	NSString *callID = [notif.userInfo objectForKey:@"call-id"];
	if (from != nil) {
		[self playMessageSoundForCallID:callID];
	}
}

- (void)registrationUpdate:(NSNotification *)notif {
	LinphoneRegistrationState state = [[notif.userInfo objectForKey:@"state"] intValue];
	LinphoneProxyConfig *cfg = [[notif.userInfo objectForKey:@"cfg"] pointerValue];
	// Only report bad credential issue
	if (state == LinphoneRegistrationFailed &&
		[UIApplication sharedApplication].applicationState == UIApplicationStateBackground &&
		linphone_proxy_config_get_error(cfg) == LinphoneReasonBadCredentials) {
		UIAlertView *error =
			[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Registration failure", nil)
									   message:NSLocalizedString(@"Bad credentials, check your account settings", nil)
									  delegate:nil
							 cancelButtonTitle:NSLocalizedString(@"Continue", nil)
							 otherButtonTitles:nil, nil];
		[error show];
	}
}

- (void)onGlobalStateChanged:(NSNotification *)notif {
	LinphoneGlobalState state = (LinphoneGlobalState)[[[notif userInfo] valueForKey:@"state"] integerValue];
	static BOOL already_shown = FALSE;
	if (state == LinphoneGlobalOn && !already_shown && [LinphoneManager instance].wasRemoteProvisioned) {
		LinphoneProxyConfig *conf = NULL;
		linphone_core_get_default_proxy([LinphoneManager getLc], &conf);
		if ([[LinphoneManager instance] lpConfigBoolForKey:@"show_login_view" forSection:@"app"] && conf == NULL) {
			already_shown = TRUE;
			WizardViewController *controller = DYNAMIC_CAST(
				[[PhoneMainView instance] changeCurrentView:[WizardViewController compositeViewDescription]],
				WizardViewController);
			if (controller != nil) {
				[controller fillDefaultValues];
			}
		}
	}
}

- (void)callUpdate:(NSNotification *)notif {
	LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
	NSString *message = [notif.userInfo objectForKey:@"message"];
    LOGI(@"Call State:[%p] %s", call, linphone_call_state_to_string(state));

	bool canHideInCallView = (linphone_core_get_calls([LinphoneManager getLc]) == NULL);

	// Don't handle call state during incoming call view
	if ([[self currentView] equal:[IncomingCallViewController compositeViewDescription]] &&
		state != LinphoneCallError && state != LinphoneCallEnd) {
		return;
	}

	switch (state) {
	case LinphoneCallIncomingReceived:
	case LinphoneCallIncomingEarlyMedia: {
		[self displayIncomingCall:call];
		break;
	}
	case LinphoneCallOutgoingInit:
	case LinphoneCallPausedByRemote:
	case LinphoneCallConnected:
	case LinphoneCallStreamsRunning: {
		[self changeCurrentView:[RgInCallViewController compositeViewDescription]];
		break;
	}
	case LinphoneCallUpdatedByRemote: {
		const LinphoneCallParams *current = linphone_call_get_current_params(call);
		const LinphoneCallParams *remote = linphone_call_get_remote_params(call);

		if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
			[self changeCurrentView:[RgInCallViewController compositeViewDescription]];
		}
		break;
	}
	case LinphoneCallError: {
		NSString *sipId = [NSString stringWithCString:linphone_call_log_get_call_id(linphone_call_get_call_log(call)) encoding:NSASCIIStringEncoding];
		NSLog(@"Errors: %@", errorIds);
		if (errorIds[sipId] == nil)
		{
			errorIds[sipId] = @1;
            [self displayCallError:call message:message];
		}
		// Note: These are triggered via HTTP API now, not via SIP
        /*if (linphone_call_get_reason(call) == LinphoneReasonMovedPermanently) // Not an error, just a URL
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                // Assume HTTP(S) urls for now, check for ring:// later
                NSLog(@"RingMail: Redirect to URL: %@", message);
                UIViewController* cur = (UIViewController *)[PhoneMainView instance];
                SVModalWebViewController *webViewModal = [[SVModalWebViewController alloc] initWithAddress:message];
                [webDelegate setWebView:webViewModal.webViewController];
                [webViewModal setWebViewDelegate:webDelegate];
                [cur presentViewController:webViewModal animated:NO completion:NULL];
            }];
        }
        else
        {
            [self displayCallError:call message:message];
        }*/
	}
	case LinphoneCallEnd: {
		if (canHideInCallView) {
			// Go to dialer view
			RgMainViewController *controller = DYNAMIC_CAST(
				[self changeCurrentView:[RgMainViewController compositeViewDescription]], RgMainViewController);
			if (controller != nil) {
//				[controller setAddress:@""];  // mrkbxt
				[controller setTransferMode:FALSE];
			}
		} else {
			[self changeCurrentView:[RgInCallViewController compositeViewDescription]];
		}
		break;
	}
	default:
		break;
	}
}

- (void) launchBrowser:(NSNotification *)notif
{
	__block NSString *address = [notif.userInfo objectForKey:@"address"];
	if (address != nil && ![address isKindOfClass:[NSNull class]])
	{
        if ([address length] > 0)
        {
        	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        		// Assume HTTP(S) urls for now, check for ring:// later
        		NSLog(@"RingMail: Launch browser to URL: %@", address);
        		UIViewController* cur = (UIViewController *)[PhoneMainView instance];
        		SVModalWebViewController *webViewModal = [[SVModalWebViewController alloc] initWithAddress:address];
        		[webDelegate setWebView:webViewModal.webViewController];
        		[webViewModal setWebViewDelegate:webDelegate];
        		[cur presentViewController:webViewModal animated:NO completion:NULL];
        	}];
        }
	}
    else
    {
   		NSLog(@"RingMail: No RingPage address for hashtag");
    }
}

#pragma mark -

- (void)orientationUpdate:(UIInterfaceOrientation)orientation {
	int oldLinphoneOrientation = linphone_core_get_device_rotation([LinphoneManager getLc]);
	int newRotation = 0;
	switch (orientation) {
	case UIInterfaceOrientationPortrait:
		newRotation = 0;
		break;
	case UIInterfaceOrientationPortraitUpsideDown:
		newRotation = 180;
		break;
	case UIInterfaceOrientationLandscapeRight:
		newRotation = 270;
		break;
	case UIInterfaceOrientationLandscapeLeft:
		newRotation = 90;
		break;
	default:
		newRotation = oldLinphoneOrientation;
	}
	if (oldLinphoneOrientation != newRotation) {
		linphone_core_set_device_rotation([LinphoneManager getLc], newRotation);
		LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
		if (call && linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
			// Orientation has changed, must call update call
			linphone_core_update_call([LinphoneManager getLc], call, NULL);
		}
	}
}

- (void)startUp {
    if ([RgManager configReadyAndVerified])
    {
        NSLog(@"RingMail: Startup - Config Ready and Verified");
		[self updateApplicationBadgeNumber]; // Update Badge at startup
        [[LinphoneManager instance] startLinphoneCore];
        [RgManager initialLogin];
        [self changeCurrentView:[RgMainViewController compositeViewDescription]];
    }
    else
    {
        NSLog(@"RingMail: Startup - Need Setup Wizard");
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@"" forKey:@"msgContactID"];
        [defaults setObject:@"" forKey:@"callContactID"];
        
        WizardViewController *controller = DYNAMIC_CAST(
            [self changeCurrentView:[WizardViewController compositeViewDescription]],
            WizardViewController);
        if (controller != nil) {
            [controller startWizard];
        }
    }
}

- (void)updateApplicationBadgeNumber {
	int count = 0;
	//count += linphone_core_get_missed_calls_count([LinphoneManager getLc]);
	//count += [[[[LinphoneManager instance] chatManager] dbGetSessionUnread] integerValue];
	//count += linphone_core_get_calls_nb([LinphoneManager getLc]);
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:count];
}

+ (CATransition *)getBackwardTransition {
	BOOL RTL = [LinphoneManager langageDirectionIsRTL];
	NSString *transition = RTL ? kCATransitionFromRight : kCATransitionFromLeft;
	CATransition *trans = [CATransition animation];
	[trans setType:kCATransitionPush];
	[trans setDuration:0.35];
	[trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	[trans setSubtype:transition];

	return trans;
}

+ (CATransition *)getForwardTransition {
	BOOL RTL = [LinphoneManager langageDirectionIsRTL];
	NSString *transition = RTL ? kCATransitionFromLeft : kCATransitionFromRight;
	CATransition *trans = [CATransition animation];
	[trans setType:kCATransitionPush];
	[trans setDuration:0.35];
	[trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
	[trans setSubtype:transition];

	return trans;
}

+ (PhoneMainView *)instance {
	return [[RootViewManager instance] currentView];
}

- (void)showTabBar:(BOOL)show {
	[mainViewController setToolBarHidden:!show];
}

- (void)showStateBar:(BOOL)show {
	[mainViewController setStateBarHidden:!show];
}

- (void)updateStatusBar:(UICompositeViewDescription *)to_view {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
	// In iOS7, the app has a black background on dialer, incoming and incall, so we have to adjust the
	// status bar style for each transition to/from these views
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    statusBarBG.backgroundColor = [UIColor colorWithHex:@"#F4F4F4" alpha:1.0f];

#endif
}

- (void)updateNavBar:(UICompositeViewDescription*) vc {
    printf("updating Nav Bar for: %s\n", [vc.name UTF8String]);  // mrkbxt
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"header"] = vc.name;
    dict[@"lSeg"] = vc.segLeft;
    dict[@"rSeg"] = vc.segRight;
    [[NSNotificationCenter defaultCenter] postNotificationName:kRgNavBarViewChange object:nil userInfo:dict];
}

- (void)fullScreen:(BOOL)enabled {
	[statusBarBG setHidden:enabled];
	[mainViewController setFullScreen:enabled];
}

- (UIViewController *)changeCurrentView:(UICompositeViewDescription *)view {
	return [self changeCurrentView:view push:FALSE];
}

- (UIViewController *)changeCurrentView:(UICompositeViewDescription *)view push:(BOOL)push {
	BOOL force = push;
	NSMutableArray *viewStack = [RootViewManager instance].viewDescriptionStack;
	if (!push) {
		force = [viewStack count] > 1;
		[viewStack removeAllObjects];
	}
	[viewStack addObject:view];
	return [self _changeCurrentView:view transition:nil force:force];
}

- (UIViewController *)_changeCurrentView:(UICompositeViewDescription *)view
							  transition:(CATransition *)transition
								   force:(BOOL)force {
	LOGI(@"PhoneMainView: Change current view to %@", [view name]);

	PhoneMainView *vc = [[RootViewManager instance] setViewControllerForDescription:view];

	if (force || ![view equal:vc.currentView] || vc != self) {
        // RingMail: No animated transitions :(->

        [vc.mainViewController setViewTransition:nil];
		[vc updateStatusBar:view];
		[vc.mainViewController changeView:view];
		vc->currentView = view;
        [vc updateNavBar:view];
	}

	//[[RootViewManager instance] setViewControllerForDescription:view];

	NSDictionary *mdict = [NSMutableDictionary dictionaryWithObject:vc->currentView forKey:@"view"];
	[[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneMainViewChange object:self userInfo:mdict];

	return [vc->mainViewController getCurrentViewController];
}

- (void)popToView:(UICompositeViewDescription *)view {
	NSMutableArray *viewStack = [RootViewManager instance].viewDescriptionStack;
	while ([viewStack count] > 1 && ![[viewStack lastObject] equal:view]) {
		[viewStack removeLastObject];
	}
	[self _changeCurrentView:[viewStack lastObject] transition:[PhoneMainView getBackwardTransition] force:TRUE];
}

- (UICompositeViewDescription *)firstView {
	UICompositeViewDescription *view = nil;
	NSArray *viewStack = [RootViewManager instance].viewDescriptionStack;
	if ([viewStack count]) {
		view = [viewStack objectAtIndex:0];
	}
	return view;
}

- (UICompositeViewDescription *)topView {
    UICompositeViewDescription *view = nil;
    NSArray *viewStack = [RootViewManager instance].viewDescriptionStack;
    if ([viewStack count]) {
        view = [viewStack objectAtIndex:([viewStack count] - 1)];
    }
    return view;
}

- (UIViewController *)popCurrentView {
	LOGI(@"PhoneMainView: Pop view");
	NSMutableArray *viewStack = [RootViewManager instance].viewDescriptionStack;
	if ([viewStack count] > 1) {
		[viewStack removeLastObject];
		[self _changeCurrentView:[viewStack lastObject] transition:[PhoneMainView getBackwardTransition] force:TRUE];
		return [mainViewController getCurrentViewController];
	}
	return nil;
}

- (void)displayCallError:(LinphoneCall *)call message:(NSString *)message {
	const char *lUserNameChars = linphone_address_get_username(linphone_call_get_remote_address(call));
	NSString *lUserName =
		lUserNameChars ? [[NSString alloc] initWithUTF8String:lUserNameChars] : NSLocalizedString(@"Unknown", nil);
	NSString *lMessage;
	NSString *lTitle;
	
	lUserName = [lUserName stringByReplacingOccurrencesOfRegex:@"\\\\" withString:@"@"];

	// get default proxy
	LinphoneProxyConfig *proxyCfg;
	linphone_core_get_default_proxy([LinphoneManager getLc], &proxyCfg);
	if (proxyCfg == nil) {
		lMessage = NSLocalizedString(@"Please make sure your device is connected to the internet and double check your "
									 @"SIP account configuration in the settings.",
									 nil);
	} else {
		lMessage = [NSString stringWithFormat:NSLocalizedString(@"Cannot call %@.", nil), lUserName];
	}

	switch (linphone_call_get_reason(call)) {
		case LinphoneReasonNotFound:
			lMessage = [NSString stringWithFormat:@"%@ Not Registered", lUserName];
			break;
		case LinphoneReasonBusy:
			lMessage = [NSString stringWithFormat:@"%@ Busy", lUserName];
			break;
		default:
			if (message != nil) {
				lMessage = [NSString stringWithFormat:@"%@\nCall Error: %@", lMessage, message];
			}
			break;
	}

	lTitle = @"Call Failed";
	UIAlertView *error = [[UIAlertView alloc] initWithTitle:lTitle
													message:lMessage
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
										  otherButtonTitles:nil];
	[error show];
}

- (void)addInhibitedEvent:(id)event {
	[inhibitedEvents addObject:event];
}

- (BOOL)removeInhibitedEvent:(id)event {
	NSUInteger index = [inhibitedEvents indexOfObject:event];
	if (index != NSNotFound) {
		[inhibitedEvents removeObjectAtIndex:index];
		return TRUE;
	}
	return FALSE;
}

#pragma mark - Contact Functions

- (void)promptNewOrEdit:(NSString *)address {
    __block NSString *addr = address;
    DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:addr];
    [sheet addButtonWithTitle:@"New Contact" block:^() {
         ContactDetailsViewController *controller = DYNAMIC_CAST(
            [[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE],
            ContactDetailsViewController);
        if (controller != nil)
        {
    		// Go to Contact details view
       		[controller newContact:addr];
        }
    }];
    [sheet addButtonWithTitle:@"Add To Contact" block:^() {
        [ContactSelection setSelectionMode:ContactSelectionModeEdit];
        [ContactSelection setAddAddress:addr];
        [ContactSelection setSipFilter:nil];
        [ContactSelection setNameOrEmailFilter:nil];
        [ContactSelection enableEmailFilter:FALSE];
        ContactsViewController *controller = DYNAMIC_CAST(
            [[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription] push:TRUE],
            ContactsViewController);
        if (controller != nil) {
        }
    }];
    [sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:^{}];
    [sheet showInView:self.view];
}

#pragma mark - ActionSheet Functions

- (void)playMessageSoundForCallID:(NSString *)callID {
	if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
		LinphoneManager *lm = [LinphoneManager instance];
		// if the message was already received through a push notif, we don't need to ring
		if (![lm popPushCallID:callID]) {
			[lm playMessageSound];
		}
	}
}

- (void)displayIncomingCall:(LinphoneCall *)call {
    NSLog(@"RingMail: Display Incoming Call");
	LinphoneCallLog *callLog = linphone_call_get_call_log(call);
	NSString *callId = [NSString stringWithUTF8String:linphone_call_log_get_call_id(callLog)];

	if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
		LinphoneManager *lm = [LinphoneManager instance];
		BOOL callIDFromPush = [lm popPushCallID:callId];
		BOOL autoAnswer = [lm lpConfigBoolForKey:@"autoanswer_notif_preference"];

		if (callIDFromPush && autoAnswer) {
			// accept call automatically
			[lm acceptCall:call];

		} else {

			IncomingCallViewController *controller = nil;
			if (![currentView.name isEqualToString:[IncomingCallViewController compositeViewDescription].name]) {
				controller = DYNAMIC_CAST(
					[self changeCurrentView:[IncomingCallViewController compositeViewDescription] push:TRUE],
					IncomingCallViewController);
			} else {
				// controller is already presented, don't bother animating a transition
				controller =
					DYNAMIC_CAST([self.mainViewController getCurrentViewController], IncomingCallViewController);
			}
			AudioServicesPlaySystemSound(lm.sounds.vibrate);
            if (controller != nil) {
                [controller setCall:call];
                [controller setDelegate:self];
            }
		}
	}
}

- (void)batteryLevelChanged:(NSNotification *)notif {
	float level = [UIDevice currentDevice].batteryLevel;
	UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
	LOGD(@"Battery state:%d level:%.2f", state, level);
    
    if (! [[[LinphoneManager instance] coreReady] boolValue])
    {
        return;
    }

	LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
	if (call && linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
		LinphoneCallAppData *callData = (__bridge LinphoneCallAppData *)linphone_call_get_user_pointer(call);
		if (callData != nil) {
			if (state == UIDeviceBatteryStateUnplugged) {
				if (level <= 0.2f && !callData->batteryWarningShown) {
					LOGI(@"Battery warning");
					DTActionSheet *sheet = [[DTActionSheet alloc]
						initWithTitle:NSLocalizedString(@"Battery is running low. Stop video ?", nil)];
					[sheet addCancelButtonWithTitle:NSLocalizedString(@"Continue video", nil) block:nil];
					[sheet addDestructiveButtonWithTitle:NSLocalizedString(@"Stop video", nil)
												   block:^() {
													 LinphoneCallParams *paramsCopy = linphone_call_params_copy(
														 linphone_call_get_current_params(call));
													 // stop video
													 linphone_call_params_enable_video(paramsCopy, FALSE);
													 linphone_core_update_call([LinphoneManager getLc], call,
																			   paramsCopy);
												   }];
					[sheet showInView:self.view];
					callData->batteryWarningShown = TRUE;
				}
			}
			if (level > 0.2f) {
				callData->batteryWarningShown = FALSE;
			}
		}
	}
}

#pragma mark - IncomingCallDelegate Functions

- (void)incomingCallAborted:(LinphoneCall *)call {
}

- (void)incomingCallAccepted:(LinphoneCall *)call {
	[[LinphoneManager instance] acceptCall:call];
}

- (void)incomingCallDeclined:(LinphoneCall *)call {
	linphone_core_terminate_call([LinphoneManager getLc], call);
}


#pragma mark - Google Sign in

- (void)handleGoogleSignInStartEvent:(NSNotification *) notification {
    
    NSDictionary* userInfo = notification.userInfo;
    UIViewController* vc = (UIViewController*)userInfo[@"vc"];
    
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)handleGoogleSignInCompleteEvent {
     [self dismissViewControllerAnimated:YES completion:nil];
}

@end
