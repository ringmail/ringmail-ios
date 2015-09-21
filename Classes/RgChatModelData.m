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
        NSLog(@"**** RELOAD MESSAGES ****");
        NSMutableArray* msgs = [NSMutableArray array];
        NSArray* input = [[LinphoneManager instance].chatManager dbGetMessages:self.chatRoom];
        for (NSDictionary* msgdata in input)
        {
            if ([(NSString*)[msgdata objectForKey:@"direction"] isEqualToString:@"outbound"])
            {
                [msgs addObject:[[JSQMessage alloc] initWithSenderId:kRgSelf
                                                   senderDisplayName:kRgSelfName
                                                                date:[msgdata objectForKey:@"time"]
                                                                text:[msgdata objectForKey:@"body"]]];
            }
            else
            {
                [msgs addObject:[[JSQMessage alloc] initWithSenderId:kJSQDemoAvatarIdJobs
                                                   senderDisplayName:kJSQDemoAvatarDisplayNameJobs
                                                                date:[msgdata objectForKey:@"time"]
                                                                text:[msgdata objectForKey:@"body"]]];
            }
        }
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
