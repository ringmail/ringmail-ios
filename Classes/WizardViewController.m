
/* WizardViewController.m
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
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "WizardViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

#import "DTAlertView.h"
#import "RgNetwork.h"

typedef enum _ViewElement {
	ViewElement_FirstName = 100,
	ViewElement_LastName = 101,
	ViewElement_Username = 102, // Really "email"
	ViewElement_Phone = 103,
	ViewElement_Password = 104,
    ViewElement_Hashtag = 106,
	//ViewElement_Password2 = 102,
    ViewElement_Code = 105,
	ViewElement_Label = 200,
	ViewElement_Error = 201,
	ViewElement_Username_Error = 404
} ViewElement;

@implementation WizardViewController

@synthesize contentView;

@synthesize choiceView;
@synthesize createAccountView;
@synthesize connectAccountView;
@synthesize validateAccountView;
@synthesize validatePhoneView;
@synthesize waitView;

@synthesize backButtonWiz;
@synthesize createAccountButton;
@synthesize connectAccountButton;
@synthesize remoteProvisioningButton;

@synthesize choiceViewLogoImageView;

@synthesize viewTapGestureRecognizer;

@synthesize verifyEmailLabel;
@synthesize verifyPhoneLabel;

@synthesize passwordLabel;


#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"WizardViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		[[NSBundle mainBundle] loadNibNamed:@"WizardViews" owner:self options:nil];
		self->historyViews = [[NSMutableArray alloc] init];
		self->currentView = nil;
		self->viewTapGestureRecognizer =
			[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewTap:)];
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
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Wizard"
																content:@"WizardViewController"
															   stateBar:nil
														stateBarEnabled:false
                                                                 navBar:nil
																 tabBar:nil
                                                         navBarEnabled:false
														  tabBarEnabled:false
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
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
//	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
	[viewTapGestureRecognizer setCancelsTouchesInView:FALSE];
	[viewTapGestureRecognizer setDelegate:self];
	[contentView addGestureRecognizer:viewTapGestureRecognizer];
    
    [GIDSignIn sharedInstance].uiDelegate = self;
//    [self.googleSignInButton setStyle:kGIDSignInButtonStyleWide];
//    [self.googleSignUpButton setStyle:kGIDSignInButtonStyleWide];
    
    [backButtonWiz setTitle:[NSString stringWithUTF8String:"\uf053"] forState:UIControlStateNormal];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdateEvent:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(attemptVerify:)
                                                 name:kRgAttemptVerify
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(googleSignInVerifedEvent:)
                                                 name:kRgGoogleSignInVerifed
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(googleSignInErrorEvent:)
                                                 name:kRgGoogleSignInError
                                               object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneRegistrationUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgAttemptVerify object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgGoogleSignInVerifed object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgGoogleSignInError object:nil];
}

#pragma mark -

+ (void)cleanTextField:(UIView *)view {
	if ([view isKindOfClass:[UITextField class]]) {
		[(UITextField *)view setText:@""];
	} else {
		for (UIView *subview in view.subviews) {
			[WizardViewController cleanTextField:subview];
		}
	}
}

- (void)fillDefaultValues {

	LinphoneCore *lc = [LinphoneManager getLc];
	[self resetTextFields];

	LinphoneProxyConfig *current_conf = NULL;
	linphone_core_get_default_proxy([LinphoneManager getLc], &current_conf);
	if (current_conf != NULL) {
		const char *proxy_addr = linphone_proxy_config_get_identity(current_conf);
		if (proxy_addr) {
			LinphoneAddress *addr = linphone_address_new(proxy_addr);
			if (addr) {
				const LinphoneAuthInfo *auth = linphone_core_find_auth_info(
					lc, NULL, linphone_address_get_username(addr), linphone_proxy_config_get_domain(current_conf));
				linphone_address_destroy(addr);
				if (auth) {
					LOGI(@"A proxy config was set up with the remote provisioning, skip wizard");
				}
			}
		}
	}
}

- (void)resetTextFields {
	[WizardViewController cleanTextField:choiceView];
	[WizardViewController cleanTextField:createAccountView];
	[WizardViewController cleanTextField:connectAccountView];
	[WizardViewController cleanTextField:validateAccountView];
}

- (void)startWizard {
	[self resetTextFields];
    if ([RgManager configReady])
    {
        if ([RgManager configEmailVerified])
        {
            [self changeView:validatePhoneView back:FALSE animation:FALSE];
        }
        else
        {
            [self changeView:validateAccountView back:FALSE animation:FALSE];
            LevelDB* cfg = [RgManager configDatabase];
            if (cfg[@"ringmail_check_email"] != nil) // attempt check
            {
                [cfg removeObjectForKey:@"ringmail_check_email"];
                [self verifyEmail];
            }
        }
    }
    else
    {
        [self changeView:choiceView back:FALSE animation:FALSE];
    }
	[waitView setHidden:TRUE];
}

- (void)reset {
	[self clearProxyConfig];

	LinphoneCore *lc = [LinphoneManager getLc];
	LCSipTransports transportValue = {5060, 5060, -1, -1};

	if (linphone_core_set_sip_transports(lc, &transportValue)) {
		LOGE(@"cannot set transport");
	}

	[[LinphoneManager instance] lpConfigSetString:@"" forKey:@"sharing_server_preference"];
	[[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"ice_preference"];
	[[LinphoneManager instance] lpConfigSetString:@"" forKey:@"stun_preference"];
	linphone_core_set_stun_server(lc, NULL);
	linphone_core_set_firewall_policy(lc, LinphonePolicyNoFirewall);
   
    NSLog(@"RingMail: Wizard - Reset Complete");
}

+ (UIView *)findView:(ViewElement)tag view:(UIView *)view {
	for (UIView *child in [view subviews]) {
		if ([child tag] == tag) {
			return (UITextField *)child;
		} else {
			UIView *o = [WizardViewController findView:tag view:child];
			if (o)
				return o;
		}
	}
	return nil;
}

+ (UITextField *)findTextField:(ViewElement)tag view:(UIView *)view {
	UIView *aview = [WizardViewController findView:tag view:view];
	if ([aview isKindOfClass:[UITextField class]])
		return (UITextField *)aview;
	return nil;
}

+ (UILabel *)findLabel:(ViewElement)tag view:(UIView *)view {
	UIView *aview = [WizardViewController findView:tag view:view];
	if ([aview isKindOfClass:[UILabel class]])
		return (UILabel *)aview;
	return nil;
}

- (void)clearHistory {
	[historyViews removeAllObjects];
}


- (void)changeView:(UIView *)view back:(BOOL)back animation:(BOOL)animation {

	// Change toolbar buttons following view
    
	if (
        view == validateAccountView ||
        view == validatePhoneView ||
        view == choiceView
    ) {
		[backButtonWiz setEnabled:FALSE];
        [backButtonWiz setHidden:TRUE];
	} else {
		[backButtonWiz setEnabled:TRUE];
        [backButtonWiz setHidden:FALSE];
	}
    
    if (view == validateAccountView)
    {
        LevelDB* cfg = [RgManager configDatabase];
        [verifyEmailLabel setText:[cfg objectForKey:@"ringmail_login"]];
    }
    else if (view == validatePhoneView)
    {
        LevelDB* cfg = [RgManager configDatabase];
		NSString *ph = [cfg objectForKey:@"ringmail_phone"];
		ph = [RgManager formatPhoneNumber:ph];
        [verifyPhoneLabel setText:ph];
        
        if (cfg[@"ringmain_check_phone"] == nil) // Send code once
        {
            [[RgNetwork instance] resendVerify:@{@"phone": [cfg objectForKey:@"ringmail_phone"]} callback:^(NSURLSessionTask *operation, id responseObject) {
                NSDictionary* res = responseObject;
                NSString *ok = [res objectForKey:@"result"];
                if (ok != nil && [ok isEqualToString:@"ok"])
                {
                    cfg[@"ringmail_check_phone"] = @1;
                }
                else
                {
                    NSString* error = [res objectForKey:@"error"];
                    NSLog(@"RingMail: Error - API resend verify: %@", error);
                }
            }];
        }
    }
    
	// Animation
	if (animation && [[LinphoneManager instance] lpConfigBoolForKey:@"animations_preference"] == true) {
		CATransition *trans = [CATransition animation];
		[trans setType:kCATransitionPush];
		[trans setDuration:0.35];
		[trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		if (back) {
			[trans setSubtype:kCATransitionFromLeft];
		} else {
			[trans setSubtype:kCATransitionFromRight];
		}
		[contentView.layer addAnimation:trans forKey:@"Transition"];
	}

	// Stack current view
	if (currentView != nil) {
		if (!back)
			[historyViews addObject:currentView];
		[currentView removeFromSuperview];
	}

	// Set current view
	currentView = view;
	[contentView insertSubview:view atIndex:0];
	[view setFrame:[contentView bounds]];
	[contentView setContentSize:[view bounds].size];
}

- (void)clearProxyConfig {
	linphone_core_clear_proxy_config([LinphoneManager getLc]);
	linphone_core_clear_all_auth_info([LinphoneManager getLc]);
}

- (void)setDefaultSettings:(LinphoneProxyConfig *)proxyCfg {
	LinphoneManager *lm = [LinphoneManager instance];

	[lm configurePushTokenForProxyConfig:proxyCfg];
}

- (BOOL)addProxyConfig:(NSString *)username
			  password:(NSString *)password
				domain:(NSString *)domain
		 withTransport:(NSString *)transport {
    
	LinphoneCore *lc = [LinphoneManager getLc];
	LinphoneProxyConfig *proxyCfg = linphone_core_create_proxy_config(lc);
	NSString *server_address = domain;

	char normalizedUserName[256];
	linphone_proxy_config_normalize_number(proxyCfg, [username cStringUsingEncoding:[NSString defaultCStringEncoding]],
										   normalizedUserName, sizeof(normalizedUserName));

	const char *identity = linphone_proxy_config_get_identity(proxyCfg);
	if (!identity || !*identity)
		identity = "sip:user@example.com";

	LinphoneAddress *linphoneAddress = linphone_address_new(identity);
	linphone_address_set_username(linphoneAddress, normalizedUserName);

	if (domain && [domain length] != 0) {
		if (transport != nil) {
			server_address =
				[NSString stringWithFormat:@"%@;transport=%@", server_address, [transport lowercaseString]];
		}
		// when the domain is specified (for external login), take it as the server address
		linphone_proxy_config_set_server_addr(proxyCfg, [server_address UTF8String]);
		linphone_address_set_domain(linphoneAddress, [domain UTF8String]);
	}

	char *extractedAddres = linphone_address_as_string_uri_only(linphoneAddress);

	LinphoneAddress *parsedAddress = linphone_address_new(extractedAddres);
	ms_free(extractedAddres);

	if (parsedAddress == NULL || !linphone_address_is_sip(parsedAddress)) {
		if (parsedAddress)
			linphone_address_destroy(parsedAddress);
		UIAlertView *errorView =
			[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)", nil)
									   message:NSLocalizedString(@"Please enter a valid username", nil)
									  delegate:nil
							 cancelButtonTitle:NSLocalizedString(@"Continue", nil)
							 otherButtonTitles:nil, nil];
		[errorView show];
		return FALSE;
	}

	char *c_parsedAddress = linphone_address_as_string_uri_only(parsedAddress);

	linphone_proxy_config_set_identity(proxyCfg, c_parsedAddress);

	linphone_address_destroy(parsedAddress);
	ms_free(c_parsedAddress);

	LinphoneAuthInfo *info = linphone_auth_info_new([username UTF8String], NULL, [password UTF8String], NULL, NULL,
													linphone_proxy_config_get_domain(proxyCfg));
    
	[self setDefaultSettings:proxyCfg];

	[self clearProxyConfig];

	linphone_proxy_config_enable_register(proxyCfg, true);
	linphone_core_add_auth_info(lc, info);
	linphone_core_add_proxy_config(lc, proxyCfg);
	linphone_core_set_default_proxy_config(lc, proxyCfg);
	// reload address book to prepend proxy config domain to contacts' phone number
	[[[LinphoneManager instance] fastAddressBook] reload];
	return TRUE;
}

- (NSString *)identityFromUsername:(NSString *)username {
	char normalizedUserName[256];
	LinphoneAddress *linphoneAddress = linphone_address_new("sip:user@domain.com");
	linphone_proxy_config_normalize_number(NULL, [username cStringUsingEncoding:[NSString defaultCStringEncoding]],
										   normalizedUserName, sizeof(normalizedUserName));
	linphone_address_set_username(linphoneAddress, normalizedUserName);
	linphone_address_set_domain(
		linphoneAddress, [[[LinphoneManager instance] lpConfigStringForKey:@"domain" forSection:@"wizard"] UTF8String]);
	NSString *uri = [NSString stringWithUTF8String:linphone_address_as_string_uri_only(linphoneAddress)];
	NSString *scheme = [NSString stringWithUTF8String:linphone_address_get_scheme(linphoneAddress)];
	return [uri substringFromIndex:[scheme length] + 1];
}

#pragma mark -

- (void)registrationUpdate:(LinphoneRegistrationState)state message:(NSString *)message {
	switch (state) {
	case LinphoneRegistrationOk: {
        // TODO:
//        (create RKContactStore DBs and get any previous RGContacts from server after first app use signin:)
        //                [RgManager updateContacts:res];  // needs a stubbed res object
		[waitView setHidden:true];
		[[PhoneMainView instance] changeCurrentView:[RgHashtagDirectoryViewController compositeViewDescription]];
		break;
	}
	case LinphoneRegistrationNone:
	case LinphoneRegistrationCleared: {
		[waitView setHidden:true];
		break;
	}
	case LinphoneRegistrationFailed: {
		[waitView setHidden:true];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Registration failure", nil)
														message:message
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
		break;
	}
	case LinphoneRegistrationProgress: {
		[waitView setHidden:false];
		break;
	}
	default:
		break;
	}
}

- (void)loadWizardConfig:(NSString *)rcFilename {
	NSString *fullPath = [@"file://" stringByAppendingString:[LinphoneManager bundleFile:rcFilename]];
	linphone_core_set_provisioning_uri([LinphoneManager getLc],
									   [fullPath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
	[[LinphoneManager instance] lpConfigSetInt:1 forKey:@"transient_provisioning" forSection:@"misc"];

	// For some reason, video preview hangs for 15seconds when resetting linphone core from here...
	// to avoid it, we disable it before and reenable it after core restart.
	BOOL hasPreview = linphone_core_video_preview_enabled([LinphoneManager getLc]);
	linphone_core_enable_video_preview([LinphoneManager getLc], FALSE);
	[[LinphoneManager instance] resetLinphoneCore];
	linphone_core_enable_video_preview([LinphoneManager getLc], hasPreview);
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    UITextField *next = nil;
    if (currentView == createAccountView)
    {
        if (textField.tag == ViewElement_FirstName)
        {
            next = [WizardViewController findTextField:ViewElement_LastName view:contentView];
        }
        else if (textField.tag == ViewElement_LastName)
        {
            next = [WizardViewController findTextField:ViewElement_Username view:contentView];
        }
        else if (textField.tag == ViewElement_Username)
        {
            next = [WizardViewController findTextField:ViewElement_Password view:contentView];
        }
        else if (textField.tag == ViewElement_Password)
        {
            next = [WizardViewController findTextField:ViewElement_Phone view:contentView];
        }
    }
    else if (currentView == connectAccountView)
    {
        if (textField.tag == ViewElement_Username)
        {
            next = [WizardViewController findTextField:ViewElement_Password view:contentView];
        }
    }
    if (next)
    {
        [next becomeFirstResponder];
    }
    
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	activeTextField = textField;
}

- (void)hideError:(NSTimer *)timer {
	UILabel *error_label = [WizardViewController findLabel:ViewElement_Username_Error view:contentView];
	if (error_label) {
		[UIView animateWithDuration:0.3
			animations:^{
			  error_label.alpha = 0;
			}
			completion:^(BOOL finished) {
			  error_label.hidden = YES;
			}];
	}
}

#pragma mark - Action Functions

- (IBAction)onBackClick:(id)sender {
	if ([historyViews count] > 0) {
        
        if (currentView == createAccountView)
        {
            [WizardViewController cleanTextField:createAccountView];
            [WizardViewController findTextField:ViewElement_Username view:contentView].userInteractionEnabled = true;
            [WizardViewController findTextField:ViewElement_Password view:contentView].hidden = false;
            passwordLabel.hidden = false;
            [[GIDSignIn sharedInstance] signOut];
        }
        
		UIView *view = [historyViews lastObject];
		[historyViews removeLastObject];
		[self changeView:view back:TRUE animation:FALSE];
	}
}

- (IBAction)onCreateAccountClick:(id)sender {
	nextView = createAccountView;
    [self changeView:nextView back:false animation:FALSE];
    nextView = nil;
}

- (IBAction)onConnectLinphoneAccountClick:(id)sender {
	nextView = connectAccountView;
    [self changeView:nextView back:false animation:FALSE];
    nextView = nil;
}

- (IBAction)onGoToMailClick:(id)sender {
    NSURL* mailURL = [NSURL URLWithString:@"message://"];
    if ([[UIApplication sharedApplication] canOpenURL:mailURL]) {
        [[UIApplication sharedApplication] openURL:mailURL];
    }
    else
    {
        NSLog(@"RingMail: Mail - Goto failed");
    }
}

- (IBAction)onResendVerifyClick:(id)sender {
    LevelDB* cfg = [RgManager configDatabase];
    [[RgNetwork instance] resendVerify:@{@"email": [cfg objectForKey:@"ringmail_login"]} callback:^(NSURLSessionTask *operation, id responseObject) {
        NSDictionary* res = responseObject;
        NSString *ok = [res objectForKey:@"result"];
        if ([ok isEqualToString:@"ok"])
        {
            UIAlertView *confirmView = [[UIAlertView alloc] initWithTitle:@"Email Sent"
                                                                message:@"Please check your email inbox."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            [confirmView show];
        }
        else
        {
            NSString* error = [res objectForKey:@"error"];
            NSLog(@"RingMail: Error - API resend verify: %@", error);
        }
    }];
}

- (IBAction)onCheckEmailClick:(id)sender {
    [self verifyEmail];
}

- (void)verifyEmail
{
    [waitView setHidden:FALSE];
    [RgManager verifyLogin:^(NSURLSessionTask *operation, id responseObject) {
        [waitView setHidden:TRUE];
        BOOL verified = NO;
        NSMutableDictionary* res = [NSMutableDictionary dictionaryWithDictionary:responseObject];
        NSString *ok = [res objectForKey:@"result"];
        if (ok != nil && [ok isEqualToString:@"ok"])
        {
            LevelDB* cfg = [RgManager configDatabase];
            [cfg setObject:@"1" forKey:@"ringmail_verify_email"];
            [cfg setObject:res forKey:@"ringmail_initial"];
            verified = YES;
        }
        else if ([RgManager configEmailVerified])
        {
            verified = YES;
        }
        if (verified)
        {
            if ([RgManager configPhoneVerified])
            {
                [self connectToRingMail];
            }
            else
            {
                // Go To Next View
                [self changeView:validatePhoneView back:false animation:FALSE];
            }
        }
    }
    failure:^(NSURLSessionTask *operation, NSError *error) {
       NSLog(@"at verifyEmail: failure");
    }];
}

- (IBAction)onResendPhoneClick:(id)sender {
    LevelDB* cfg = [RgManager configDatabase];
    [[RgNetwork instance] resendVerify:@{@"phone": [cfg objectForKey:@"ringmail_phone"]} callback:^(NSURLSessionTask *operation, id responseObject) {
        NSDictionary* res = responseObject;
        NSString *ok = [res objectForKey:@"result"];
        if (ok != nil && [ok isEqualToString:@"ok"])
        {
            cfg[@"ringmail_check_phone"] = @1;
        }
        else
        {
            NSString* error = [res objectForKey:@"error"];
            NSLog(@"RingMail: Error - API resend verify: %@", error);
        }
    }];
}

- (IBAction)onCheckPhoneClick:(id)sender {
	NSString *code = [WizardViewController findTextField:ViewElement_Code view:contentView].text;
    if ([code isMatchedByRegex:@"^\\d{4}$"])
    {
        [waitView setHidden:FALSE];
        [[RgNetwork instance] verifyPhone:code callback:^(NSURLSessionTask *operation, id responseObject) {
            [waitView setHidden:TRUE];
            BOOL verified = NO;
            NSDictionary* res = responseObject;
            NSString *ok = [res objectForKey:@"result"];
            LevelDB* cfg = [RgManager configDatabase];
            if (ok != nil && [ok isEqualToString:@"ok"])
            {
                [cfg setObject:@"1" forKey:@"ringmail_verify_phone"];
                verified = YES;
            }
            else if ([RgManager configReadyAndVerified])
            {
                verified = YES;
            }
            if (verified)
            {
				if (cfg[@"google_oauth2_id_token"] != nil)
				{
    				[RgManager verifyLogin:^(NSURLSessionTask *operation, id responseObject) {
                        [waitView setHidden:TRUE];
                        NSMutableDictionary* res = [NSMutableDictionary dictionaryWithDictionary:responseObject];
                        NSString *ok = [res objectForKey:@"result"];
                        if (ok != nil && [ok isEqualToString:@"ok"])
                        {
                            LevelDB* cfg = [RgManager configDatabase];
                            [cfg setObject:res forKey:@"ringmail_initial"];
							[self connectToRingMail];
                        }
					} failure:^(NSURLSessionTask *operation, NSError *error) {
                       NSLog(@"Verify login failed with Google OAuth2");
                    }];
				}
				else
				{
					[self connectToRingMail];
				}
            }
            else
            {
                UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"Phone Number Not Verified"
                               message:@"Please enter the correct code for your phone number to continue."
                              delegate:nil
                     cancelButtonTitle:@"OK"
                     otherButtonTitles:nil, nil];
                [errorView show];
            }
        }];
    }
    else
    {
        UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"Invalid Code"
                       message:@"Please enter the correct code for your phone number to continue."
                      delegate:nil
             cancelButtonTitle:@"OK"
             otherButtonTitles:nil, nil];
        [errorView show];
    }
}

- (void)connectToRingMail
{
    LevelDB* cfg = [RgManager configDatabase];
    NSDictionary *res = cfg[@"ringmail_initial"];
    if (res != nil)
    {
        [cfg removeObjectForKey:@"ringmail_initial"];
        [[LinphoneManager instance] startLinphoneCore];
        [self reset];
        [self loadWizardConfig:@"wizard_linphone_ringmail.rc"];
        [self addProxyConfig:[res objectForKey:@"sip_login"] password:[res objectForKey:@"sip_password"]
                      domain:[RgManager ringmailHostSIP] withTransport:@"tls"];
        [RgManager updateCredentials:res];
        [RgManager updateContacts:res];
    }
}

- (BOOL)verificationWithUsername:(NSString *)username
						password:(NSString *)password
						  domain:(NSString *)domain
				   withTransport:(NSString *)transport {
	NSMutableString *errors = [NSMutableString string];
	if ([username length] == 0) {
		[errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a valid username.\n", nil)]];
	}

	if (domain != nil && [domain length] == 0) {
		[errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a valid domain.\n", nil)]];
	}

	if ([errors length]) {
		UIAlertView *errorView =
			[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)", nil)
									   message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
									  delegate:nil
							 cancelButtonTitle:NSLocalizedString(@"Continue", nil)
							 otherButtonTitles:nil, nil];
		[errorView show];
		return FALSE;
	}
	return TRUE;
}

- (IBAction)onSignInClick:(id)sender {
	NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
	NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;

    if ([self verificationWithUsername:username password:password domain:nil withTransport:nil]) {
        [waitView setHidden:false];
        if ([LinphoneManager instance].connectivity == none) {
            DTAlertView *alert = [[DTAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"No connectivity", nil)
                                  message:@"Internet connectivity required to continue"];
            [alert addCancelButtonWithTitle:NSLocalizedString(@"Stay here", nil)
                                      block:^{
                                          [waitView setHidden:true];
                                      }];
            [alert show];
        } else {
            [[RgNetwork instance] login:username password:password callback:^(NSURLSessionTask *operation, id responseObject) {
                [waitView setHidden:true];
                NSDictionary* res = responseObject;
                NSString *ok = [res objectForKey:@"result"];
                if (ok != nil && [ok isEqualToString:@"ok"])
                {
                    // Store login and password
                    LevelDB* cfg = [RgManager configDatabase];
                    [cfg setObject:username forKey:@"ringmail_login"];
                    [cfg setObject:password forKey:@"ringmail_password"];
                    [cfg setObject:@"1" forKey:@"ringmail_verify_email"];
                    [cfg setObject:@"1" forKey:@"ringmail_verify_phone"];
                    [cfg setObject:[res objectForKey:@"phone"] forKey:@"ringmail_phone"];
                    NSLog(@"RingMail Logged In - Config: %@", cfg);
                    [[LinphoneManager instance] setRingLogin:username];
                    [[LinphoneManager instance] startLinphoneCore];
                    [self reset];
                    [self loadWizardConfig:@"wizard_linphone_ringmail.rc"];
                    [self addProxyConfig:[res objectForKey:@"sip_login"] password:[res objectForKey:@"sip_password"]
                                  domain:[RgManager ringmailHostSIP] withTransport:@"tls"];
                    [RgManager updateCredentials:res];
                }
                else
                {
                    NSString* err = [res objectForKey:@"error"];
                    if (err != nil)
                    {
                        NSLog(@"RingMail API Error: %@", err);
                        if ([err isEqualToString:@"verify"])
                        {
                            LevelDB* cfg = [RgManager configDatabase];
                            [cfg setObject:username forKey:@"ringmail_login"];
                            [cfg setObject:password forKey:@"ringmail_password"];
                            [cfg setObject:@"0" forKey:@"ringmail_verify_email"];
                            [self changeView:validateAccountView back:FALSE animation:FALSE];
                        }
                        else if ([err isEqualToString:@"credentials"])
                        {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign In Failure", nil)
                                                                            message:@"Invalid email and password combination."
                                                                           delegate:nil
                                                                  cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil];
                            [alert show];
                        }
                    }
                }
            }
            failure:^(NSURLSessionTask *operation, NSError *error) {
				NSLog(@"RingMail API Error: %@", error);
                LOGI(@"Login failure network error");

                DTAlertView *alert = [[DTAlertView alloc]
                                      initWithTitle:NSLocalizedString(@"Network Error", nil)
                                      message:@"Please try again later"];
                [alert addCancelButtonWithTitle:NSLocalizedString(@"Close", nil)
                                          block:^{
                                              [waitView setHidden:true];
                                          }];
                [alert show];
            }];
        }
    }
}

- (BOOL)verifyRegister:(NSMutableDictionary *)data {
	NSMutableString *errors = [NSMutableString string];
	NSInteger username_length = [[LinphoneManager instance] lpConfigIntForKey:@"username_length" forSection:@"wizard"];
	NSInteger password_length = [[LinphoneManager instance] lpConfigIntForKey:@"password_length" forSection:@"wizard"];
    NSString *username = data[@"email"];
    NSString *password = data[@"password"];
    
    if ([data[@"first_name"] length] < 1 || [data[@"last_name"] length] < 1)
    {
		[errors appendString:@"Please enter your name.\n"];
    }

	if ([username length] < username_length)
    {
		[errors appendString:@"The email is too short.\n"];
	}
    else
    {
    	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".+@.+\\.[A-Za-z]{2}[A-Za-z]*"];
    	if (![emailTest evaluateWithObject:username]) {
    		[errors appendString:NSLocalizedString(@"The email is invalid.\n", nil)];
    	}
    }
    
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    //NSLog(@"RingMail: Country Code: %@", countryCode);
    
    NBPhoneNumberUtil *phoneUtil = [[NBPhoneNumberUtil alloc] init];
    NSError *anError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:data[@"phone"] defaultRegion:countryCode error:&anError];
    if (anError == nil && [phoneUtil isValidNumber:myNumber])
    {
        data[@"phone"] = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&anError];
    }
    else
    {
		[errors appendString:@"The phone number is invalid.\n"];
    }

	if ([password length] < password_length) {
		[errors appendString:@"The password is too short.\n"];
	}

	if ([errors length]) {
		UIAlertView *errorView =
			[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)", nil)
									   message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
									  delegate:nil
							 cancelButtonTitle:NSLocalizedString(@"Continue", nil)
							 otherButtonTitles:nil, nil];
		[errorView show];
		return FALSE;
	}
   	return TRUE;
}

- (IBAction)onRegisterClick:(id)sender {
    
//    [self changeView:validateAccountView back:FALSE animation:TRUE];  //testing the next screen -- REMOVE MB
    
	NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
	NSString *firstname = [WizardViewController findTextField:ViewElement_FirstName view:contentView].text;
	NSString *lastname = [WizardViewController findTextField:ViewElement_LastName view:contentView].text;
	NSString *phone = [WizardViewController findTextField:ViewElement_Phone view:contentView].text;
    NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
	//NSString *password2 = [WizardViewController findTextField:ViewElement_Password2 view:contentView].text;
	__block BOOL google_auth = ([WizardViewController findTextField:ViewElement_Username view:createAccountView].userInteractionEnabled) ? NO : YES;
    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"first_name": firstname,
        @"last_name": lastname,
        @"email": username,
        @"phone": phone,
        @"password": password,
    }];
	if ([self verifyRegister:params])
    {
		username = [username lowercaseString];
		if (google_auth)
		{
            LevelDB* cfg = [RgManager configDatabase];
			params[@"idToken"] = cfg[@"google_oauth2_id_token"];
		}
        [[RgNetwork instance] registerUser:params callback:^(NSURLSessionTask *operation, id responseObject) {
            NSDictionary* res = responseObject;
            NSString *ok = [res objectForKey:@"result"];
            if (ok != nil && [ok isEqualToString:@"ok"])
            {
                // RingMail account created
                LevelDB* cfg = [RgManager configDatabase];
                [cfg setObject:params[@"email"] forKey:@"ringmail_login"];
                [cfg setObject:params[@"password"] forKey:@"ringmail_password"];
                [cfg setObject:params[@"first_name"] forKey:@"ringmail_first_name"];
                [cfg setObject:params[@"last_name"] forKey:@"ringmail_last_name"];
                [cfg setObject:params[@"phone"] forKey:@"ringmail_phone"];
                [cfg setObject:@"" forKey:@"ringmail_chat_password"];
                [cfg setObject:@"0" forKey:@"ringmail_verify_phone"];
				
				if (google_auth)
				{
					[cfg setObject:@"1" forKey:@"ringmail_verify_email"];
					[self changeView:validatePhoneView back:FALSE animation:FALSE];
				}
				else
				{
					[cfg setObject:@"0" forKey:@"ringmail_verify_email"];
					[self changeView:validateAccountView back:FALSE animation:FALSE];
				}
            }
            else
            {
                NSString *err = [res objectForKey:@"error"];
                if ([err isEqualToString:@"duplicate"])
                {
                    UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check issue", nil)
                                               message:[NSString stringWithFormat:@"Duplicate %@", res[@"duplicate"]]
                                              delegate:nil
                                     cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                     otherButtonTitles:nil, nil];
                    [errorView show];
                }
                else
                {
                    UIAlertView *errorView = [[UIAlertView alloc]
                                              initWithTitle:NSLocalizedString(@"Account creation issue", nil)
                                              message:NSLocalizedString(@"Can't create the account. Please try again.", nil)
                                              delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Continue", nil)
                                              otherButtonTitles:nil, nil];
                    [errorView show];
                }
            }
        }];
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[contentView contentSizeToFit];
}

- (IBAction)onViewTap:(id)sender {
	[LinphoneUtils findAndResignFirstResponder:currentView];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) { /* fetch */
		NSString *url = [alertView textFieldAtIndex:0].text;
		if ([url length] > 0) {
			// missing prefix will result in http:// being used
			if ([url rangeOfString:@"://"].location == NSNotFound)
				url = [NSString stringWithFormat:@"http://%@", url];

			LOGI(@"Should use remote provisioning URL %@", url);
			linphone_core_set_provisioning_uri([LinphoneManager getLc], [url UTF8String]);

			[waitView setHidden:false];
			[[LinphoneManager instance] resetLinphoneCore];
		}
	} else {
		LOGI(@"Canceled remote provisioning");
	}
}

#pragma mark - Event Functions

- (void)registrationUpdateEvent:(NSNotification *)notif {
	NSString *message = [notif.userInfo objectForKey:@"message"];
	[self registrationUpdate:[[notif.userInfo objectForKey:@"state"] intValue] message:message];
}

- (void)attemptVerify:(NSNotification *)notif {
	[self verifyEmail];
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

#pragma mark - UIGestureRecognizerDelegate Functions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	if ([touch.view isKindOfClass:[UIButton class]]) {
		/* we resign any keyboard that's displayed when a button is touched */
		if ([LinphoneUtils findAndResignFirstResponder:currentView]) {
			return NO;
		}
	}
	return YES;
}

#pragma mark - Google Sign-In


- (IBAction)onGoogleSignInCustomClick:(id)sender
{
    [[GIDSignIn sharedInstance] signIn];
}


- (void)signInWillDispatch:(GIDSignIn *)signIn error:(NSError *)error {
    //    [myActivityIndicator stopAnimating];
    [waitView setHidden:FALSE];
}

- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    [[NSNotificationCenter defaultCenter] postNotificationName:kRgGoogleSignInStart object:self userInfo:@{@"vc": viewController}];
}

- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
    [[NSNotificationCenter defaultCenter] postNotificationName:kRgGoogleSignInComplete object:self userInfo:nil];
}

- (void)googleSignInVerifedEvent:(NSNotification *)notif
{
    
    GIDGoogleUser *obj = notif.object;
//    NSString *userId = obj.userID;
    __block NSString *idToken = obj.authentication.idToken;
    NSString *login = [NSString stringWithFormat:@"%@", obj.profile.email];
    NSString *accessToken = obj.authentication.accessToken;
    
    if (currentView == choiceView)
    {
        [[RgNetwork instance] loginGoogle:login idToken:idToken accessToken:accessToken callback:^(NSURLSessionTask *operation, id responseObject) {
            NSDictionary* res = responseObject;
            NSString *ok = [res objectForKey:@"result"];
            if (ok != nil && [ok isEqualToString:@"ok"])
            {
                // Store login and password
                LevelDB* cfg = [RgManager configDatabase];
                [cfg setObject:login forKey:@"ringmail_login"];
                [cfg setObject:@"1" forKey:@"ringmail_verify_email"];
                [cfg setObject:@"1" forKey:@"ringmail_verify_phone"];
                [cfg setObject:[res objectForKey:@"phone"] forKey:@"ringmail_phone"];
                NSString *newPW = [res objectForKey:@"ringmail_password"];
                if ([newPW length] != 0)
				{
                    [cfg setObject:newPW forKey:@"ringmail_password"];
				}
                NSLog(@"RingMail Logged In - Config: %@", cfg);
                [[LinphoneManager instance] setRingLogin:login];
                [[LinphoneManager instance] startLinphoneCore];
                [self reset];
                [self loadWizardConfig:@"wizard_linphone_ringmail.rc"];
                [self addProxyConfig:[res objectForKey:@"sip_login"] password:[res objectForKey:@"sip_password"]
                              domain:[RgManager ringmailHostSIP] withTransport:@"tls"];
                [RgManager updateCredentials:res];
                
                // TODO:
                // (create RKContactStore DBs and get any previous RGContacts from server after first app use signin:
                [RgManager updateContacts:res];
                
                [waitView setHidden:TRUE];
                [[PhoneMainView instance] changeCurrentView:[RgHashtagDirectoryViewController compositeViewDescription]];
                [[NSNotificationCenter defaultCenter] postNotificationName:kRgHashtagDirectoryRefreshPath object:nil userInfo:nil];
            }
            else
            {
                NSString* err = [res objectForKey:@"error"];
                if (err != nil)
                {
                    NSLog(@"RingMail API Error: %@", err);
                    if ([err isEqualToString:@"verify"])
                    {
                        LevelDB* cfg = [RgManager configDatabase];
                        [cfg setObject:login forKey:@"ringmail_login"];
                        [cfg setObject:@"" forKey:@"ringmail_password"];
                        [cfg setObject:@"0" forKey:@"ringmail_verify_email"];
                        [self changeView:validateAccountView back:FALSE animation:FALSE];
                    }
                    else if ([err isEqualToString:@"register"])
                    {
                        LevelDB* cfg = [RgManager configDatabase];
                        [cfg setObject:idToken forKey:@"google_oauth2_id_token"];
                        [waitView setHidden:TRUE];
                        
                        [WizardViewController findTextField:ViewElement_Username view:createAccountView].text = obj.profile.email;
                        [WizardViewController findTextField:ViewElement_Username view:createAccountView].userInteractionEnabled = false;
                        [WizardViewController findTextField:ViewElement_FirstName view:createAccountView].text = obj.profile.givenName;
                        [WizardViewController findTextField:ViewElement_LastName view:createAccountView].text = obj.profile.familyName;
                        
                        NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
                        NSMutableString *randomString = [NSMutableString stringWithCapacity: 64];
                        for (int i = 0; i < 64; i++) {
                            [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform(4294967291) % [letters length]]];
                        }
                        
                        [WizardViewController findTextField:ViewElement_Password view:createAccountView].text = randomString;
                        [WizardViewController findTextField:ViewElement_Password view:createAccountView].hidden = true;
                        passwordLabel.hidden = true;
                        [self changeView:createAccountView back:FALSE animation:FALSE];
                    }
                    else if ([err isEqualToString:@"credentials"])
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sign In Failure", nil)
                                                                        message:@"Please complete registration. A phone number is required."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [waitView setHidden:TRUE];
                        [alert show];
                    }
                }
            }
        }
        failure:^(NSURLSessionTask *operation, NSError *error) {
            LOGI(@"Login failure network error");
            
            DTAlertView *alert = [[DTAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Network Error", nil)
                                  message:@"Please try again later"];
            [alert addCancelButtonWithTitle:NSLocalizedString(@"Close", nil)
                                      block:^{
                                          [waitView setHidden:true];
                                      }];
            [waitView setHidden:TRUE];
            [alert show];
            
        }];
    
    }
}

- (void)googleSignInErrorEvent:(NSNotification *)notif
{
    [waitView setHidden:TRUE];
}


@end
