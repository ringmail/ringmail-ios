/* InCallViewController.h
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

#import <AudioToolbox/AudioToolbox.h>
#import <AddressBook/AddressBook.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#import "RgInCallViewController.h"
#import "UICallCell.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UILinphone.h"
#import "DTActionSheet.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"

#include "linphone/linphonecore.h"

//const NSInteger SECURE_BUTTON_TAG = 5;

@implementation RgInCallViewController {
	BOOL hiddenVolume;
}

@synthesize videoGroup;
@synthesize videoView;
@synthesize videoPreview;
@synthesize videoCameraSwitch;
@synthesize videoWaitingForFirstImage;
#ifdef TEST_VIDEO_VIEW_CHANGE
@synthesize testVideoView;
#endif

@synthesize addressLabel;
@synthesize avatarImage;
@synthesize callData;
@synthesize callViewController;

@synthesize padView;
@synthesize padActive;
@synthesize oneButton;
@synthesize twoButton;
@synthesize threeButton;
@synthesize fourButton;
@synthesize fiveButton;
@synthesize sixButton;
@synthesize sevenButton;
@synthesize eightButton;
@synthesize nineButton;
@synthesize starButton;
@synthesize zeroButton;
@synthesize sharpButton;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"RgInCallViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		self->singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showControls:)];
		self->videoZoomHandler = [[VideoZoomHandler alloc] init];
		self->callData = [NSMutableDictionary dictionary];
		self->padActive = [NSNumber numberWithBool:NO];
	}
	return self;
}

- (void)dealloc {
	[[PhoneMainView instance].view removeGestureRecognizer:singleFingerTap];

	// Remove all observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"InCall"
																content:@"RgInCallViewController"
															   stateBar:@"UIStateBar"
														stateBarEnabled:true
																 tabBar:nil
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:true
														   portraitMode:true];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	UIDevice *device = [UIDevice currentDevice];
	device.proximityMonitoringEnabled = YES;

	[[PhoneMainView instance] setVolumeHidden:TRUE];
	hiddenVolume = TRUE;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (hideControlsTimer != nil) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	if (hiddenVolume) {
		[[PhoneMainView instance] setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}

	// Remove observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgToggleNumberPad object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgCallRefresh object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	// Set observer
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callUpdateEvent:)
												 name:kLinphoneCallUpdate
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(toggleNumberPad:)
												 name:kRgToggleNumberPad
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callRefreshEvent:)
												 name:kRgCallRefresh
											   object:nil];

	// Update on show
	LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
	[self callUpdate:call state:state animated:FALSE];

	// Set windows (warn memory leaks)
	linphone_core_set_native_video_window_id([LinphoneManager getLc], (__bridge void *)(videoView));
	linphone_core_set_native_preview_window_id([LinphoneManager getLc], (__bridge void *)(videoPreview));

	// Enable tap
	[singleFingerTap setEnabled:TRUE];
	
	[padView setHidden:YES];
	padActive = @NO;
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	[[UIApplication sharedApplication] setIdleTimerDisabled:false];
	UIDevice *device = [UIDevice currentDevice];
	device.proximityMonitoringEnabled = NO;

	[[PhoneMainView instance] fullScreen:false];
	// Disable tap
	[singleFingerTap setEnabled:FALSE];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[singleFingerTap setNumberOfTapsRequired:1];
	[singleFingerTap setCancelsTouchesInView:FALSE];
	[[PhoneMainView instance].view addGestureRecognizer:singleFingerTap];

	[videoZoomHandler setup:videoGroup];
	videoGroup.alpha = 0;

	[videoCameraSwitch setPreview:videoPreview];

	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideVideoPreview:)];
	tap.numberOfTapsRequired = 1;
	[self.videoPreview addGestureRecognizer:tap];
	
	[zeroButton setDigit:'0'];
	[zeroButton setDtmf:true];
	[oneButton setDigit:'1'];
	[oneButton setDtmf:true];
	[twoButton setDigit:'2'];
	[twoButton setDtmf:true];
	[threeButton setDigit:'3'];
	[threeButton setDtmf:true];
	[fourButton setDigit:'4'];
	[fourButton setDtmf:true];
	[fiveButton setDigit:'5'];
	[fiveButton setDtmf:true];
	[sixButton setDigit:'6'];
	[sixButton setDtmf:true];
	[sevenButton setDigit:'7'];
	[sevenButton setDtmf:true];
	[eightButton setDigit:'8'];
	[eightButton setDtmf:true];
	[nineButton setDigit:'9'];
	[nineButton setDtmf:true];
	[starButton setDigit:'*'];
	[starButton setDtmf:true];
	[sharpButton setDigit:'#'];
	[sharpButton setDtmf:true];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[PhoneMainView instance].view removeGestureRecognizer:singleFingerTap];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
	//[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	// in mode display_filter_auto_rotate=0, no need to rotate the preview
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	//[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	//[self previewTouchLift];
}

#pragma mark -

- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated {
	LinphoneCore *lc = [LinphoneManager getLc];

	if (hiddenVolume) {
		[[PhoneMainView instance] setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}
	
	// RingMail: Update call data
	if ([RgInCallViewController callCount:lc] > 0)
	{
		LinphoneCall *call = [RgInCallViewController retrieveCallAtIndex:0]; // First call only
		const LinphoneAddress *addr = linphone_call_get_remote_address(call);
		if (addr != NULL)
		{
			char *lAddress = linphone_address_as_string_uri_only(addr);
			if (lAddress)
			{
				NSString *address = [RgManager addressFromSIP:[NSString stringWithUTF8String:lAddress]];
				ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
				NSString *name = [address copy];
				if (contact)
				{
					name = [FastAddressBook getContactDisplayName:contact];
				}
                NSNumber *video = [NSNumber numberWithBool:NO];
                LinphoneCallAppData *data = (__bridge LinphoneCallAppData *)linphone_call_get_user_data(call);
                if (data)
                {
					if (data->videoRequested)
                    {
                        video = [NSNumber numberWithBool:YES];
                    }
				}
				callData = [NSMutableDictionary dictionaryWithDictionary:@{
					@"address": address,
					@"label": name,
					@"speaker": [NSNumber numberWithBool:[[LinphoneManager instance] speakerEnabled]],
					@"mute": [NSNumber numberWithBool:linphone_core_is_mic_muted(lc)],
					@"dialpad": padActive,
                    @"video": video,
				}];
				[callViewController updateCall:callData];
				ms_free(lAddress);
			}
		}
	}

	// Update table
	//[callTableView reloadData];

	// Fake call update
	if (call == NULL) {
		return;
	}

	switch (state) {
	case LinphoneCallIncomingReceived:
	case LinphoneCallOutgoingInit: {
		if (linphone_core_get_calls_nb(lc) > 1) {
			//[callTableController minimizeAll];
		}
	}
	case LinphoneCallConnected:
	case LinphoneCallStreamsRunning: {
		// check video
		if (linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
			//NSLog(@"RingMail - Video Enabled: 1");
			[self displayVideoCall:animated];
		} else {
			//NSLog(@"RingMail - Video Enabled: 0");
			[self displayTableCall:animated];
			const LinphoneCallParams *param = linphone_call_get_current_params(call);
			const LinphoneCallAppData *callAppData =
				(__bridge const LinphoneCallAppData *)(linphone_call_get_user_pointer(call));
			if (state == LinphoneCallStreamsRunning && callAppData->videoRequested &&
				linphone_call_params_low_bandwidth_enabled(param)) {
				// too bad video was not enabled because low bandwidth
				UIAlertView *alert = [[UIAlertView alloc]
						initWithTitle:NSLocalizedString(@"Low bandwidth", nil)
							  message:NSLocalizedString(@"Video cannot be activated because of low bandwidth "
														@"condition, only audio is available",
														nil)
							 delegate:nil
					cancelButtonTitle:NSLocalizedString(@"Continue", nil)
					otherButtonTitles:nil];
				[alert show];
				callAppData->videoRequested = FALSE; /*reset field*/
			}
		}
		break;
	}
	case LinphoneCallUpdatedByRemote: {
		const LinphoneCallParams *current = linphone_call_get_current_params(call);
		const LinphoneCallParams *remote = linphone_call_get_remote_params(call);

		/* remote wants to add video */
		if (linphone_core_video_enabled(lc) && !linphone_call_params_video_enabled(current) &&
			linphone_call_params_video_enabled(remote) && !linphone_core_get_video_policy(lc)->automatically_accept) {
			linphone_core_defer_call_update(lc, call);
			[self displayAskToEnableVideoCall:call];
		} else if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
			[self displayTableCall:animated];
		}
		break;
	}
	case LinphoneCallPausing:
	case LinphoneCallPaused:
	case LinphoneCallPausedByRemote: {
		[self displayTableCall:animated];
		break;
	}
	case LinphoneCallEnd:
	case LinphoneCallError: {
		if (linphone_core_get_calls_nb(lc) <= 2 && !videoShown) {
			//[callTableController maximizeAll];
		}
		break;
	}
	default:
		break;
	}
}

- (void)showControls:(id)sender {
	if (hideControlsTimer) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	if ([[[PhoneMainView instance] currentView] equal:[RgInCallViewController compositeViewDescription]] && videoShown) {
		// show controls
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[[PhoneMainView instance] showTabBar:true];
		[[PhoneMainView instance] showStateBar:true];
		//[videoCameraSwitch setAlpha:1.0];
		[UIView commitAnimations];

		// hide controls in 5 sec
		hideControlsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
															 target:self
														   selector:@selector(hideControls:)
														   userInfo:nil
															repeats:NO];
	}
}

- (void)hideControls:(id)sender {
	if (hideControlsTimer) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	if ([[[PhoneMainView instance] currentView] equal:[RgInCallViewController compositeViewDescription]] && videoShown) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		//[videoCameraSwitch setAlpha:0.0];
		[UIView commitAnimations];

		[[PhoneMainView instance] showTabBar:false];
		[[PhoneMainView instance] showStateBar:false];
	}
}

#ifdef TEST_VIDEO_VIEW_CHANGE
// Define TEST_VIDEO_VIEW_CHANGE in IncallViewController.h to enable video view switching testing
- (void)_debugChangeVideoView {
	static bool normalView = false;
	if (normalView) {
		linphone_core_set_native_video_window_id([LinphoneManager getLc], (unsigned long)videoView);
	} else {
		linphone_core_set_native_video_window_id([LinphoneManager getLc], (unsigned long)testVideoView);
	}
	normalView = !normalView;
}
#endif

- (void)enableVideoDisplay:(BOOL)animation {
	if (videoShown && animation)
		return;

	// Setup video contact bar
	LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
	if (call != NULL)
	{
		const LinphoneAddress *addr = linphone_call_get_remote_address(call);
		if (addr != NULL)
		{
			char *lAddress = linphone_address_as_string_uri_only(addr);
			if (lAddress)
			{
				NSString *displayName = [RgManager addressFromSIP:[NSString stringWithUTF8String:lAddress]];
				UIImage *image = nil;
				ABRecordRef acontact = [[[LinphoneManager instance] fastAddressBook] getContact:displayName];
				if (acontact != nil) {
					displayName = [FastAddressBook getContactDisplayName:acontact];
					image = [FastAddressBook getContactImage:acontact thumbnail:NO];
				}
				addressLabel.text = displayName;
				addressLabel.accessibilityValue = displayName;

				if (image == nil) {
					image = [UIImage imageNamed:@"avatar_unknown_small.png"];
				}

				image = [image thumbnailImage:140 transparentBorder:0 cornerRadius:70 interpolationQuality:kCGInterpolationHigh];
				[avatarImage setImage:image];
			}
		}
	}

	videoShown = true;
	[videoZoomHandler resetZoom];

	if (animation) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:1.0];
	}

	[videoGroup setHidden:NO];
	[videoGroup setAlpha:1.0];

	if (animation) {
		[UIView commitAnimations];
	}
	
	[callViewController removeCallView];

	if (linphone_core_self_view_enabled([LinphoneManager getLc])) {
		[videoPreview setHidden:FALSE];
		//[videoCameraSwitch setHidden:FALSE];
	} else {
		[videoPreview setHidden:TRUE];
		//[videoCameraSwitch setHidden:TRUE];
	}

	/*if ([LinphoneManager instance].frontCamId != nil) {
		// only show camera switch button if we have more than 1 camera
		[videoCameraSwitch setHidden:FALSE];
	}
	[videoCameraSwitch setAlpha:0.0];*/

	[[PhoneMainView instance] fullScreen:true];
	[[PhoneMainView instance] showTabBar:false];
	[[PhoneMainView instance] showStateBar:false];

#ifdef TEST_VIDEO_VIEW_CHANGE
	[NSTimer scheduledTimerWithTimeInterval:5.0
									 target:self
								   selector:@selector(_debugChangeVideoView)
								   userInfo:nil
									repeats:YES];
#endif
	// [self batteryLevelChanged:nil];

	[videoWaitingForFirstImage setHidden:NO];
	[videoWaitingForFirstImage startAnimating];

	// linphone_call_params_get_used_video_codec return 0 if no video stream enabled
	if (call != NULL && linphone_call_params_get_used_video_codec(linphone_call_get_current_params(call))) {
		linphone_call_set_next_video_frame_decoded_callback(call, hideSpinner, (__bridge void *)(self));
	}
}

- (void)disableVideoDisplay:(BOOL)animation {
	if (!videoShown && animation)
		return;
	
	[videoGroup setHidden:YES];

	videoShown = false;
	if (animation) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:1.0];
	}

	[videoGroup setAlpha:0.0];
	[[PhoneMainView instance] showTabBar:true];
	//[videoCameraSwitch setHidden:TRUE];

	if (animation) {
		[UIView commitAnimations];
	}

	if (hideControlsTimer != nil) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	[[PhoneMainView instance] fullScreen:false];
}

- (void)displayVideoCall:(BOOL)animated {
	[self enableVideoDisplay:animated];
}

- (void)displayTableCall:(BOOL)animated {
	[self disableVideoDisplay:animated];
}

#pragma mark - Spinner Functions

- (void)hideSpinnerIndicator:(LinphoneCall *)call {
	videoWaitingForFirstImage.hidden = TRUE;
}

static void hideSpinner(LinphoneCall *call, void *user_data) {
	RgInCallViewController *thiz = (__bridge RgInCallViewController *)user_data;
	[thiz hideSpinnerIndicator:call];
}

#pragma mark - Event Functions

- (void)callUpdateEvent:(NSNotification *)notif
{
	LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
	[self callUpdate:call state:state animated:TRUE];
}

- (void)callRefreshEvent:(NSNotification *)notif
{
	[callData setObject:[NSNumber numberWithBool:[[LinphoneManager instance] speakerEnabled]] forKey:@"speaker"];
	[callData setObject:[NSNumber numberWithBool:linphone_core_is_mic_muted([LinphoneManager getLc])] forKey:@"mute"];
	[callData setObject:padActive forKey:@"dialpad"];
	[callViewController updateCall:callData];
}

- (void)toggleNumberPad:(NSNotification *)notif
{
	if ([padView isHidden])
	{
		padActive = @YES;
		[padView setAlpha:0.0f];
		[padView setHidden:NO];
		[UIView animateWithDuration:0.5f animations:^{
			[padView setAlpha:1.0f];
		} completion:^(BOOL finished) {
		}];

    }
	else
	{
		padActive = @NO;
		[UIView animateWithDuration:0.5f animations:^{
			[padView setAlpha:0.0f];
		} completion:^(BOOL finished) {
			[padView setHidden:YES];
		}];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:kRgCallRefresh object:nil];
}

- (void)callRefreshTimer
{
	if ([RgInCallViewController callCount:[LinphoneManager getLc]] > 0)
	{
		LinphoneCall *call = [RgInCallViewController retrieveCallAtIndex:0];
		int duration = linphone_call_get_duration(call);
		[callData setObject:[NSString stringWithFormat:@"%02i:%02i:%02i", (duration / 3600), (duration / 60), (duration % 60), nil] forKey:@"duration"];
		[callViewController updateCall:callData];
	}
}


#pragma mark - ActionSheet Functions

- (void)displayAskToEnableVideoCall:(LinphoneCall *)call {
	if (linphone_core_get_video_policy([LinphoneManager getLc])->automatically_accept)
		return;

	const char *lUserNameChars = linphone_address_get_username(linphone_call_get_remote_address(call));
    NSString *lUserName = [[NSString alloc] initWithUTF8String:lUserNameChars];
    NSString *lDisplayName = [RgManager addressFromSIPUser:lUserName];
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"'%@' would like to enable video", nil), lDisplayName];
	DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:title];
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:30
													  target:self
													selector:@selector(dismissVideoActionSheet:)
													userInfo:sheet
													 repeats:NO];
	[sheet addButtonWithTitle:NSLocalizedString(@"Accept", nil)
						block:^() {
						  LOGI(@"User accept video proposal");
						  LinphoneCallParams *paramsCopy =
							  linphone_call_params_copy(linphone_call_get_current_params(call));
						  linphone_call_params_enable_video(paramsCopy, TRUE);
						  linphone_core_accept_call_update([LinphoneManager getLc], call, paramsCopy);
						  linphone_call_params_destroy(paramsCopy);
						  [timer invalidate];
						}];
	DTActionSheetBlock cancelBlock = ^() {
	  LOGI(@"User declined video proposal");
	  LinphoneCallParams *paramsCopy = linphone_call_params_copy(linphone_call_get_current_params(call));
	  linphone_core_accept_call_update([LinphoneManager getLc], call, paramsCopy);
	  linphone_call_params_destroy(paramsCopy);
	  [timer invalidate];
	};
	[sheet addDestructiveButtonWithTitle:NSLocalizedString(@"Decline", nil) block:cancelBlock];
	if ([LinphoneManager runningOnIpad]) {
		[sheet addCancelButtonWithTitle:NSLocalizedString(@"Decline", nil) block:cancelBlock];
	}
	[sheet showInView:[PhoneMainView instance].view];
}

- (void)dismissVideoActionSheet:(NSTimer *)timer {
	DTActionSheet *sheet = (DTActionSheet *)timer.userInfo;
	[sheet dismissWithClickedButtonIndex:sheet.destructiveButtonIndex animated:TRUE];
}

#pragma mark Show/Hide Video Preview

- (void)hideVideoPreview:(UITapGestureRecognizer *)tap {
	LinphoneCore* lc = [LinphoneManager getLc];
	if (linphone_core_self_view_enabled(lc))
	{
		[videoPreview setHidden:TRUE];
		//[videoCameraSwitch setHidden:TRUE];
		linphone_core_enable_self_view(lc, NO);
	}
}

- (void)toggleCameras
{
	const char *currentCamId = (char *)linphone_core_get_video_device([LinphoneManager getLc]);
	const char **cameras = linphone_core_get_video_devices([LinphoneManager getLc]);
	const char *newCamId = NULL;
	int i;

	for (i = 0; cameras[i] != NULL; ++i) {
		if (strcmp(cameras[i], "StaticImage: Static picture") == 0)
			continue;
		if (strcmp(cameras[i], currentCamId) != 0) {
			newCamId = cameras[i];
			break;
		}
	}
	if (newCamId) {
		LOGI(@"Switching from [%s] to [%s]", currentCamId, newCamId);
		linphone_core_set_video_device([LinphoneManager getLc], newCamId);
		LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
		if (call != NULL) {
			linphone_core_update_call([LinphoneManager getLc], call, NULL);
		}
	}
}

#pragma mark VideoPreviewMoving

- (void)moveVideoPreview:(UIPanGestureRecognizer *)dragndrop {
	CGPoint center = [dragndrop locationInView:videoPreview.superview];
	self.videoPreview.center = center;
	if (dragndrop.state == UIGestureRecognizerStateEnded) {
		[self previewTouchLift];
	}
}

- (CGFloat)coerce:(CGFloat)value betweenMin:(CGFloat)min andMax:(CGFloat)max {
	if (value > max) {
		value = max;
	}
	if (value < min) {
		value = min;
	}
	return value;
}

- (void)previewTouchLift {
	CGRect previewFrame = self.videoPreview.frame;
	previewFrame.origin.x = [self coerce:previewFrame.origin.x
							  betweenMin:5
								  andMax:(self.view.frame.size.width - previewFrame.size.width - 5)];
	previewFrame.origin.y = [self coerce:previewFrame.origin.y
							  betweenMin:5
								  andMax:(self.view.frame.size.height - previewFrame.size.height - 5)];

	if (!CGRectEqualToRect(previewFrame, self.videoPreview.frame)) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		  [UIView animateWithDuration:0.3
						   animations:^{
							 LOGI(@"Recentering preview to %@", NSStringFromCGRect(previewFrame));
							 self.videoPreview.frame = previewFrame;
						   }];
		});
	}
}

#pragma mark - Call data

+ (int)callCount:(LinphoneCore *)lc
{
	int count = 0;
	const MSList *calls = linphone_core_get_calls(lc);

	while (calls != 0)
	{
		count++;
		calls = calls->next;
	}
	return count;
}

+ (LinphoneCall *)retrieveCallAtIndex:(NSInteger)index
{
	const MSList *calls = linphone_core_get_calls([LinphoneManager getLc]);

	while (calls != 0)
	{
		if (index == 0)
		{
			break;
		}
		index--;
		calls = calls->next;
	}

	if (calls == 0) {
		LOGE(@"Cannot find call with index %d", index);
		return nil;
	} else {
		return (LinphoneCall *)calls->data;
	}
}

@end
