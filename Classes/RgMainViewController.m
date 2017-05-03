/* RgMainViewController.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
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

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "RgMainViewController.h"
#import "RgInCallViewController.h"
#import "DTAlertView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "UIColor+Hex.h"
#import "SendViewController.h"

#include "linphone/linphonecore.h"

#import "RgLocationManager.h"
#import "RgSearchBarViewController.h"

@interface RgMainViewController()
@property BOOL isSearchBarVisible;
@property (strong, nonatomic) RgSearchBarViewController *searchBarViewController;
@property (nonatomic, retain) IBOutlet SendViewController* sendViewController;
@end

@implementation RgMainViewController

@synthesize transferMode;
@synthesize videoPreview;
@synthesize videoCameraSwitch;
@synthesize needsRefresh;
@synthesize sendViewController;
@synthesize backgroundImageView;
@synthesize sendInfo;
@synthesize isEditing;

#pragma mark - Lifecycle Functions

- (id)init {
	NSLog(@"RgMainViewController init");
	self = [super initWithNibName:@"RgMainViewController" bundle:[NSBundle mainBundle]];
	if (self) {
		self->transferMode = FALSE;
		self->sendInfo = [NSMutableDictionary dictionaryWithDictionary:@{
			@"media": [self getMediaThumbnails:[self getLatestMedia]],
		}];
		self->isEditing = FALSE;
	}
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
		compositeDescription = [[UICompositeViewDescription alloc] init:@"RingMail"
																content:@"RgMainViewController"
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
	
	NSLog(@"RgMainViewController viewWillAppear");

	// Set observer
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callUpdateEvent:)
												 name:kLinphoneCallUpdate
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(coreUpdateEvent:)
												 name:kLinphoneCoreUpdate
											   object:nil];
    
    
    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeCard:)
                                                 name:@"RgMainCardRemove"
                                               object:nil];*/
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSegControl)
                                                 name:kRgSegmentControl
                                               object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	
	// technically not needed, but older versions of linphone had this button
	// disabled by default. In this case, updating by pushing a new version with
	// xcode would result in the callbutton being disabled all the time.
	// We force it enabled anyway now.
//	[callButton setEnabled:TRUE];
    
	// Update on show
	LinphoneManager *mgr = [LinphoneManager instance];
    if ([[mgr coreReady] boolValue])
    {
    	LinphoneCore *lc = [LinphoneManager getLc];
    	LinphoneCall *call = linphone_core_get_current_call(lc);
    	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
    	[self callUpdate:call state:state];

    	if ([LinphoneManager runningOnIpad]) {
    		BOOL videoEnabled = linphone_core_video_enabled(lc);
    		BOOL previewPref = [mgr lpConfigBoolForKey:@"preview_preference"];

    		if (videoEnabled && previewPref) {
    			linphone_core_set_native_preview_window_id(lc, (__bridge void *)(videoPreview));

    			if (!linphone_core_video_preview_enabled(lc)) {
    				linphone_core_enable_video_preview(lc, TRUE);
    			}

    			[videoCameraSwitch setHidden:FALSE];
    		} else {
    			linphone_core_set_native_preview_window_id(lc, NULL);
    			linphone_core_enable_video_preview(lc, FALSE);
    			[videoCameraSwitch setHidden:TRUE];
    		}
    	}
    }
    
    self.visible = YES;
    
    [[RgLocationManager sharedInstance] requestWhenInUseAuthorization];
    [[RgLocationManager sharedInstance] startUpdatingLocation];
    [[RgLocationManager sharedInstance] addObserver:self forKeyPath:kRgCurrentLocation options:NSKeyValueObservingOptionNew context:nil];

	// TODO: fix updating when there are new photos or videos (PHPhoto​Library​Change​Observer)
	// Code below does NOT work
	/*NSArray* update = [self getLatestMedia];
	if ([self hasNewMedia:update current:sendInfo[@"media"]])
	{
		sendInfo[@"media"] = [self getMediaThumbnails:update];
		[sendViewController setSendInfo:sendInfo];
		[sendViewController updateSend];
	}*/
}

// mrkbxt  // test incallview
//-(void)viewDidAppear:(BOOL)animated {
//    [[PhoneMainView instance] changeCurrentView:[RgInCallViewController compositeViewDescription] push:TRUE];
//}


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	// Remove observer
//	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil]; //mrkbxt - commented out to allow maincollectionview update after phone call.
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCoreUpdate object:nil];
    /*[[NSNotificationCenter defaultCenter] removeObserver:self name:@"RgMainCardRemove" object:nil];*/

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSegmentControl object:nil];
    [[RgLocationManager sharedInstance] removeObserver:self forKeyPath:kRgCurrentLocation context:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RgSegmentControl" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	
    [[RgLocationManager sharedInstance] removeObserver:self forKeyPath:@"currentLocation" context:nil];
    
    self.visible = NO;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.searchBarViewController = [[RgSearchBarViewController alloc] initWithPlaceHolder:@"Hashtag, Domain or Email"];
    self.searchBarViewController.view.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 50);
    self.isSearchBarVisible = YES;
    [self addChildViewController:self.searchBarViewController];
    [self.view addSubview:self.searchBarViewController.view];
    
    int width = [UIScreen mainScreen].applicationFrame.size.width;
    if (width == 320) {
		[backgroundImageView setImage:[UIImage imageNamed:@"explore_background_ip5p@2x.png"]];
    }
    else if (width == 375) {
		[backgroundImageView setImage:[UIImage imageNamed:@"explore_background_ip6-7s@2x.png"]];
    }
    else if (width == 414) {
		[backgroundImageView setImage:[UIImage imageNamed:@"explore_background_ip6-7p@3x.png"]];
    }

    self.searchBarViewController = [[RgSearchBarViewController alloc] initWithPlaceHolder:@"Hashtag, Domain or Email"];
    self.searchBarViewController.view.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 50);
    self.isSearchBarVisible = YES;
    [self addChildViewController:self.searchBarViewController];
    [self.view addSubview:self.searchBarViewController.view];
    
    [self setNeedsRefresh:NO]; // Remove this?
    
    UITapGestureRecognizer* tapBackground = [[UITapGestureRecognizer alloc] initWithTarget:self.searchBarViewController action:@selector(dismissKeyboard:)];
    [tapBackground setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapBackground];

	if ([LinphoneManager runningOnIpad]) {
		if ([LinphoneManager instance].frontCamId != nil) {
			// only show camera switch button if we have more than 1 camera
			[videoCameraSwitch setHidden:FALSE];
		}
	}
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mainRefreshEvent:)
                                                 name:kRgTextReceived
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mainRefreshEvent:)
                                                 name:kRgTextUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mainRefreshEvent:)
                                                 name:kRgMainRefresh
                                               object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeCard:)
                                                 name:kRgMainRemove
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mainRefreshEvent:)
                                                 name:kRgContactRefresh
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mainRefreshEvent:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUserActivity)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
	
	[sendViewController setSendInfo:sendInfo];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSetAddress object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgTextReceived object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgTextUpdate object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgMainRefresh object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgContactRefresh object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

/*- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	CGRect frame = [videoPreview frame];
	switch (toInterfaceOrientation) {
	case UIInterfaceOrientationPortrait:
		[videoPreview setTransform:CGAffineTransformMakeRotation(0)];
		break;
	case UIInterfaceOrientationPortraitUpsideDown:
		[videoPreview setTransform:CGAffineTransformMakeRotation(M_PI)];
		break;
	case UIInterfaceOrientationLandscapeLeft:
		[videoPreview setTransform:CGAffineTransformMakeRotation(M_PI / 2)];
		break;
	case UIInterfaceOrientationLandscapeRight:
		[videoPreview setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
		break;
	default:
		break;
	}
	[videoPreview setFrame:frame];
}*/

#pragma mark - Event Functions

- (void)callUpdateEvent:(NSNotification *)notif {
	LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
	[self callUpdate:call state:state];
}

- (void)coreUpdateEvent:(NSNotification *)notif {
	if ([LinphoneManager runningOnIpad]) {
		LinphoneCore *lc = [LinphoneManager getLc];
		if (linphone_core_video_enabled(lc) && linphone_core_video_preview_enabled(lc)) {
			linphone_core_set_native_preview_window_id(lc, (__bridge void *)(videoPreview));
			[videoCameraSwitch setHidden:FALSE];
		} else {
			linphone_core_set_native_preview_window_id(lc, NULL);
			[videoCameraSwitch setHidden:TRUE];
		}
	}
}


- (void)mainRefreshEvent:(NSNotification *)notif {
    if (self.visible)
    {
        LOGI(@"RingMail: Updating Main Card List 2");
        //[mainViewController updateCollection];
    }
    else
    {
        [self setNeedsRefresh:YES];
    }
}

- (void)removeCard:(NSNotification *)notif {
	[[[LinphoneManager instance] chatManager] dbHideSession:notif.userInfo[@"id"]];
	//[mainViewController updateCollection];
}

#pragma mark - Debug Functions
- (void)presentMailViewWithTitle:(NSString *)subject forRecipients:(NSArray *)recipients attachLogs:(BOOL)attachLogs {
	if ([MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
		if (controller) {
			controller.mailComposeDelegate = self;
			[controller setSubject:subject];
			[controller setToRecipients:recipients];

			if (attachLogs) {
				char *filepath = linphone_core_compress_log_collection();
				if (filepath == NULL) {
					LOGE(@"Cannot sent logs: file is NULL");
					return;
				}

				NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
				NSString *filename = [appName stringByAppendingString:@".gz"];
				NSString *mimeType = @"text/plain";

				if ([filename hasSuffix:@".gz"]) {
					mimeType = @"application/gzip";
					filename = [appName stringByAppendingString:@".gz"];
				} else {
					LOGE(@"Unknown extension type: %@, cancelling email", filename);
					return;
				}
				[controller setMessageBody:NSLocalizedString(@"Application logs", nil) isHTML:NO];
				[controller addAttachmentData:[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:filepath]]
									 mimeType:mimeType
									 fileName:filename];

				ms_free(filepath);
			}
			self.modalPresentationStyle = UIModalPresentationPageSheet;
			[self.view.window.rootViewController presentViewController:controller
															  animated:TRUE
															completion:^{
															}];
		}

	} else {
		UIAlertView *alert =
			[[UIAlertView alloc] initWithTitle:subject
									   message:NSLocalizedString(@"Error: no mail account configured", nil)
									  delegate:nil
							 cancelButtonTitle:NSLocalizedString(@"OK", nil)
							 otherButtonTitles:nil];
		[alert show];
	}
}

- (BOOL)displayDebugPopup:(NSString *)address {
	LinphoneManager *mgr = [LinphoneManager instance];
	NSString *debugAddress = [mgr lpConfigStringForKey:@"debug_popup_magic" withDefault:@""];
	if (![debugAddress isEqualToString:@""] && [address isEqualToString:debugAddress]) {

		DTAlertView *alertView = [[DTAlertView alloc] initWithTitle:NSLocalizedString(@"Debug", nil)
															message:NSLocalizedString(@"Choose an action", nil)];

		[alertView addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];

		[alertView
			addButtonWithTitle:NSLocalizedString(@"Send logs", nil)
						 block:^{
						   NSString *appName =
							   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
						   NSString *logsAddress =
							   [mgr lpConfigStringForKey:@"debug_popup_email" withDefault:@"linphone-ios@linphone.org"];
						   [self presentMailViewWithTitle:appName forRecipients:@[ logsAddress ] attachLogs:true];
						 }];

		BOOL debugEnabled = [[LinphoneManager instance] lpConfigBoolForKey:@"debugenable_preference"];
		NSString *actionLog =
			(debugEnabled ? NSLocalizedString(@"Disable logs", nil) : NSLocalizedString(@"Enable logs", nil));
		[alertView addButtonWithTitle:actionLog
								block:^{
								  // enable / disable
								  BOOL enableDebug = ![mgr lpConfigBoolForKey:@"debugenable_preference"];
								  [mgr lpConfigSetBool:enableDebug forKey:@"debugenable_preference"];
								  [mgr setLogsEnabled:enableDebug];
								}];

		[alertView show];
		return true;
	}
	return false;
}

#pragma mark -

- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state {
    //NSLog(@"RingMail: %s", __PRETTY_FUNCTION__);
}


- (void)setTransferMode:(BOOL)atransferMode {
	transferMode = atransferMode;
	LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
	[self callUpdate:call state:state];
}


#pragma mark - MFComposeMailDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error {
	[controller dismissViewControllerAnimated:TRUE
								   completion:^{
								   }];
	[self.navigationController setNavigationBarHidden:TRUE animated:FALSE];
}

#pragma mark - Action Functions

- (IBAction)onAddContactClick:(id)event {
	[ContactSelection setSelectionMode:ContactSelectionModeEdit];
	[ContactSelection setSipFilter:nil];
	[ContactSelection setNameOrEmailFilter:nil];
	[ContactSelection enableEmailFilter:FALSE];
	ContactsViewController *controller = DYNAMIC_CAST(
		[[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription] push:TRUE],
		ContactsViewController);
	if (controller != nil) {
	}
}

- (void)handleUserActivity {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    //    NSString *msgContactIDString = @"51";  // test mike as recip
    NSString *msgContactIDString = [defaults stringForKey:@"msgContactID"];
    NSString *callContactIDString = [defaults stringForKey:@"callContactID"];

    if (![msgContactIDString isEqual: @""]) {
        
        [defaults setObject:@"" forKey:@"msgContactID"];
    
        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        NSNumber *contactID = [nf numberFromString:msgContactIDString];
        
        ABRecordRef contact;
        contact = [[[LinphoneManager instance] fastAddressBook] getContactById:contactID];
        NSString *rgAddress = [[[LinphoneManager instance] contactManager] getRingMailAddress:contact];
        
        if (rgAddress != nil)
        {
            NSDictionary *sessionData = [[[LinphoneManager instance] chatManager] dbGetSessionID:rgAddress to:nil contact:contactID uuid:nil];
            [[LinphoneManager instance] setChatSession:sessionData[@"id"]];
            [[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE];
        }
    }
    
    if (![callContactIDString isEqual: @""]) {
        
        [defaults setObject:@"" forKey:@"callContactID"];
        
        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        NSNumber *contactID = [nf numberFromString:callContactIDString];
        
        ABRecordRef contact;
        contact = [[[LinphoneManager instance] fastAddressBook] getContactById:contactID];
        
        NSString *rgAddress = [[[LinphoneManager instance] contactManager] getRingMailAddress:contact];
        
        if (rgAddress != nil)
            [RgManager startCall:rgAddress contact:contact video:NO];
        
    }
}

- (void)handleSegControl {
    printf("rgmain segement controller hit\n");
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object  change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:kRgCurrentLocation])
        [[RgLocationManager sharedInstance] stopUpdatingLocation];
}

#pragma mark - Keyboard Events

- (void)keyboardWillShow:(NSNotification*)event
{
	self.isEditing = YES;
}

- (void)keyboardWillHide:(NSNotification*)event
{
	self.isEditing = NO;
}

#pragma mark - Tap Recognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (self.isEditing)
	{
        UITouch *touch = [touches anyObject];
        if (![touch.view isMemberOfClass:[UITextField class]])
    	{
    		[touch.view endEditing:YES];
        }
	}
}

#pragma mark - Photos & Videos

- (BOOL)hasNewMedia:(NSArray*)media current:(NSArray*)prev
{
	if ([prev count] == 0)
	{
		if ([media count] > 0)
		{
			return YES;
		}
		else
		{
			return NO;
		}
	}
	else if ([media count] > 0 && [prev count] > 0)
	{
		NSString* item1 = [(PHAsset*)media[0][@"asset"] localIdentifier];
		NSString* item2 = [(PHAsset*)prev[0][@"asset"] localIdentifier];
		if ([item1 isEqualToString:item2])
		{
			return NO;
		}
		else
		{
			return YES;
		}
	}
	else
	{
		return NO; // Both empty
	}
}

- (NSArray*)getLatestMedia
{
    // load recent media
    int max = 25;
    int count = 0;
    NSMutableArray *assets = [NSMutableArray new];
    PHFetchOptions *mainopts = [[PHFetchOptions alloc] init];
    mainopts.sortDescriptors = @[
    	[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:NO],
    ];
    PHFetchResult *collects = [PHAssetCollection fetchMomentsWithOptions:mainopts];
    for (PHAssetCollection *collection in collects)
    {
    	//NSLog(@"Collection(%@): %@", collection.localizedTitle, collection);
    	PHFetchOptions *opts = [[PHFetchOptions alloc] init];
    	opts.fetchLimit = max;
    	opts.sortDescriptors = @[
    		[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
        ];
    	PHFetchResult *fr = [PHAsset fetchAssetsInAssetCollection:collection options:opts];
        for (PHAsset *asset in fr)
    	{
    		if (count < max)
    		{
    			[assets addObject:@{@"asset": asset}];
    			count++;
    		}
        }
    	if (count == max)
    	{
    		break;
    	}
    }
    [assets sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
    	return [[(PHAsset*)obj2[@"asset"] creationDate] compare:[(PHAsset*)obj1[@"asset"] creationDate]];
    }];
    //NSLog(@"Latest Media: %@", assets);
	return assets;
}

- (NSArray*)getMediaThumbnails:(NSArray*)media
{
	__block NSMutableArray* res = [NSMutableArray new];
	PHImageManager* imageManager = [PHImageManager defaultManager];
	PHImageRequestOptions* opts = [PHImageRequestOptions new];
	opts.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
	opts.resizeMode = PHImageRequestOptionsResizeModeExact;
	opts.synchronous = YES;
	for (NSDictionary* item in media)
	{
		[imageManager requestImageForAsset:item[@"asset"] targetSize:CGSizeMake(142, 142) contentMode:PHImageContentModeAspectFill options:opts resultHandler:^(UIImage* image, NSDictionary* info){
			[res addObject:@{
				@"asset": item[@"asset"],
				@"thumbnail": image,
			}];
		}];
	}
	return res;
}

- (void)addMedia:(NSDictionary*)param
{
	[sendViewController addMedia:param];
}

@end
