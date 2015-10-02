#import "RgMessagesViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "DTActionSheet.h"
#import "NYXImagesKit/NYXImagesKit.h"

@implementation RgMessagesViewController

@synthesize chatRoom = _chatRoom;
@synthesize popoverController;
@synthesize imageCache;

#pragma mark - Init

#pragma mark - View lifecycle

- (id)init
{
    if (self = [super init])
    {
        self.chatRoom = @"";
        self.imageCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"RingMail Messages";
    
    self.senderId = kRgSelf;
    self.senderDisplayName = kRgSelfName;
    self.chatData = [[RgChatModelData alloc] initWithChatRoom:self.chatRoom];
    
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    self.showLoadEarlierMessagesHeader = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //self.collectionView.collectionViewLayout.springinessEnabled = YES;
}

#pragma mark - Chat room switch

- (void)setChatRoom:(NSString *)chatRoom
{
    _chatRoom = chatRoom;
    [self.chatData setChatRoom:chatRoom];
    [self.chatData loadMessages];
}

#pragma mark - Actions

- (void)receiveMessage
{
    [self.chatData loadMessages];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollToBottomAnimated:YES];
        [self finishReceivingMessageAnimated:YES];
        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
    });
}

- (void)sentMessage
{
    [self.chatData loadMessages];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self scrollToBottomAnimated:YES];
        [self finishReceivingMessageAnimated:YES];
        [JSQSystemSoundPlayer jsq_playMessageSentSound];
    });
}

- (void)updateMessages
{
    [self.chatData loadMessages];
    dispatch_async(dispatch_get_main_queue(), ^{
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
    DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:NSLocalizedString(@"Select picture source", nil)];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Camera", nil)
                            block:^() {
                                showAppropriateController(UIImagePickerControllerSourceTypeCamera);
                            }];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addButtonWithTitle:NSLocalizedString(@"Photo Library", nil)
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
    
    UIImage *imageSized = [image scaleToFitSize:(CGSize){300, 300}];
    
    RgChatManager* mgr = [[LinphoneManager instance] chatManager];
    [mgr sendMessageTo:_chatRoom image:imageSized];
    
    NSDictionary *dict = @{
        @"tag":_chatRoom
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
        RgChatManager* mgr = [[LinphoneManager instance] chatManager];
        [mgr sendMessageTo:_chatRoom body:text];
        
        //NSLog(@"RingMail - Send Message To: %@ -> %@", _chatRoom, msgTo);
    
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
        [JSQSystemSoundPlayer jsq_playMessageSentSound];
        
        JSQMessage *msg = [[JSQMessage alloc] initWithSenderId:senderId
                                                 senderDisplayName:senderDisplayName
                                                              date:date
                                                              text:text];
        
        [self.chatData.messages addObject:msg];
        [self.chatData setChatError:@""];
        
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
        RgChatManager* mgr = [[LinphoneManager instance] chatManager];
        UIImage* image = nil;
        NSData* imageData;
        NSNumber* imageID = [lazy objectForKey:@"id"];
        NSObject* cacheData = [imageCache objectForKey:[imageID stringValue]];
        if (cacheData == nil)
        {
            imageData = [mgr dbGetMessageData:imageID];
            if (imageData != nil)
            {
                image = [UIImage imageWithData:imageData];
            }
            [imageCache setObject:image forKey:[imageID stringValue]];
        }
        else
        {
            image = (UIImage*)cacheData;
        }
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
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.chatData.outgoingBubbleImageData;
    }
    
    return self.chatData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    //JSQMessage *message = [self.chatData.messages objectAtIndex:indexPath.item];
    /*if ([message.senderId isEqualToString:self.senderId]) {
        if (![NSUserDefaults outgoingAvatarSetting]) {
            return nil;
        }
    }
    else {
        if (![NSUserDefaults incomingAvatarSetting]) {
            return nil;
        }
    }*/
    //return [self.chatData.avatars objectForKey:message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
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
    return [[NSAttributedString alloc] initWithString:@"Result"];
    //return nil;
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
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
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
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self getMessageAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self getMessageAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
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
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

@end
