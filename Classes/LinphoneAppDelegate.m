/* LinphoneAppDelegate.m
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

#import "RgViewDelegate.h"
#import "PhoneMainView.h"
#import "LinphoneAppDelegate.h"
#import "AddressBook/ABPerson.h"

#import "CoreTelephony/CTCallCenter.h"
#import "CoreTelephony/CTCall.h"

#import "LinphoneCoreSettingsStore.h"

#import "RingKit.h"
#import "RKAdapterXMPP.h"

#include "LinphoneManager.h"
#include "linphone/linphonecore.h"

@implementation LinphoneAppDelegate

@synthesize configURL;
@synthesize window;
@synthesize pushReg;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super init];
	if (self != nil) {
		self->startedInBackground = FALSE;
	}
	return self;
}

#pragma mark -

- (void)applicationDidEnterBackground:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	[[LinphoneManager instance] enterBackgroundMode];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
    LinphoneManager *instance = [LinphoneManager instance];
    if ([[instance coreReady] boolValue])
    {
    	LinphoneCore *lc = [LinphoneManager getLc];
    	LinphoneCall *call = linphone_core_get_current_call(lc);

    	if (call) {
    		/* save call context */
    		instance->currentCallContextBeforeGoingBackground.call = call;
    		instance->currentCallContextBeforeGoingBackground.cameraIsEnabled = linphone_call_camera_enabled(call);

    		const LinphoneCallParams *params = linphone_call_get_current_params(call);
    		if (linphone_call_params_video_enabled(params)) {
    			linphone_call_enable_camera(call, false);
    		}
    	}
        [[LinphoneManager instance] resignActive];
    }
	[[RKCommunicator sharedInstance].adapterXMPP disconnect];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));

	if (startedInBackground) {
		startedInBackground = FALSE;
		[[PhoneMainView instance] startUp];
		[[PhoneMainView instance] updateStatusBar:nil];
	}
	LinphoneManager *instance = [LinphoneManager instance];

	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

    if ([[instance coreReady] boolValue])
    {
    	[instance becomeActive];

    	LinphoneCore *lc = [LinphoneManager getLc];
    	LinphoneCall *call = linphone_core_get_current_call(lc);

    	if (call) {
    		if (call == instance->currentCallContextBeforeGoingBackground.call) {
    			const LinphoneCallParams *params = linphone_call_get_current_params(call);
    			if (linphone_call_params_video_enabled(params)) {
    				linphone_call_enable_camera(call, instance->currentCallContextBeforeGoingBackground.cameraIsEnabled);
    			}
    			instance->currentCallContextBeforeGoingBackground.call = 0;
    		} else if (linphone_call_get_state(call) == LinphoneCallIncomingReceived) {
    			[[PhoneMainView instance] displayIncomingCall:call];
    			// in this case, the ringing sound comes from the notification.
    			// To stop it we have to do the iOS7 ring fix...
    			//[self fixRing];
    		}
    	}
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[RgViewDelegate sharedInstance];
    
    NSDictionary *activityDic = [launchOptions objectForKey:UIApplicationLaunchOptionsUserActivityDictionaryKey];
    if (activityDic) {
        NSString *callAddressString = [activityDic valueForKey:@"callAddress"];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:callAddressString forKey:@"callAddress"];
    }
    
	UIApplication *app = [UIApplication sharedApplication];
	//UIApplicationState state = app.applicationState;

	[LinphoneManager instance];
	//BOOL background_mode = [instance lpConfigBoolForKey:@"backgroundmode_preference"];
	//BOOL start_at_boot = [instance lpConfigBoolForKey:@"start_at_boot_preference"];

	if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) // TODO: change this to something more up-to-date
	{
        // registration
		UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
			completionHandler:^(BOOL granted, NSError * _Nullable error) {
		    LevelDB* cfg = [RgManager configDatabase];
			cfg[@"ringmail_allow_local_notifications"] = [NSNumber numberWithBool:granted];
			if (granted)
			{
				UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        	    UNNotificationAction *acceptAction = [UNNotificationAction actionWithIdentifier:@"call_answer" title:@"Answer" options:UNNotificationActionOptionForeground];
                UNNotificationAction *declineAction = [UNNotificationAction actionWithIdentifier:@"call_decline" title:@"Decline" options:UNNotificationActionOptionDestructive];
                NSArray *notificationActions = @[ acceptAction, declineAction ];

        		// create a category
                UNNotificationCategory *answerCategory = [UNNotificationCategory categoryWithIdentifier:@"call" actions:notificationActions intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];

                NSSet *categories = [NSSet setWithObject:answerCategory];
				[center setNotificationCategories:categories];
				center.delegate = self;
			}
		}];
        [app registerForRemoteNotifications];
	}

	/*if (state == UIApplicationStateBackground) {
		// we've been woken up directly to background;
		if (!start_at_boot || !background_mode) {
			// autoboot disabled or no background, and no push: do nothing and wait for a real launch
			// output a log with NSLog, because the ortp logging system isn't activated yet at this time
			NSLog(@"Linphone launch doing nothing because start_at_boot or background_mode are not activated.", NULL);
			return YES;
		}
	}*/
	/*bgStartId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
	  LOGW(@"Background task for application launching expired.");
	  [[UIApplication sharedApplication] endBackgroundTask:bgStartId];
	}];*/
    
	// initialize UI
	[self.window makeKeyAndVisible];
	[RootViewManager setupWithPortrait:(PhoneMainView *)self.window.rootViewController];

   	[[PhoneMainView instance] startUp];
    [[PhoneMainView instance] updateStatusBar:nil];

	NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	if (remoteNotif) {
		LOGI(@"PushNotification from launch received: %@", remoteNotif);
		//[self processRemoteNotification:remoteNotif];
	}
	/*if (bgStartId != UIBackgroundTaskInvalid)
		[[UIApplication sharedApplication] endBackgroundTask:bgStartId];*/
    
    
    // Google Sign-In
    NSError* configureError;
    [[GGLContext sharedInstance] configureWithError: &configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
    [GIDSignIn sharedInstance].delegate = self;

	return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));

	linphone_core_terminate_all_calls([LinphoneManager getLc]);

	// destroyLinphoneCore automatically unregister proxies but if we are using
	// remote push notifications, we want to continue receiving them
	if ([LinphoneManager instance].pushNotificationToken != nil) {
		//trick me! setting network reachable to false will avoid sending unregister
		linphone_core_set_network_reachable([LinphoneManager getLc], FALSE);
	}
	[[LinphoneManager instance] destroyLinphoneCore];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
        
	LOGI(@"%@ - url = %ld", NSStringFromSelector(_cmd), [url absoluteString]);
	NSString *scheme = [[url scheme] lowercaseString];
	if ([scheme isEqualToString:@"ring"] || [scheme isEqualToString:@"ringdev"])
    {
        NSString *encodedURL = [url absoluteString];
		NSString *finalURL = [encodedURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [RgManager processRingURI:finalURL];
	}
	return YES;
}

/*- (void)fixRing {
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
		// iOS7 fix for notification sound not stopping.
		// see http://stackoverflow.com/questions/19124882/stopping-ios-7-remote-notification-sound
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	}
}*/

/*
- (void)processRemoteNotification:(NSDictionary *)userInfo {

	NSDictionary *aps = [userInfo objectForKey:@"aps"];

	if (aps != nil) {
		NSDictionary *alert = [aps objectForKey:@"alert"];
		if (alert != nil) {
			NSString *loc_key = [alert objectForKey:@"loc-key"];
			LinphoneCore *lc = [LinphoneManager getLc];
			if (linphone_core_get_calls(lc) == NULL) { // if there are calls, obviously our TCP socket shall be working
				linphone_core_set_network_reachable(lc, FALSE);
				[LinphoneManager instance].connectivity = none; // force connectivity to be discovered again
				[[LinphoneManager instance] refreshRegisters];
				if (loc_key != nil) {

					NSString *callId = [userInfo objectForKey:@"call-id"];
					if (callId != nil) {
						[[LinphoneManager instance] addPushCallId:callId];
					} else {
						LOGE(@"PushNotification: does not have call-id yet, fix it !");
					}

					if ([loc_key isEqualToString:@"IM_MSG"]) {

                        // TODO: Replace this
						//[[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];

					} else if ([loc_key isEqualToString:@"IC_MSG"]) {

						[self fixRing];
					}
				}
			}
		}
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);

	[self processRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
	LOGI(@"%@ - state = %ld", NSStringFromSelector(_cmd), (long)application.applicationState);

	[self fixRing];

	if ([notification.userInfo objectForKey:@"callId"] != nil) {
		BOOL auto_answer = TRUE;

		// some local notifications have an internal timer to relaunch themselves at specified intervals
		if ([[notification.userInfo objectForKey:@"timer"] intValue] == 1) {
			[[LinphoneManager instance] cancelLocalNotifTimerForCallId:[notification.userInfo objectForKey:@"callId"]];
			auto_answer = [[LinphoneManager instance] lpConfigBoolForKey:@"autoanswer_notif_preference"];
		}
		if (auto_answer) {
			[[LinphoneManager instance] acceptCallForCallId:[notification.userInfo objectForKey:@"callId"]];
		}
	}
}
*/

// this method is implemented for iOS7. It is invoked when receiving a push notification for a call and it has
// "content-available" in the aps section.
/*
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);
    
    LinphoneManager *lm = [LinphoneManager instance];
    
    NSString *actionKey = [[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"action-loc-key"];
    if ([actionKey isEqualToString:@"CHAT"])
    {
        NSString *chatMd5 = [userInfo objectForKey:@"tag"];
		RKCommunicator* comm = [RKCommunicator sharedInstance];
		RKThread* thread = [comm getThreadByMD5:chatMd5];
		if (thread != nil)
		{
			[comm startMessageView:thread];
		}
		else
		{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
				RKCommunicator* comm = [RKCommunicator sharedInstance];
        		RKThread* thread = [comm getThreadByMD5:chatMd5];
        		if (thread != nil)
        		{
        			[comm startMessageView:thread];
        		}				
			});
		}
		completionHandler(UIBackgroundFetchResultNewData);
		return;
    }

	// save the completion handler for later execution.
	// 2 outcomes:
	// - if a new call/message is received, the completion handler will be called with "NEWDATA"
	// - if nothing happens for 15 seconds, the completion handler will be called with "NODATA"
	lm.silentPushCompletion = completionHandler;
	[NSTimer scheduledTimerWithTimeInterval:15.0
									 target:lm
								   selector:@selector(silentPushFailed:)
								   userInfo:nil
									repeats:FALSE];

	LinphoneCore *lc = [LinphoneManager getLc];
	// If no call is yet received at this time, then force Linphone to drop the current socket and make new one to
	// register, so that we get
	// a better chance to receive the INVITE.
    
	if (linphone_core_get_calls(lc) == NULL) {
		linphone_core_set_network_reachable(lc, FALSE);
		lm.connectivity = none; //force connectivity to be discovered again
		[lm refreshRegisters];
	}
}
*/

#pragma mark - PushNotification Functions

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), deviceToken);
    
    pushReg = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushReg.delegate = self;
    pushReg.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    
	[[LinphoneManager instance] setPushNotificationToken:deviceToken];
    [RgManager setupPushToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), [error localizedDescription]);
	[[LinphoneManager instance] setPushNotificationToken:nil];
}
#pragma mark - PushKit VoIP

-(void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type
{
    NSLog(@"RingMail: PushKit Token: %@", credentials.token);
    LevelDB* cfg = [RgManager configDatabase];
    [cfg setObject:credentials.token forKey:@"ringmail_voip_token"];
    [[RgNetwork instance] registerPushTokenVoIP:credentials.token];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
    NSLog(@"RingMail: VoIP Push Received: %@", payload);
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
    {
	    LevelDB* cfg = [RgManager configDatabase];
		NSNumber* allow = cfg[@"ringmail_allow_local_notifications"];
		if (allow != nil && [allow boolValue])
		{
   			LinphoneManager* mgr = [LinphoneManager instance];
		    if ([[mgr coreReady] boolValue])
			{
				[mgr refreshRegisters];
    			mgr->skipRegisterRefresh = YES;
			}
		
			UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
            content.title = @"Incoming Call";
			content.body = [payload.dictionaryPayload objectForKey:@"from"];
			content.userInfo = @{
				@"call_id": [payload.dictionaryPayload objectForKey:@"call_id"],
			};
            content.sound = [UNNotificationSound soundNamed:@"call_in.caf"];
            content.categoryIdentifier = @"call";
			UNNotificationRequest *notification = [UNNotificationRequest requestWithIdentifier:@"ringmail_call_notification" content:content trigger:nil];
    		UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
			[center addNotificationRequest:notification withCompletionHandler:^(NSError * _Nullable error) {
                if (error)
				{
                    NSAssert(FALSE, [error localizedDescription]);
                }
            }];
		}
    }
}

#pragma mark - User notification response delegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler
{
	NSLog(@"%s: %@ %@", __PRETTY_FUNCTION__, response.actionIdentifier, response.notification.request.content.userInfo);
	NSString *action = response.actionIdentifier;
	NSString *category = response.notification.request.content.categoryIdentifier;
	if ([category isEqualToString:@"msg"])
	{
		NSString *chatMd5 = response.notification.request.content.userInfo[@"tag"];
		RKCommunicator* comm = [RKCommunicator sharedInstance];
		RKThread* thread = [comm getThreadByMD5:chatMd5];
		if (thread != nil)
		{
			[comm startMessageView:thread];
		}
		else
		{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2000 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
				RKCommunicator* comm = [RKCommunicator sharedInstance];
        		RKThread* thread = [comm getThreadByMD5:chatMd5];
        		if (thread != nil)
        		{
        			[comm startMessageView:thread];
        		}				
			});
		}
	}
	else if ([category isEqualToString:@"call"])
	{
    	if (
    		[action isEqualToString:@"com.apple.UNNotificationDefaultActionIdentifier"] ||
    		[action isEqualToString:@"call_answer"]
    	) {
    		NSDictionary* userInfo = response.notification.request.content.userInfo;
    		NSLog(@"Notification: %@", userInfo);
    		[[LinphoneManager instance] acceptCallForCallId:userInfo[@"call_id"]];
    	}
    	else if ([action isEqualToString:@"call_decline"])
    	{
    		LinphoneManager *mgr = [LinphoneManager instance];
    		mgr->skipRegisterRefresh = NO;
    		if ([[mgr coreReady] boolValue])
    		{
        		LinphoneCore *lc = [LinphoneManager getLc];
        		LinphoneCall *call = linphone_core_get_current_call(lc);
        		if (call)
        		{
        			linphone_core_decline_call(lc, call, LinphoneReasonDeclined);
        		}
    		}
    	}
    	else
    	{
    		LinphoneManager *mgr = [LinphoneManager instance];
    		mgr->skipRegisterRefresh = NO;
    	}
	}
	completionHandler();
}

#pragma mark - User notifications

/*
- (void)application:(UIApplication *)application
	didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
	LOGI(@"%@", NSStringFromSelector(_cmd));
}

- (void)application:(UIApplication *)application
	handleActionWithIdentifier:(NSString *)identifier
		  forLocalNotification:(UILocalNotification *)notification
			 completionHandler:(void (^)())completionHandler {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	if ([[UIDevice currentDevice].systemVersion floatValue] >= 8) {

		LinphoneCore *lc = [LinphoneManager getLc];
		LOGI(@"%@", NSStringFromSelector(_cmd));
		if ([notification.category isEqualToString:@"incoming_call"]) {
			if ([identifier isEqualToString:@"answer"]) {
				// use the standard handler
				[self application:application didReceiveLocalNotification:notification];
			} else if ([identifier isEqualToString:@"decline"]) {
				LinphoneCall *call = linphone_core_get_current_call(lc);
				if (call)
					linphone_core_decline_call(lc, call, LinphoneReasonDeclined);
			}
		} else if ([notification.category isEqualToString:@"incoming_msg"]) {
			if ([identifier isEqualToString:@"reply"]) {
				// use the standard handler
				[self application:application didReceiveLocalNotification:notification];
			} else if ([identifier isEqualToString:@"mark_read"]) {
				NSString *from = [notification.userInfo objectForKey:@"from_addr"];
				LinphoneChatRoom *room = linphone_core_get_chat_room_from_uri(lc, [from UTF8String]);
				if (room) {
					linphone_chat_room_mark_as_read(room);
					[[PhoneMainView instance] updateApplicationBadgeNumber];
				}
			}
		}
	}
	completionHandler();
}

- (void)application:(UIApplication *)application
	handleActionWithIdentifier:(NSString *)identifier
		 forRemoteNotification:(NSDictionary *)userInfo
			 completionHandler:(void (^)())completionHandler {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	completionHandler();
}
*/

#pragma mark - NSUserActivity

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType {
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    
    NSDictionary *tempDict = [[userActivity userInfo] copy];
    NSString *msgContactIDString = tempDict[@"msgContactID"];
    NSString *msgTextString = tempDict[@"msgText"];
    NSString *callContactIDString = tempDict[@"callContactID"];
        
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:msgContactIDString forKey:@"msgContactID"];
    [defaults setObject:msgTextString forKey:@"msgText"];
    [defaults setObject:callContactIDString forKey:@"callContactID"];
    
    return YES;
}

- (void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error {

}

- (void)application:(UIApplication *)application didUpdateUserActivity:(NSUserActivity *)userActivity {

}

#pragma mark - openURL

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)options {
//    NSLog(@"openURL: %@", url);
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:sourceApplication
                                      annotation:annotation];
}

#pragma mark - Google Sign-In

- (void)signIn:(GIDSignIn *)signIn
didSignInForUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    
    if (user.userID && user.authentication.idToken)
        [[NSNotificationCenter defaultCenter] postNotificationName:kRgGoogleSignInVerifed object:user userInfo:nil];
    else if (error)
        [[NSNotificationCenter defaultCenter] postNotificationName:kRgGoogleSignInError object:user userInfo:nil];
}

- (void)signIn:(GIDSignIn *)signIn
didDisconnectWithUser:(GIDGoogleUser *)user
     withError:(NSError *)error {
    // Perform any operations when the user disconnects from app here.
}

@end
