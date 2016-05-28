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

#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>

#import "RgScanViewController.h"
#import "RgMainViewController.h"
#import "RgInCallViewController.h"
#import "DTAlertView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "UIColor+Hex.h"

#include "linphone/linphonecore.h"

@implementation RgMainViewController

@synthesize transferMode;

@synthesize addressField;
@synthesize addContactButton;
@synthesize backButton;
@synthesize addCallButton;
@synthesize transferButton;
@synthesize callButton;
@synthesize goButton;
@synthesize messageButton;
@synthesize eraseButton;

@synthesize backgroundView;
@synthesize videoPreview;
@synthesize videoCameraSwitch;
//@synthesize mainController;
@synthesize mainView;
@synthesize mainViewController;
@synthesize needsRefresh;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"RgMainViewController" bundle:[NSBundle mainBundle]];
	if (self) {
		self->transferMode = FALSE;
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
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Dialer"
																content:@"RgMainViewController"
															   stateBar:@"UIStateBar"
														stateBarEnabled:true
																 tabBar:@"UIMainBar"
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// Set observer
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callUpdateEvent:)
												 name:kLinphoneCallUpdate
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(coreUpdateEvent:)
												 name:kLinphoneCoreUpdate
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mainRefreshEvent:)
                                                 name:kRgTextReceived
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mainRefreshEvent:)
                                                 name:kLinphoneCallUpdate
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
                                         selector:@selector(setAddressEvent:)
                                             name:kRgSetAddress
                                           object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeCard:)
                                                 name:@"RgMainCardRemove"
                                               object:nil];
    
	// technically not needed, but older versions of linphone had this button
	// disabled by default. In this case, updating by pushing a new version with
	// xcode would result in the callbutton being disabled all the time.
	// We force it enabled anyway now.
	[callButton setEnabled:TRUE];

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

    			[backgroundView setHidden:FALSE];
    			[videoCameraSwitch setHidden:FALSE];
    		} else {
    			linphone_core_set_native_preview_window_id(lc, NULL);
    			linphone_core_enable_video_preview(lc, FALSE);
    			[backgroundView setHidden:TRUE];
    			[videoCameraSwitch setHidden:TRUE];
    		}
    	}
    }

	// fix placeholder bar color in >= iOS7
    NSString *intro = @" Enter #Hashtag or Email";
	NSAttributedString *placeHolderString = [[NSAttributedString alloc] initWithString:intro
										attributes:@{NSForegroundColorAttributeName:[UIColor colorWithHex:@"#5b5d58"]}];
	addressField.attributedPlaceholder = placeHolderString;
    
    if ([self needsRefresh])
    {
        [mainViewController updateCollection];
        [self setNeedsRefresh:NO];
    }
    
    self.visible = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	// Remove observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCoreUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RgMainCardRemove" object:nil];
    
    self.visible = NO;
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:0];
    
    MainCollectionViewController *mainController = [[MainCollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
    
    [[mainController collectionView] setBounces:YES];
    [[mainController collectionView] setAlwaysBounceVertical:YES];
    
    CGRect r = mainView.frame;
    r.origin.y = 0;
    [mainController.view setFrame:r];
    [mainView addSubview:mainController.view];
    [self addChildViewController:mainController];
    [mainController didMoveToParentViewController:self];
    mainViewController = mainController;
    [self setNeedsRefresh:NO];
    
	[addressField setText:@""];
	[addressField setAdjustsFontSizeToFitWidth:TRUE]; // Not put it in IB: issue with placeholder size
    UITapGestureRecognizer* tapBackground = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard:)];
    [tapBackground setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapBackground];

	if ([LinphoneManager runningOnIpad]) {
		if ([LinphoneManager instance].frontCamId != nil) {
			// only show camera switch button if we have more than 1 camera
			[videoCameraSwitch setHidden:FALSE];
		}
	}
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSetAddress object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgTextReceived object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgTextUpdate object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgMainRefresh object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
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
}

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
			[backgroundView setHidden:FALSE];
			[videoCameraSwitch setHidden:FALSE];
		} else {
			linphone_core_set_native_preview_window_id(lc, NULL);
			[backgroundView setHidden:TRUE];
			[videoCameraSwitch setHidden:TRUE];
		}
	}
}

- (void)setAddressEvent:(NSNotification *)notif
{
    NSString *newAddress = [notif.userInfo objectForKey:@"address"];
    NSLog(@"RingMail - Set Address Event: %@", newAddress);
    [addressField setText:newAddress];
    if ([newAddress length] > 0 && [[newAddress substringToIndex:1] isEqualToString:@"#"])
    {
        messageButton.hidden = YES;
        callButton.hidden = YES;
        goButton.hidden = NO;
    }
    else
    {
        messageButton.hidden = NO;
        callButton.hidden = NO;
        goButton.hidden = YES;
    }
}

- (void)mainRefreshEvent:(NSNotification *)notif {
    if (self.visible)
    {
        [mainViewController updateCollection];
    }
    else
    {
        [self setNeedsRefresh:YES];
    }
}

- (void)removeCard:(NSNotification *)notif{
    [mainViewController removeCard:notif.userInfo[@"index"]];
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
    
	LinphoneCore *lc = [LinphoneManager getLc];
	if (linphone_core_get_calls_nb(lc) > 0) {
		if (transferMode) {
			[addCallButton setHidden:true];
			[transferButton setHidden:false];
		} else {
			[addCallButton setHidden:false];
			[transferButton setHidden:true];
		}
		//[callButton setHidden:true];
		[backButton setHidden:false];
		[addContactButton setHidden:true];
	} else {
		[addCallButton setHidden:true];
		//[callButton setHidden:false];
		[backButton setHidden:true];
		[addContactButton setHidden:false];
		[transferButton setHidden:true];
	}
}

- (void)setAddress:(NSString *)address {
	[addressField setText:address];
}

- (void)setTransferMode:(BOOL)atransferMode {
	transferMode = atransferMode;
	LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
	[self callUpdate:call state:state];
}

- (void)call:(NSString *)address {
	NSString *displayName = nil;
	ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
	if (contact) {
		displayName = [FastAddressBook getContactDisplayName:contact];
	}
	[self call:address displayName:displayName];
}

- (void)call:(NSString *)address displayName:(NSString *)displayName {
	[[LinphoneManager instance] call:address displayName:displayName transfer:transferMode];
}

#pragma mark - UITextFieldDelegate Functions

/*- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
	//[textField performSelector:@selector() withObject:nil afterDelay:0];
	return YES;
}*/

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == addressField) {
		[addressField resignFirstResponder];
	}
	return YES;
}

#pragma mark - Text Field Functions

-(void) dismissKeyboard:(id)sender
{
    //[addressField resignFirstResponder];
    [self.view endEditing:YES];
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
	[ContactSelection setAddAddress:[addressField text]];
	[ContactSelection setSipFilter:nil];
	[ContactSelection setNameOrEmailFilter:nil];
	[ContactSelection enableEmailFilter:FALSE];
	ContactsViewController *controller = DYNAMIC_CAST(
		[[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription] push:TRUE],
		ContactsViewController);
	if (controller != nil) {
	}
}

- (IBAction)onBackClick:(id)event {
	[[PhoneMainView instance] changeCurrentView:[RgInCallViewController compositeViewDescription]];
}

- (IBAction)onAddressChange:(id)sender {
	if ([self displayDebugPopup:self.addressField.text]) {
		self.addressField.text = @"";
	}
	if ([[addressField text] length] > 0) {
		[addContactButton setEnabled:TRUE];
		[eraseButton setEnabled:TRUE];
		[addCallButton setEnabled:TRUE];
		[transferButton setEnabled:TRUE];
        NSString* addr = [addressField text];
        if ([[addr substringToIndex:1] isEqualToString:@"#"])
        {
            messageButton.hidden = YES;
            callButton.hidden = YES;
            goButton.hidden = NO;
        }
        else
        {
            messageButton.hidden = NO;
            callButton.hidden = NO;
            goButton.hidden = YES;
        }
	} else {
		[addContactButton setEnabled:FALSE];
		[eraseButton setEnabled:FALSE];
		[addCallButton setEnabled:FALSE];
		[transferButton setEnabled:FALSE];
        messageButton.hidden = YES;
        callButton.hidden = YES;
        goButton.hidden = YES;
	}
}

- (IBAction)onScan:(id)sender {
    RgScanViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[RgScanViewController compositeViewDescription] push:TRUE], RgScanViewController);
    if (controller != nil)
    {
        [controller beginScan];
    }
}

@end
