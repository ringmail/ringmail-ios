/* ChatRoomViewController.m
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

#import "ChatRoomViewController.h"
#import "PhoneMainView.h"
#import "LinphoneManager.h"
#import "DTActionSheet.h"
#import "DTAlertView.h"
#import <NinePatch.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "Utils.h"
#import "RgChatModelData.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"

@implementation ChatRoomViewController

@synthesize editButton;
@synthesize addressLabel;
@synthesize avatarImage;
@synthesize headerView;
@synthesize originalToView;
@synthesize originalToLabel;
@synthesize chatView;
@synthesize chatViewController;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"ChatRoomViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
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
		compositeDescription = [[UICompositeViewDescription alloc] init:@"ChatRoom"
																content:@"ChatRoomViewController"
															   stateBar:nil
														stateBarEnabled:false
																 tabBar:/*@"UIMainBar"*/ nil
														  tabBarEnabled:false /*to keep room for chat*/
															 fullscreen:false
														  landscapeMode:true
														   portraitMode:true];
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];

	// Set selected+over background: IB lack !
	[editButton setBackgroundImage:[UIImage imageNamed:@"chat_ok_over.png"]
						  forState:(UIControlStateHighlighted | UIControlStateSelected)];

	[LinphoneUtils buttonFixStates:editButton];
	
	UITapGestureRecognizer *tapContact = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContactClick:)];
    tapContact.numberOfTapsRequired = 1;
    [addressLabel addGestureRecognizer:tapContact];
    addressLabel.userInteractionEnabled = YES;
	
	UITapGestureRecognizer *tapContactImg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContactClick:)];
    tapContactImg.numberOfTapsRequired = 1;
    [avatarImage addGestureRecognizer:tapContactImg];
    avatarImage.userInteractionEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillEnterForeground:)
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatReceivedEvent:)
                                                 name:kRgTextReceived
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatSentEvent:)
                                                 name:kRgTextSent
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(chatUpdateEvent:)
                                                 name:kRgTextUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactRefreshEvent:)
                                                 name:kRgContactRefresh
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUserActivity)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
	[editButton setOff];
    
    RgMessagesViewController* mc = [RgMessagesViewController messagesViewController];
    NSNumber *room = [[LinphoneManager instance] chatSession];
    
    RgChatModelData* cdata = [[RgChatModelData alloc] initWithChatRoom:room];
    [mc setChatData:cdata];
    [mc setChatSession:room]; // loads the data
    [self setChatViewController:mc];
    [self update];
    
    [mc view].autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [mc view].frame = chatView.superview.bounds;
    [chatView addSubview:[mc view]];
    //[[NSNotificationCenter defaultCenter] postNotificationName:kRgTextReceived object:self];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[self.chatViewController view] removeFromSuperview];
    [self setChatViewController:nil]; // De-allocate
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark -

- (void)update {
	LinphoneManager *lm = [LinphoneManager instance];
    NSNumber *session = [lm chatSession];
    NSLog(@"RingMail Chat Update: %@", session);
    if ([session intValue] != 0)
    {
        UIImage *image = nil;
		NSDictionary *sdata = [[lm chatManager] dbGetSessionData:session];
        //NSLog(@"RingMail Chat Session Data: %@", sdata);
        NSString *displayName = sdata[@"session_tag"];
        ABRecordRef acontact = NULL;
		if (! [sdata[@"contact_id"] isKindOfClass:[NSNull class]])
		{
			acontact = [[lm fastAddressBook] getContactById:sdata[@"contact_id"]];
		}
        else
        {
			acontact = [[lm fastAddressBook] getContact:sdata[@"session_tag"]];
        }
        if (acontact != NULL)
        {
            displayName = [FastAddressBook getContactDisplayName:acontact];
            image = [FastAddressBook getContactImage:acontact thumbnail:true];
        }
        addressLabel.text = displayName;
        addressLabel.accessibilityValue = displayName;
        
        // Original To
        if (! [sdata[@"session_to"] isEqualToString:@""])
        {
            originalToView.hidden = NO;
            [originalToLabel setText:sdata[@"session_to"]];
        }
        else
        {
            // No Original-To
            originalToView.hidden = YES;
        }

        // Avatar
        if (image == nil) {
            image = [UIImage imageNamed:@"avatar_unknown_small.png"];
        }
        
        //UIImage *smallImage = [image thumbnailImage:56 transparentBorder:0 cornerRadius:28 interpolationQuality:kCGInterpolationHigh];
        JSQMessagesAvatarImage *smallAvatar = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:28];
        [chatViewController.chatData.avatars setObject:smallAvatar forKey:@"avatar"];
        
        image = [image thumbnailImage:84 transparentBorder:0 cornerRadius:42 interpolationQuality:kCGInterpolationHigh];
        [avatarImage setImage:image];
    }
}

#pragma mark - Event Functions

- (void)chatReceivedEvent:(NSNotification *)notif {
    NSNumber *room = [[notif userInfo] objectForKey:@"session"];
    NSLog(@"receive event: %@", room);
    if ([room isEqualToNumber:chatViewController.chatSession])
    {
        if ([[notif userInfo] objectForKey:@"error"] != nil)
        {
            NSString *error = [[notif userInfo] objectForKey:@"error"];
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *errorAlert = [[UIAlertView alloc]
                                           initWithTitle:@"Error"
                                           message:error
                                           delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                                           otherButtonTitles:nil, nil];
                [errorAlert show];
            });
        }
        else
        {
            [chatViewController receiveMessage:[[notif userInfo] objectForKey:@"uuid"]];
        }
    }
}

- (void)chatSentEvent:(NSNotification *)notif {
    NSNumber *room = [[notif userInfo] objectForKey:@"session"];
    if ([room isEqualToNumber:chatViewController.chatSession])
    {
        [chatViewController sentMessage];
    }
}

- (void)chatUpdateEvent:(NSNotification *)notif {
    NSNumber *room = [[notif userInfo] objectForKey:@"session"];
    if ([room isEqualToNumber:chatViewController.chatSession])
    {
        if ([[notif userInfo] objectForKey:@"status"])
        {
            [chatViewController updateMessages:nil]; // just refresh the current screen
        }
        else
        {
            [chatViewController updateMessages:[[notif userInfo] objectForKey:@"uuid"]];
        }
    }
}

- (void)contactRefreshEvent:(NSNotification *)notif {
    [self update];
    //[chatViewController updateMessages:nil];
}

#pragma mark - Action Functions

- (IBAction)onBackClick:(id)event {
	[[PhoneMainView instance] popCurrentView];
}

- (IBAction)onEditClick:(id)event {
	//[tableController setEditing:![tableController isEditing] animated:TRUE];
	//[messageField resignFirstResponder];
}

- (IBAction)onCallClick:(id)sender {
    NSNumber *session = [chatViewController chatSession];
    if ([session intValue] != 0)
    {
		NSDictionary *sdata = [[[LinphoneManager instance] chatManager] dbGetSessionData:session];
		ABRecordRef contact = NULL;
		if (! [sdata[@"contact_id"] isKindOfClass:[NSNull class]])
		{
			contact = [[[LinphoneManager instance] fastAddressBook] getContactById:sdata[@"contact_id"]];
		}
        [RgManager startCall:sdata[@"session_tag"] contact:contact video:NO];
    }
}

- (IBAction)onVideoClick:(id)sender {
    NSNumber *session = [chatViewController chatSession];
    if ([session intValue] != 0)
    {
    	NSDictionary *sdata = [[[LinphoneManager instance] chatManager] dbGetSessionData:session];
    	ABRecordRef contact = NULL;
    	if (! [sdata[@"contact_id"] isKindOfClass:[NSNull class]])
    	{
    		contact = [[[LinphoneManager instance] fastAddressBook] getContactById:sdata[@"contact_id"]];
    	}
        [RgManager startCall:sdata[@"session_tag"] contact:contact video:YES];
	}
}

- (IBAction)onContactClick:(id)sender {
    NSNumber *session = [chatViewController chatSession];
    if ([session intValue] != 0)
    {
		ABRecordRef contact = NULL;
    	NSDictionary *sdata = [[[LinphoneManager instance] chatManager] dbGetSessionData:session];
    	if (! [sdata[@"contact_id"] isKindOfClass:[NSNull class]])
    	{
    		contact = [[[LinphoneManager instance] fastAddressBook] getContactById:sdata[@"contact_id"]];
    	}
        else
        {
    		contact = [[[LinphoneManager instance] fastAddressBook] getContact:sdata[@"session_tag"]];
        }
        if (contact)
        {
            ContactDetailsViewController *controller = DYNAMIC_CAST(
                [[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE],
                ContactDetailsViewController);
            if (controller != nil) {
        		// Go to Contact details view
           		[controller setContact:contact];
        	}
        }
    	else
    	{
       		[[PhoneMainView instance] promptNewOrEdit:sdata[@"session_tag"]];
    	}
	}
}

- (void)handleUserActivity {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSString *msgTextString = [defaults stringForKey:@"msgText"];
    
    if (![msgTextString isEqual: @""]) {
        
        [defaults setObject:@"" forKey:@"msgText"];
        
        
    }

}

@end
