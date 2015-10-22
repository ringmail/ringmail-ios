
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
#import "UITextField+DoneButton.h"

#import "DTAlertView.h"
#import "RgNetwork.h"

typedef enum _ViewElement {
	ViewElement_Username = 100,
	ViewElement_Password = 101,
	ViewElement_Password2 = 102,
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
@synthesize waitView;

@synthesize backButton;
@synthesize createAccountButton;
@synthesize connectAccountButton;
@synthesize remoteProvisioningButton;

@synthesize choiceViewLogoImageView;

@synthesize viewTapGestureRecognizer;

@synthesize verifyEmailLabel;

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
																 tabBar:nil
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
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(registrationUpdateEvent:)
												 name:kLinphoneRegistrationUpdate
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(configuringUpdate:)
												 name:kLinphoneConfiguringStateUpdate
											   object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(checkValidation:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[viewTapGestureRecognizer setCancelsTouchesInView:FALSE];
	[viewTapGestureRecognizer setDelegate:self];
	[contentView addGestureRecognizer:viewTapGestureRecognizer];

	/*if ([LinphoneManager runningOnIpad]) {
		[LinphoneUtils adjustFontSize:choiceView mult:2.22f];
		[LinphoneUtils adjustFontSize:createAccountView mult:2.22f];
		[LinphoneUtils adjustFontSize:connectAccountView mult:2.22f];
		[LinphoneUtils adjustFontSize:validateAccountView mult:2.22f];
	}*/
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
	[self resetTextFields];
    if ([RgManager configReady])
    {
        [self changeView:validateAccountView back:FALSE animation:FALSE];
    }
    else
    {
        [self changeView:choiceView back:FALSE animation:FALSE];
    }
	[waitView setHidden:TRUE];
    
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

- (void)checkValidation:(NSNotification *)notif {
    // Check once if validated, if so, this screen can be skipped
    if ([RgManager configReady] && ! [RgManager configVerified])
    {
        [RgManager verifyLogin:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary* res = responseObject;
            NSLog(@"RingMail: Check Validation: %@", res);
            NSString *ok = [res objectForKey:@"result"];
            if ([ok isEqualToString:@"ok"])
            {
                [self addProxyConfig:[res objectForKey:@"sip_login"] password:[res objectForKey:@"sip_password"]
                              domain:[RgManager ringmailHostSIP] withTransport:@"tls"];
                [RgManager updateCredentials:res];
            }
        }];
    }
}

- (void)changeView:(UIView *)view back:(BOOL)back animation:(BOOL)animation {

	// Change toolbar buttons following view
    
	if (view == validateAccountView) {
		[backButton setEnabled:FALSE];
        [backButton setHidden:TRUE];
        
	} else if (view == choiceView) {
        [backButton setEnabled:FALSE];
        [backButton setHidden:TRUE];
	} else {
		[backButton setEnabled:TRUE];
        [backButton setHidden:FALSE];
	}
    
    if (view == validateAccountView)
    {
        LevelDB* cfg = [RgManager configDatabase];
        NSLog(@"RingMail: Change View - validate: %@", [cfg objectForKey:@"ringmail_login"]);
        [verifyEmailLabel setText:[cfg objectForKey:@"ringmail_login"]];
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
		[waitView setHidden:true];
		[[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription]];
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
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	activeTextField = textField;
}

- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
	// only validate the username when creating a new account
	if ((textField.tag == ViewElement_Username) && (currentView == createAccountView)) {
		BOOL isValidUsername = YES;

        NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern:@"^[a-z0-9-_\\.@+]*$"
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:nil];

        NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
        isValidUsername = ([matches count] != 0);

		if (!isValidUsername) {
			UILabel *error = [WizardViewController findLabel:ViewElement_Username_Error view:contentView];

			// show error with fade animation
			[error setText:[NSString stringWithFormat:NSLocalizedString(@"Illegal character in %@: %@", nil), NSLocalizedString(@"username", nil), string]];
			error.alpha = 0;
			error.hidden = NO;
			[UIView animateWithDuration:0.3
							 animations:^{
							   error.alpha = 1;
							 }];

			// hide again in 2s
			[NSTimer scheduledTimerWithTimeInterval:2.0f
											 target:self
										   selector:@selector(hideError:)
										   userInfo:nil
											repeats:NO];
			return NO;
		}
	}
	return YES;
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
		UIView *view = [historyViews lastObject];
		[historyViews removeLastObject];
		[self changeView:view back:TRUE animation:TRUE];
	}
}

- (IBAction)onCreateAccountClick:(id)sender {
	nextView = createAccountView;
	[self loadWizardConfig:@"wizard_linphone_ringmail.rc"];
}

- (IBAction)onConnectLinphoneAccountClick:(id)sender {
	nextView = connectAccountView;
	[self loadWizardConfig:@"wizard_linphone_ringmail.rc"];
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
    [[RgNetwork instance] resendVerify:@{@"email": [cfg objectForKey:@"ringmail_login"]} callback:^(AFHTTPRequestOperation *operation, id responseObject) {
        [waitView setHidden:true];
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

- (IBAction)onCheckValidationClick:(id)sender {
    [RgManager verifyLogin:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary* res = responseObject;
        NSString *ok = [res objectForKey:@"result"];
        if ([ok isEqualToString:@"ok"])
        {
            [self addProxyConfig:[res objectForKey:@"sip_login"] password:[res objectForKey:@"sip_password"]
                          domain:[RgManager ringmailHostSIP] withTransport:@"tls"];
            [RgManager updateCredentials:res];
        }
        else
        {
            UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:@"Email Not Verified"
                           message:@"Please verify your email address to continue"
                          delegate:nil
                 cancelButtonTitle:@"OK"
                 otherButtonTitles:nil, nil];
            [errorView show];
        }
    }];
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
            [[RgNetwork instance] login:username password:password callback:^(AFHTTPRequestOperation *operation, id responseObject) {
                [waitView setHidden:true];
                NSDictionary* res = responseObject;
                NSString *ok = [res objectForKey:@"result"];
                if ([ok isEqualToString:@"ok"])
                {
                    // Store login and password
                    LevelDB* cfg = [RgManager configDatabase];
                    [cfg setObject:username forKey:@"ringmail_login"];
                    [cfg setObject:password forKey:@"ringmail_password"];
                    [[LinphoneManager instance] setRingLogin:username];
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
                            [self changeView:validateAccountView back:FALSE animation:TRUE];
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
            }];
        }
    }
}

- (BOOL)verificationRegisterWithUsername:(NSString *)username
								password:(NSString *)password
							   password2:(NSString *)password2 {
	NSMutableString *errors = [NSMutableString string];
	NSInteger username_length = [[LinphoneManager instance] lpConfigIntForKey:@"username_length" forSection:@"wizard"];
	NSInteger password_length = [[LinphoneManager instance] lpConfigIntForKey:@"password_length" forSection:@"wizard"];

	if ([username length] < username_length) {
		[errors
			appendString:[NSString stringWithFormat:NSLocalizedString(@"The email is too short (minimum %d characters).\n", nil), username_length]];
	}

	if ([password length] < password_length) {
		[errors
			appendString:[NSString stringWithFormat:NSLocalizedString(
														@"The password is too short (minimum %d characters).\n", nil),
													password_length]];
	}

	if (![password2 isEqualToString:password]) {
		[errors appendString:NSLocalizedString(@"The passwords are different.\n", nil)];
	}

	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".+@.+\\.[A-Za-z]{2}[A-Za-z]*"];
	if (![emailTest evaluateWithObject:username]) {
		[errors appendString:NSLocalizedString(@"The email is invalid.\n", nil)];
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
	UITextField *username_tf = [WizardViewController findTextField:ViewElement_Username view:contentView];
	NSString *username = username_tf.text;
	NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
	NSString *password2 = [WizardViewController findTextField:ViewElement_Password2 view:contentView].text;

	if ([self verificationRegisterWithUsername:username password:password password2:password2]) {
		username = [username lowercaseString];
		[username_tf setText:username];
        NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:username, @"email", password, @"password", nil];
        [[RgNetwork instance] registerUser:params callback:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSDictionary* res = responseObject;
            NSString *ok = [res objectForKey:@"result"];
            if (! [ok isEqualToString:@"ok"])
            {
                NSString *err = [res objectForKey:@"error"];
                if ([err isEqualToString:@"duplicate"])
                {
                    UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check issue", nil)
                                               message:NSLocalizedString(@"Email already exists", nil)
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
            else
            {
                // RingMail account created
                LevelDB* cfg = [RgManager configDatabase];
                [cfg setObject:username forKey:@"ringmail_login"];
                [cfg setObject:password forKey:@"ringmail_password"];
                [cfg setObject:@"" forKey:@"ringmail_chat_password"];
                [cfg setObject:@"0" forKey:@"ringmail_verify_email"];
                [self changeView:validateAccountView back:FALSE animation:TRUE];
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

- (void)configuringUpdate:(NSNotification *)notif {
	LinphoneConfiguringState status = (LinphoneConfiguringState)[[notif.userInfo valueForKey:@"state"] integerValue];

	[waitView setHidden:true];

	switch (status) {
	case LinphoneConfiguringSuccessful:
		if (nextView == nil) {
			[self fillDefaultValues];
		} else {
			[self changeView:nextView back:false animation:TRUE];
			nextView = nil;
		}
		break;
	case LinphoneConfiguringFailed: {
		NSString *error_message = [notif.userInfo valueForKey:@"message"];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Provisioning Load error", nil)
														message:error_message
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"OK", nil)
											  otherButtonTitles:nil];
		[alert show];
		break;
	}

	case LinphoneConfiguringSkipped:
	default:
		break;
	}
}

#pragma mark - Event Functions

- (void)registrationUpdateEvent:(NSNotification *)notif {
	NSString *message = [notif.userInfo objectForKey:@"message"];
	[self registrationUpdate:[[notif.userInfo objectForKey:@"state"] intValue] message:message];
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

@end
