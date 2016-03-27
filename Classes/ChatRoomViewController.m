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
#import "DTActionSheet.h"
#import "UILinphone.h"
#import "DTAlertView.h"
#import "Utils/FileTransferDelegate.h"
#import <NinePatch.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "Utils.h"
#import "UIChatRoomCell.h"
#import "RgChatModelData.h"

#import "UIImage+RoundedCorner.h"
#import "UIImage+Resize.h"

@implementation ChatRoomViewController

@synthesize editButton;
@synthesize addressLabel;
@synthesize avatarImage;
@synthesize headerView;
@synthesize chatView;
@synthesize chatViewController;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"ChatRoomViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		self->scrollOnGrowingEnabled = TRUE;
		self->chatRoom = NULL;
		self->imageQualities = [[OrderedDictionary alloc]
			initWithObjectsAndKeys:[NSNumber numberWithFloat:0.9], NSLocalizedString(@"Maximum", nil),
								   [NSNumber numberWithFloat:0.5], NSLocalizedString(@"Average", nil),
								   [NSNumber numberWithFloat:0.0], NSLocalizedString(@"Minimum", nil), nil];
		self->composingVisible = TRUE;
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
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillEnterForeground:)
												 name:UIApplicationDidBecomeActiveNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textComposeEvent:)
												 name:kLinphoneTextComposeEvent
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
	[editButton setOff];
    
    RgMessagesViewController* mc = [RgMessagesViewController messagesViewController];
    NSString *room = [[LinphoneManager instance] chatTag];
    
    RgChatModelData* cdata = [[RgChatModelData alloc] initWithChatRoom:room];
    [mc setChatData:cdata];
    [mc setChatRoom:room]; // loads the data
    [self setChatViewController:mc];
    [self update];
    
    [mc view].autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [mc view].frame = chatView.superview.bounds;
    [chatView addSubview:[mc view]];
    //[[NSNotificationCenter defaultCenter] postNotificationName:kRgTextReceived object:self];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self setComposingVisible:FALSE withDelay:0]; // will hide the "user is composing.." message

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

- (void)setChatRoom:(LinphoneChatRoom *)room {
	self->chatRoom = room;
}

- (void)applicationWillEnterForeground:(NSNotification *)notif {
	if (chatRoom != nil) {
		linphone_chat_room_mark_as_read(chatRoom);
		[[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneTextReceived object:self];
	}
}

- (void)update {
    NSString *chatTag = [[LinphoneManager instance] chatTag];
    NSLog(@"RingMail Chat Update: %@", chatTag);
    if (! [chatTag isEqualToString:@""])
    {
        NSString *displayName = chatTag;
        UIImage *image = nil;

        ABRecordRef acontact = [[[LinphoneManager instance] fastAddressBook] getContact:displayName];
        if (acontact != nil) {
            displayName = [FastAddressBook getContactDisplayName:acontact];
            image = [FastAddressBook getContactImage:acontact thumbnail:true];
        }

        addressLabel.text = displayName;
        addressLabel.accessibilityValue = displayName;

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

static void message_status(LinphoneChatMessage *msg, LinphoneChatMessageState state, void *ud) {
	const char *text = (linphone_chat_message_get_file_transfer_information(msg) != NULL)
						   ? "photo transfer"
						   : linphone_chat_message_get_text(msg);
	LOGI(@"Delivery status for [%s] is [%s]", text, linphone_chat_message_state_to_string(state));
	//ChatRoomViewController *thiz = (__bridge ChatRoomViewController *)ud;
	//[thiz.tableController updateChatEntry:msg];
}

- (BOOL)sendMessage:(NSString *)message withExterlBodyUrl:(NSURL *)externalUrl withInternalURL:(NSURL *)internalUrl {
	if (chatRoom == NULL) {
		LOGW(@"Cannot send message: No chatroom");
		return FALSE;
	}

	LinphoneChatMessage *msg = linphone_chat_room_create_message(chatRoom, [message UTF8String]);
	if (externalUrl) {
		linphone_chat_message_set_external_body_url(msg, [[externalUrl absoluteString] UTF8String]);
	}

	linphone_chat_room_send_message2(chatRoom, msg, message_status, (__bridge void *)(self));

	if (internalUrl) {
		// internal url is saved in the appdata for display and later save
		[LinphoneManager setValueInMessageAppData:[internalUrl absoluteString] forKey:@"localimage" inMessage:msg];
	}

	//[tableController addChatEntry:msg];
	//[tableController scrollToBottom:true];
	return TRUE;
}

- (void)saveAndSend:(UIImage *)image url:(NSURL *)url {
	// photo from Camera, must be saved first
	if (url == nil) {
		[[LinphoneManager instance]
				.photoLibrary
			writeImageToSavedPhotosAlbum:image.CGImage
							 orientation:(ALAssetOrientation)[image imageOrientation]
						 completionBlock:^(NSURL *assetURL, NSError *error) {
						   if (error) {
							   LOGE(@"Cannot save image data downloaded [%@]", [error localizedDescription]);

							   UIAlertView *errorAlert = [[UIAlertView alloc]
									   initWithTitle:NSLocalizedString(@"Transfer error", nil)
											 message:NSLocalizedString(@"Cannot write image to photo library", nil)
											delegate:nil
								   cancelButtonTitle:NSLocalizedString(@"Ok", nil)
								   otherButtonTitles:nil, nil];
							   [errorAlert show];
						   } else {
							   LOGI(@"Image saved to [%@]", [assetURL absoluteString]);
							   [self chatRoomStartImageUpload:image url:assetURL];
						   }
						 }];
	} else {
		[self chatRoomStartImageUpload:image url:url];
	}
}

- (void)chooseImageQuality:(UIImage *)image url:(NSURL *)url {
	DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:NSLocalizedString(@"Choose the image size", nil)];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	  // UIImage *image = [original_image normalizedImage];
	  for (NSString *key in [imageQualities allKeys]) {
		  NSNumber *number = [imageQualities objectForKey:key];
		  NSData *data = UIImageJPEGRepresentation(image, [number floatValue]);
		  NSNumber *size = [NSNumber numberWithInteger:[data length]];

		  NSString *text = [NSString stringWithFormat:@"%@ (%@)", key, [size toHumanReadableSize]];
		  [sheet addButtonWithTitle:text
							  block:^() {
								[self saveAndSend:[UIImage imageWithData:data] url:url];
							  }];
	  }
	  [sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
	  dispatch_async(dispatch_get_main_queue(), ^{
		[sheet showInView:[PhoneMainView instance].view];
	  });
	});
}

- (void)setComposingVisible:(BOOL)visible withDelay:(CGFloat)delay {

	if (composingVisible == visible)
		return;
	composingVisible = visible;
}

#pragma mark - Event Functions

- (void)textComposeEvent:(NSNotification *)notif {
	LinphoneChatRoom *room = [[[notif userInfo] objectForKey:@"room"] pointerValue];
	if (room && room == chatRoom) {
		BOOL composing = linphone_chat_room_is_remote_composing(room);
		[self setComposingVisible:composing withDelay:0.3];
	}
}

- (void)chatReceivedEvent:(NSNotification *)notif {
    NSString *room = [[notif userInfo] objectForKey:@"tag"];
    NSLog(@"receive event: %@", room);
    if ([room isEqualToString:chatViewController.chatRoom])
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
    NSString *room = [[notif userInfo] objectForKey:@"tag"];
    if ([room isEqualToString:chatViewController.chatRoom])
    {
        [chatViewController sentMessage];
    }
}

- (void)chatUpdateEvent:(NSNotification *)notif {
    NSString *room = [[notif userInfo] objectForKey:@"tag"];
    if ([room isEqualToString:chatViewController.chatRoom])
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

#pragma mark - Action Functions

- (IBAction)onBackClick:(id)event {
	//[self.tableController setChatRoom:NULL];
	[[PhoneMainView instance] popCurrentView];
}

- (IBAction)onEditClick:(id)event {
	//[tableController setEditing:![tableController isEditing] animated:TRUE];
	//[messageField resignFirstResponder];
}

#pragma mark ChatRoomDelegate

- (BOOL)chatRoomStartImageUpload:(UIImage *)image url:(NSURL *)url {
	FileTransferDelegate *fileTransfer = [[FileTransferDelegate alloc] init];
	[fileTransfer upload:image withURL:url forChatRoom:chatRoom];
	//[tableController addChatEntry:linphone_chat_message_ref(fileTransfer.message)];
	//[tableController scrollToBottom:true];
	return TRUE;
}

- (void)resendChat:(NSString *)message withExternalUrl:(NSString *)url {
	[self sendMessage:message withExterlBodyUrl:[NSURL URLWithString:url] withInternalURL:nil];
}

#pragma mark ImagePickerDelegate

- (void)imagePickerDelegateImage:(UIImage *)image info:(NSDictionary *)info {
	// Dismiss popover on iPad
	if ([LinphoneManager runningOnIpad]) {
		UICompositeViewDescription *description = [ImagePickerViewController compositeViewDescription];
		ImagePickerViewController *controller =
			DYNAMIC_CAST([[PhoneMainView instance].mainViewController getCachedController:description.content],
						 ImagePickerViewController);
		if (controller != nil) {
			[controller.popoverController dismissPopoverAnimated:TRUE];
		}
	}

	NSURL *url = [info valueForKey:UIImagePickerControllerReferenceURL];
	[self chooseImageQuality:image url:url];
}

@end
