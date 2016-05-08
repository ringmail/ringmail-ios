/* IncomingCallViewController.m
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

#import "IncomingCallViewController.h"
#import "LinphoneManager.h"
#import "FastAddressBook.h"
#import "PhoneMainView.h"
#import "UILinphone.h"

@implementation IncomingCallViewController

@synthesize call;
@synthesize delegate;
@synthesize callData;
@synthesize callViewController;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"IncomingCallViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		self->callData = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callUpdateEvent:)
												 name:kLinphoneCallUpdate
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callAnswerEvent:)
												 name:@"RgIncomingAnswer"
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callRejectEvent:)
												 name:@"RgIncomingReject"
											   object:nil];
	
	
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"RgIncomingAnswer" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"RgIncomingReject" object:nil];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"IncomingCall"
																content:@"IncomingCallViewController"
															   stateBar:nil
														stateBarEnabled:false
																 tabBar:nil
														  tabBarEnabled:false
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

#pragma mark - Event Functions

- (void)callUpdateEvent:(NSNotification *)notif {
	LinphoneCall *acall = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState astate = [[notif.userInfo objectForKey:@"state"] intValue];
	[self callUpdate:acall state:astate];
}

- (void)callAnswerEvent:(NSNotification *)notif
{
	[self dismiss];
	[delegate incomingCallAccepted:call];
}

- (void)callRejectEvent:(NSNotification *)notif
{
	[self dismiss];
	[delegate incomingCallDeclined:call];
}

#pragma mark -

- (void)callUpdate:(LinphoneCall *)acall state:(LinphoneCallState)astate {
	if (call == acall && (astate == LinphoneCallEnd || astate == LinphoneCallError)) {
		[delegate incomingCallAborted:call];
		[self dismiss];
	}
}

- (void)dismiss {
	if ([[[PhoneMainView instance] currentView] equal:[IncomingCallViewController compositeViewDescription]]) {
		[[PhoneMainView instance] popCurrentView];
	}
}

- (void)update {
	[self view]; // Force view load
	
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
            const LinphoneCallParams *params = linphone_call_get_remote_params(call);
            if (linphone_call_params_video_enabled(params))
            {
                video = [NSNumber numberWithBool:YES];
            }
			callData = [NSMutableDictionary dictionaryWithDictionary:@{
				@"address": address,
				@"label": name,
                @"video": video,
			}];
			[callViewController updateCall:callData];
			ms_free(lAddress);
		}
	}
}

#pragma mark - Property Functions

- (void)setCall:(LinphoneCall *)acall {
	call = acall;
	[self update];
	[self callUpdate:call state:linphone_call_get_state(call)];
}

#pragma mark - TPMultiLayoutViewController Functions

- (NSDictionary *)attributesForView:(UIView *)view {
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

	[attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
	[attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
	if ([view isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton *)view;
		[LinphoneUtils buttonMultiViewAddAttributes:attributes button:button];
	}
	[attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];

	return attributes;
}

- (void)applyAttributes:(NSDictionary *)attributes toView:(UIView *)view {
	view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
	view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
	if ([view isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton *)view;
		[LinphoneUtils buttonMultiViewApplyAttributes:attributes button:button];
	}
	view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}

@end
