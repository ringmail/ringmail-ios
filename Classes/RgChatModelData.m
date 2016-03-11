#import "RgChatModelData.h"


/**
 *  This is for demo/testing purposes only.
 *  This object sets up some fake model data.
 *  Do not actually do anything like this.
 */

@implementation RgChatModelData

@synthesize chatRoom;
@synthesize lastSent;

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
        
        JSQMessagesAvatarImage *jsqImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:@"JSQ"
              backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                    textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                         font:[UIFont systemFontOfSize:14.0f]
                     diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        self.avatars = @{ @"avatar":jsqImage };
        //self.users = @{ };
        
        self.messages = [NSMutableArray array];
        self.messageData = [NSMutableArray array];
        self.messageUUIDs = [NSMutableArray array];
        self.messageRef = [NSMutableDictionary dictionary];
        self.lastSent = nil;
        
        /**
         *  Create message bubble images objects.
         *
         *  Be sure to create your bubble images one time and reuse them for good performance.
         *
         */
        //JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
        JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_ringmail"] capInsets:UIEdgeInsetsZero];
        self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
        self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
        
        JSQMessagesBubbleImageFactory *bubbleFactory2 = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularStrokedImage] capInsets:UIEdgeInsetsZero];
        self.outgoingBubbleOutlineImageData = [bubbleFactory2 outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
        self.incomingBubbleOutlineImageData = [bubbleFactory2 incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
        
        self.outgoingBubblePingImageData = [bubbleFactory2 outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
        self.incomingBubblePingImageData = [bubbleFactory2 incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
        self.outgoingBubblePingReplyImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
        self.incomingBubblePingReplyImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
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
    [self loadMessages:nil];
}

- (void)loadMessages:(NSString*)uuid
{
    if (! [chatRoom isEqualToString:@""])
    {
        NSDictionary* msgRec = [self buildMessages:uuid];
        NSMutableArray* msgs = [msgRec objectForKey:@"messages"];
        NSMutableArray* msgData = [msgRec objectForKey:@"data"];
        NSMutableArray* msgUUIDs = [msgRec objectForKey:@"uuids"];
        if (uuid)
        {
            NSInteger ct = [msgs count];
            if (ct > 0)
            {
                NSLog(@"Add messageRef: %@", uuid);
                if (self.lastSent != nil && [self.lastSent intValue] == -1)
                {
                    self.lastSent = [NSNumber numberWithUnsignedLong:[self.messages count]];
                }
                
                [self.messageRef setObject:[NSNumber numberWithInteger:[self.messages count]] forKey:uuid];
                [self.messages addObject:msgs[0]];
                [self.messageData addObject:msgData[0]];
                [self.messageUUIDs addObject:msgUUIDs[0]];
            }
        }
        else
        {
            self.messageRef = [NSMutableDictionary dictionary];
            NSInteger i = 0;
            for (NSString *uuid in msgUUIDs)
            {
                [self.messageRef setObject:[NSNumber numberWithInteger:i] forKey:uuid];
                i++;
            }
            self.messages = msgs;
            self.messageData = msgData;
            self.messageUUIDs = msgUUIDs;
        }
    }
}

- (void)updateMessage:(NSString*)uuid
{
    NSLog(@"Update message check: %@\n%@", uuid, self.messageRef);
    NSNumber* itemIdx = [self.messageRef objectForKey:uuid];
    if (itemIdx)
    {
        NSLog(@"Update message: %@", itemIdx);
        NSDictionary* msgRec = [self buildMessages:uuid];
        NSMutableArray* msgs = [msgRec objectForKey:@"messages"];
        NSMutableArray* msgData = [msgRec objectForKey:@"data"];
        NSMutableArray* msgUUIDs = [msgRec objectForKey:@"uuids"];
        NSInteger ct = [msgs count];
        if (ct > 0)
        {
            NSLog(@"Update message data: %@", msgs);
            int i = [itemIdx intValue];
            self.messages[i] = msgs[0];
            self.messageData[i] = msgData[0];
            self.messageUUIDs[i] = msgUUIDs[0];
            return;
        }
    }
    [self loadMessages];
}

- (NSDictionary*)buildMessages:(NSString*)uuid
{
    NSMutableArray* msgs = [NSMutableArray array];
    NSMutableArray* msgData = [NSMutableArray array];
    NSMutableArray* msgUUIDs = [NSMutableArray array];
    //NSLog(@"**** RELOAD MESSAGES ****");
    RgChatManager* mgr = [[LinphoneManager instance] chatManager];
    NSArray* input;
    if (uuid)
    {
        input = [mgr dbGetMessages:self.chatRoom uuid:uuid];
    }
    else
    {
        input = [mgr dbGetMessages:self.chatRoom];
    }
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
            if (! uuid)
            {
                lastSent = [NSNumber numberWithUnsignedLong:[msgs count]];
            }
            else
            {
                lastSent = [NSNumber numberWithInt:-1];
            }
        }
        else
        {
            sender = self.chatRoom;
            senderName = displayName;
            lastSent = nil; // No need for status if they reply
        }
        [msgUUIDs addObject:[msgdata objectForKey:@"uuid"]];
        NSString *type = [msgdata objectForKey:@"type"];
        if ([type isEqualToString:@"text/plain"])
        {
            [msgData addObject:[NSNull null]];
            [msgs addObject:[[JSQMessage alloc] initWithSenderId:sender
                                               senderDisplayName:senderName
                                                            date:[msgdata objectForKey:@"time"]
                                                            text:[msgdata objectForKey:@"body"]]];
        }
        else if ([type isEqualToString:@"image/png"])
        {
            [msgData addObject:[NSNull null]];
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
        else if ([type isEqualToString:@"application/json"])
        {
            NSData* jsonData = [mgr dbGetMessageData:[msgdata objectForKey:@"id"]];
            NSError* error;
            NSDictionary *jsonInfo = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
            //NSString *jsonType = [jsonInfo objectForKey:@"type"];
            NSString *body = [jsonInfo objectForKey:@"body"];
            //body = [NSString stringWithFormat:@"[%@]: %@", jsonType, body];
            [msgData addObject:jsonInfo];
            [msgs addObject:[[JSQMessage alloc] initWithSenderId:sender
                                               senderDisplayName:senderName
                                                            date:[msgdata objectForKey:@"time"]
                                                            text:body]];
        }
    }
    
    return @{
         @"messages":msgs,
         @"data":msgData,
         @"uuids":msgUUIDs,
    };
}

@end
