#import "RgChatModelData.h"


/**
 *  This is for demo/testing purposes only.
 *  This object sets up some fake model data.
 *  Do not actually do anything like this.
 */

@implementation RgChatModelData

@synthesize chatRoom;
@synthesize chatError;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        /**
         *  Create avatar images once.
         *
         *  Be sure to create your avatars one time and reuse them for good performance.
         *
         *  If you are not using avatars, ignore this.
         */
        
        JSQMessagesAvatarImage *jobsImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:@"SJ"
                                                                                       backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                                                                                             textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                                                                                                  font:[UIFont systemFontOfSize:14.0f]
                                                                                              diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        JSQMessagesAvatarImage *ringImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:@"RM"
                                                                                       backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                                                                                             textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                                                                                                  font:[UIFont systemFontOfSize:14.0f]
                                                                                              diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        self.avatars = @{ kJSQDemoAvatarIdJobs : jobsImage, kJSQDemoAvatarIdWoz : ringImage };
        
        self.users = @{ kJSQDemoAvatarIdJobs : kJSQDemoAvatarDisplayNameJobs, kJSQDemoAvatarIdWoz : @"RingMail" };
        
        self.messages = [NSMutableArray array];
        
        
        /**
         *  Create message bubble images objects.
         *
         *  Be sure to create your bubble images one time and reuse them for good performance.
         *
         */
        JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
        
        self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
        self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    }
    
    return self;
}

- (id)initWithChatRoom:(NSString *)room
{
    if (self = [self init])
    {
        chatRoom = room;
        [self loadMessages];
    }
    return self;
}

- (void)loadMessages
{
    if (! [chatRoom isEqualToString:@""])
    {
        //NSLog(@"**** RELOAD MESSAGES ****");
        NSMutableArray* msgs = [NSMutableArray array];
        RgChatManager* mgr = [[LinphoneManager instance] chatManager];
        NSArray* input = [mgr dbGetMessages:self.chatRoom];
        NSString *displayName = self.chatRoom;
        
        ABRecordRef acontact = [[[LinphoneManager instance] fastAddressBook] getContact:displayName];
        if (acontact != nil) {
            displayName = [FastAddressBook getContactDisplayName:acontact];
        }
        //NSLog(@"RingMail: Messages: %@", input);
        for (NSDictionary* msgdata in input)
        {
            NSString* sender;
            NSString* senderName;
            if ([(NSString*)[msgdata objectForKey:@"direction"] isEqualToString:@"outbound"])
            {
                sender = kRgSelf;
                senderName = kRgSelfName;
            }
            else
            {
                sender = kJSQDemoAvatarIdJobs;
                senderName = displayName;
            }
            NSString *type = [msgdata objectForKey:@"type"];
            if ([type isEqualToString:@"text/plain"])
            {
                [msgs addObject:[[JSQMessage alloc] initWithSenderId:sender
                                                   senderDisplayName:senderName
                                                                date:[msgdata objectForKey:@"time"]
                                                                text:[msgdata objectForKey:@"body"]]];
            }
            else if ([type isEqualToString:@"image/png"])
            {
                [msgs addObject:@{
                                  @"id": [msgdata objectForKey:@"id"],
                                  @"type": type,
                                  @"sender": sender,
                                  @"senderName": senderName,
                                  @"time": [msgdata objectForKey:@"time"],
                                  @"direction": [msgdata objectForKey:@"direction"]
                              }];
                /*UIImage* image = [UIImage imageWithData:[mgr dbGetMessageData:[msgdata objectForKey:@"id"]]];
                JSQPhotoMediaItem* mediaData = [[JSQPhotoMediaItem alloc] initWithImage:image];
                [msgs addObject:[[JSQMessage alloc] initWithSenderId:sender
                                                   senderDisplayName:senderName
                                                                date:[msgdata objectForKey:@"time"]
                                                               media:mediaData]];*/
            }
        }
        
        // TODO: replace with something better
        if (chatError != nil && ![chatError isEqualToString:@""])
        {
            [msgs addObject:[[JSQMessage alloc] initWithSenderId:kJSQDemoAvatarIdWoz
                                               senderDisplayName:@"RingMail"
                                                            date:[NSDate date] // TODO: correct error date
                                                            text:[NSString stringWithFormat:@"Error: %@", chatError]]];
        }
        self.messages = msgs;
    }
}

@end
