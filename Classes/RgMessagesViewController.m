#import "Utils.h"
#import "RgMessagesViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "DTActionSheet.h"
#import "NYXImagesKit/NYXImagesKit.h"
#import "RgChatQuestionSelect.h"
#import "JSQMessagesCollectionViewFlowLayout.h"


@implementation RgMessagesViewController

@synthesize chatSession = _chatSession;
@synthesize chatData;
@synthesize popoverController;
@synthesize imageCache;

#pragma mark - Init

#pragma mark - View lifecycle

- (id)init
{
    if (self = [super init])
    {
        self.chatSession = [NSNumber numberWithInt:0];
        self.imageCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"RingMail Messages";
    
    //self.chatData = [[RgChatModelData alloc] initWithChatRoom:self.chatRoom];
    self.senderId = kRgSelf;
    self.senderDisplayName = kRgSelfName;
    
    //self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeMake(28.0f, 28.0f);
    //self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeMake(20.0f, 20.0f);
    
    self.collectionView.collectionViewLayout.messageBubbleFont = [UIFont fontWithName:@"HelveticaNeue" size:16];
    self.collectionView.collectionViewLayout.messageBubbleTextViewFrameInsets = UIEdgeInsetsMake(2.0f, 4.0f, 0.0f, 2.0f);
    
    self.showLoadEarlierMessagesHeader = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //self.collectionView.collectionViewLayout.springinessEnabled = YES;
}

#pragma mark - Chat room switch

- (void)setChatRoom:(NSNumber *)session
{
    _chatSession = session;
    [self.chatData setChatSession:session];
    [self.chatData loadMessages];
}

#pragma mark - Actions

- (void)receiveMessage:(NSString*)uuid
{
    dispatch_async(dispatch_get_main_queue(), ^{
		NSLog(@"RingMail: receiveMessage");
        [self.chatData loadMessages:uuid];
        //[self.collectionView reloadData];
        //[self scrollToBottomAnimated:YES];
        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
        //[[JSQSystemSoundPlayer sharedPlayer] playSoundWithFilename:@"chat_in_view" fileExtension:kJSQSystemSoundTypeWAV];
        [self finishReceivingMessageAnimated:YES];
    });
}

- (void)sentMessage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.chatData loadMessages];
        //[self.collectionView reloadData];
        //[self scrollToBottomAnimated:YES];
        [JSQSystemSoundPlayer jsq_playMessageSentSound];
        //[[JSQSystemSoundPlayer sharedPlayer] playSoundWithFilename:@"chat_in_view" fileExtension:kJSQSystemSoundTypeWAV];
        [self finishSendingMessageAnimated:YES];
    });
}

- (void)updateMessages:(NSString*)uuid
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (uuid)
        {
            [self.chatData updateMessage:uuid];
        }
        [self.collectionView reloadData];
    });
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
    void (^showAppropriateController)(UIImagePickerControllerSourceType) =
    ^(UIImagePickerControllerSourceType type) {
        UICompositeViewDescription *description = [ImagePickerViewController compositeViewDescription];
        ImagePickerViewController *controller;
        if ([LinphoneManager runningOnIpad]) {
            controller = DYNAMIC_CAST(
                                      [[PhoneMainView instance].mainViewController getCachedController:description.content],
                                      ImagePickerViewController);
            // keep a reference to this controller so that in case of memory pressure we keep it
            self.popoverController = controller;
        } else {
            controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:description push:TRUE],
                                      ImagePickerViewController);
        }
        if (controller != nil) {
            controller.sourceType = type;
            
            // Displays a control that allows the user to choose picture or
            // movie capture, if both are available:
            controller.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
            
            // Hides the controls for moving & scaling pictures, or for
            // trimming movies. To instead show the controls, use YES.
            controller.allowsEditing = NO;
            controller.imagePickerDelegate = self;
            
            /*if ([LinphoneManager runningOnIpad]) {
                [controller.popoverController presentPopoverFromRect:[avatarImage frame]
                                                              inView:self.view
                                            permittedArrowDirections:UIPopoverArrowDirectionAny
                                                            animated:FALSE];
            }*/
        }
    };
    DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Option", nil)];
    /*[sheet addButtonWithTitle:NSLocalizedString(@"Ping", nil)
                        block:^() {
                            NSLog(@"RingMail: Send a ping");
                            NSString *uuid = [[[LinphoneManager instance] chatManager] sendPingTo:_chatRoom reply:nil];
                            [self.chatData loadMessages:uuid];
                            [JSQSystemSoundPlayer jsq_playMessageSentSound];
                            [self finishSendingMessageAnimated:YES];
                        }];*/
    /*[sheet addButtonWithTitle:NSLocalizedString(@"Question", nil) block:^() {
        [[PhoneMainView instance] changeCurrentView:[RgChatQuestionSelect compositeViewDescription] push:TRUE];
    }];*/
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Camera", nil)
                            block:^() {
                                showAppropriateController(UIImagePickerControllerSourceTypeCamera);
                            }];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Photos", nil)
                            block:^() {
                                showAppropriateController(UIImagePickerControllerSourceTypePhotoLibrary);
                            }];
    }
    [sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil)
                              block:^{
                                  self.popoverController = nil;
                              }];
    [sheet showInView:[PhoneMainView instance].view];
}

#pragma mark - ImagePickerDelegate Functions

- (void)imagePickerDelegateImage:(UIImage *)image info:(NSDictionary *)info {
    // Dismiss popover on iPad
    /*if ([LinphoneManager runningOnIpad]) {
        UICompositeViewDescription *description = [ImagePickerViewController compositeViewDescription];
        ImagePickerViewController *controller =
        DYNAMIC_CAST([[PhoneMainView instance].mainViewController getCachedController:description.content],
                     ImagePickerViewController);
        if (controller != nil) {
            [controller.popoverController dismissPopoverAnimated:TRUE];
            self.popoverController = nil;
        }
    }*/
	
	image = [self normalizedImage:image];
    UIImage *imageSized = [image scaleToFitSize:(CGSize){3264, 3264}];
    
    RgChatManager* mgr = [[LinphoneManager instance] chatManager];
	NSDictionary *sdata = [mgr dbGetSessionData:_chatSession];
    [mgr sendMessageTo:sdata[@"session_tag"] from:NILIFNULL(sdata[@"session_to"]) image:imageSized contact:NILIFNULL(sdata[@"contact_id"])];
    
    NSDictionary *dict = @{
        @"session":_chatSession
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:kRgTextSent object:self userInfo:dict];
    
    //JSQPhotoMediaItem* mediaData = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageNamed:@"ringmail_email1"]];
    //mediaData.appliesMediaViewMaskAsOutgoing = NO;
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    
    if([text length] > 0)
    {
        //NSLog(@"RingMail - Send Message To: %@ -> %@", _chatRoom, msgTo);
        RgChatManager* mgr = [[LinphoneManager instance] chatManager];
		NSDictionary *sdata = [mgr dbGetSessionData:_chatSession];
		NSString *origTo = NILIFNULL(sdata[@"session_to"]);
        NSString *uuid = [mgr sendMessageTo:sdata[@"session_tag"] from:origTo body:text contact:NILIFNULL(sdata[@"contact_id"])];
        [self.chatData loadMessages:uuid];
        //[JSQSystemSoundPlayer jsq_playMessageSentSound];
        [[JSQSystemSoundPlayer sharedPlayer] playSoundWithFilename:@"chat_send" fileExtension:kJSQSystemSoundTypeWAV];
        [self finishSendingMessageAnimated:YES];
    }
}

#pragma mark - RingMail message data

-(JSQMessage*)getMessageAtIndex:(NSUInteger)index
{
    NSObject* data = [self.chatData.messages objectAtIndex:index];
    JSQMessage* result = nil;
    if ([data isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *lazy = (NSDictionary*)data;
        NSNumber* imageID = [lazy objectForKey:@"id"];
        UIImage* image = [self getImageByID:imageID key:@"msg_thumbnail"];
        JSQPhotoMediaItem* mediaData = [[JSQPhotoMediaItem alloc] initWithImage:image];
        if ([(NSString*)[lazy objectForKey:@"direction"] isEqualToString:@"inbound"])
        {
            [mediaData setAppliesMediaViewMaskAsOutgoing:false];
        }
        result = [[JSQMessage alloc] initWithSenderId:[lazy objectForKey:@"sender"]
                                                      senderDisplayName:[lazy objectForKey:@"senderName"]
                                                        date:[lazy objectForKey:@"time"]
                                                       media:mediaData];
    }
    else
    {
        result = (JSQMessage*)data;
    }
    return (result);
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self getMessageAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self getMessageAtIndex:indexPath.item];
    id messageData = [self.chatData.messageData objectAtIndex:indexPath.item];
    if (! [messageData isEqual:[NSNull null]])
    {
        NSDictionary* jsonInfo = (NSDictionary*)messageData;
        NSString* jsonType = [jsonInfo objectForKey:@"type"];
        if ([jsonType isEqualToString:@"question"])
        {
            if (! [message.senderId isEqualToString:self.senderId] && ! [jsonInfo objectForKey:@"answered"])
            {
                return self.chatData.incomingBubbleOutlineImageData;
            }
        }
        else if ([jsonType isEqualToString:@"ping"])
        {
            BOOL replied = ([jsonInfo objectForKey:@"answered"]) ? 1 : 0;
            if ([message.senderId isEqualToString:self.senderId])
            {
                if (replied)
                {
                    return self.chatData.outgoingBubblePingReplyImageData;
                }
                else
                {
                    return self.chatData.outgoingBubblePingImageData;
                }
            }
            else
            {
                if (replied)
                {
                    return self.chatData.incomingBubblePingReplyImageData;
                }
                else
                {
                    return self.chatData.incomingBubblePingImageData;
                }
            }
        }
    }
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.chatData.outgoingBubbleImageData;
    }
    
    return self.chatData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* messageInfo = [self.chatData.messageInfo objectAtIndex:indexPath.item];
    if ([[messageInfo objectForKey:@"direction"] isEqualToString:@"inbound"])
    {
        //[self.chatData.messageData objectAtIndex:indexPath.item];
        BOOL show = NO;
        if (indexPath.item == 0)
        {
            show = YES;
        }
        else
        {
            NSDictionary* prevInfo = [self.chatData.messageInfo objectAtIndex:(indexPath.item - 1)];
            if ([[prevInfo objectForKey:@"direction"] isEqualToString:@"outbound"])
            {
                show = YES;
            }
        }
        if (show)
        {
            return [self.chatData getAvatar:@"avatar"];
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 7 == 0) {
        JSQMessage *message = [self getMessageAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self getMessageAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self getMessageAtIndex:(indexPath.item - 1)];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.chatData.lastSent != nil)
    {
        if (indexPath.item == [self.chatData.lastSent longValue])
        {
            RgChatManager* mgr = [[LinphoneManager instance] chatManager];
            NSString *uuid = [self.chatData.messageUUIDs objectAtIndex:indexPath.item];
            NSString *status = [mgr dbGetMessageStatusByUUID:uuid];
            if ([status isEqualToString:@"sending"])
            {
                status = @"Sending";
            }
            else if ([status isEqualToString:@"sent"])
            {
                status = @"Sent";
            }
            else if ([status isEqualToString:@"delivered"])
            {
                status = @"Delivered";
            }
            else
            {
                status = @"Error";
            }
            return [[NSAttributedString alloc] initWithString:status];
        }
    }
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.chatData.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self getMessageAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) // Outbound
        {
            [cell.cellBottomLabel setTextInsets:UIEdgeInsetsMake(0, 0, 0, 10.0f)];
            cell.cellBottomLabel.font = [UIFont systemFontOfSize:12.0f];
            cell.cellBottomLabel.textColor = [UIColor grayColor];
        }
        /*else
        {
            cell.textView.textColor = [UIColor whiteColor];
        }*/
        cell.textView.textColor = [UIColor blackColor];
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
        
        // Override Default
        id messageData = [self.chatData.messageData objectAtIndex:indexPath.item];
        if (! [messageData isEqual:[NSNull null]])
        {
            NSDictionary* jsonInfo = (NSDictionary*)messageData;
            NSString* jsonType = [jsonInfo objectForKey:@"type"];
            if ([jsonType isEqualToString:@"question"])
            {
                if (! [msg.senderId isEqualToString:self.senderId])
                {
                    if (! [jsonInfo objectForKey:@"answered"])
                    {
                        cell.textView.textColor = [UIColor jsq_messageBubbleBlueColor];
                    }
                }
            }
            if ([jsonType isEqualToString:@"ping"])
            {
                BOOL replied = ([jsonInfo objectForKey:@"answered"]) ? 1 : 0;
                if (replied)
                {
                    cell.textView.textColor = [UIColor whiteColor];
                }
                else
                {
                    cell.textView.textColor = [UIColor jsq_messageBubbleGreenColor];
                }
            }
        }
    }
 
    return cell;
}

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 5th message
     */
    if (indexPath.item % 7 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
    /**
     *  iOS7-style sender name labels
     */
    /*JSQMessage *currentMessage = [self getMessageAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self getMessageAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;*/
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.chatData.lastSent != nil)
    {
        if (indexPath.item == [self.chatData.lastSent longValue])
        {
            return 20.0f;
        }
    }
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
	NSLog(@"Tapped message bubble!");
    id messageData = [self.chatData.messageData objectAtIndex:indexPath.item];
    if (! [messageData isEqual:[NSNull null]])
    {
        NSDictionary* jsonInfo = (NSDictionary*)messageData;
		NSLog(@"Bubble data: %@", jsonInfo);
        NSString* jsonType = [jsonInfo objectForKey:@"type"];
        if ([jsonType isEqualToString:@"question"])
        {
			JSQMessage *message = [self getMessageAtIndex:indexPath.item];
            if (! [message.senderId isEqualToString:self.senderId] && ! [jsonInfo objectForKey:@"answered"])
            {
                self.questionData = jsonInfo;
                self.questionIndexpath = indexPath;
                NSLog(@"Tapped question bubble: %@", jsonInfo);
                DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:[jsonInfo objectForKey:@"body"]];
                [sheet setActionSheetDelegate:self];
                for (NSString *answer in (NSArray*)[jsonInfo objectForKey:@"answers"])
                {
                    [sheet addButtonWithTitle:answer block:nil];
                }
                [sheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil)
                                          block:^{
                                              self.popoverController = nil;
                                          }];
                [sheet showInView:[PhoneMainView instance].view];
            }
        }
        /*else if ([jsonType isEqualToString:@"ping"])
        {
            if (! [message.senderId isEqualToString:self.senderId] && ! [jsonInfo objectForKey:@"answered"])
            {
                RgChatManager* mgr = [[LinphoneManager instance] chatManager];
                // Send reply
                NSString* pingUUID = [self.chatData.messageUUIDs objectAtIndex:indexPath.item];
                [mgr sendPingTo:_chatRoom reply:pingUUID];
                // Set to answered
                NSMutableDictionary* newData = [NSMutableDictionary dictionaryWithDictionary:jsonInfo];
                [newData setObject:[NSNumber numberWithBool:1] forKey:@"answered"];
                NSError *jsonErr = nil;
                [mgr dbUpdateMessageData:[NSJSONSerialization dataWithJSONObject:newData options:0 error:&jsonErr] forUUID:[self.chatData.messageUUIDs objectAtIndex:indexPath.item]];
                [JSQSystemSoundPlayer jsq_playMessageSentSound];
                [self.chatData loadMessages];
                [self.collectionView reloadData];
            }
        }*/
    }
	else
	{
		NSDictionary* jsonInfo = [self.chatData.messages objectAtIndex:indexPath.item];
        NSLog(@"Tapped bubble jsonInfo: %@", jsonInfo);
		if (
			[jsonInfo isKindOfClass:[NSDictionary class]] &&
			jsonInfo[@"media"] != nil && [jsonInfo[@"media"] isEqualToString:@"image"]
		) {
            NSLog(@"Tapped image bubble: %@", jsonInfo);
			ImageViewController *controller = DYNAMIC_CAST(
				[[PhoneMainView instance] changeCurrentView:[ImageViewController compositeViewDescription] push:TRUE],
				ImageViewController);
			if (controller != nil) {
				UIImage *fullScreen = [self getImageByID:jsonInfo[@"id"] key:@"msg_data"];
				[controller setImage:fullScreen];
			}
		}
	}
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark - Question action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    /*NSArray* answers = [self.questionData objectForKey:@"answers"];
    if (buttonIndex < [answers count])
    {
        NSString* answer = answers[buttonIndex];
        //NSLog(@"Answer(%@): %@", [NSNumber numberWithInteger:buttonIndex], answer);
        RgChatManager* mgr = [[LinphoneManager instance] chatManager];
        NSString *uuid = [mgr sendMessageTo:_chatRoom body:answer reply:[self.chatData.messageUUIDs objectAtIndex:self.questionIndexpath.item]];
        NSMutableDictionary* newData = [NSMutableDictionary dictionaryWithDictionary:self.questionData];
        [newData setObject:[NSNumber numberWithBool:1] forKey:@"answered"];
        NSError *jsonErr = nil;
        //NSLog(@"Answer(%@:%@): %@\nOrig: %@\nNew: %@", [NSNumber numberWithInteger:buttonIndex], [self.chatData.messageUUIDs objectAtIndex:self.questionIndexpath.item], answer, self.questionData, newData);
        NSString *origuuid = [self.chatData.messageUUIDs objectAtIndex:self.questionIndexpath.item];
        [mgr dbUpdateMessageData:[NSJSONSerialization dataWithJSONObject:newData options:0 error:&jsonErr] forUUID:origuuid];
        [self.chatData updateMessage:origuuid];
        [self.chatData loadMessages:uuid];
        [JSQSystemSoundPlayer jsq_playMessageSentSound];
        [self finishSendingMessageAnimated:YES];
    }*/
}

#pragma mark - Utils

- (UIImage *)normalizedImage:(UIImage*)inp {
    if (inp.imageOrientation == UIImageOrientationUp) return inp;

    UIGraphicsBeginImageContextWithOptions(inp.size, NO, inp.scale);
    [inp drawInRect:(CGRect){0, 0, inp.size}];
    UIImage *normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImage;
}

- (UIImage*)getImageByID:(NSNumber*)imageID key:(NSString*)key
{
    UIImage* image = nil;
    NSData* imageData = nil;
	if (key == nil)
	{
		key = @"msg_data";
	}
	NSString *ckey = [NSString stringWithFormat:@"%@:%@", key, [imageID stringValue]];
    NSObject* cacheData = [imageCache objectForKey:ckey];
    if (cacheData == nil)
    {
        imageData = [[[LinphoneManager instance] chatManager] dbGetMessageData:imageID key:key];
        if (imageData != nil)
        {
            image = [UIImage imageWithData:imageData];
        }
        [imageCache setObject:image forKey:ckey];
    }
    else
    {
        image = (UIImage*)cacheData;
    }
	return image;
}

@end
