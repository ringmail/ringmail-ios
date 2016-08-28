#import "RgChatModelData.h"
#import "RgChatBubbleFactory.h"


/**
 *  This is for demo/testing purposes only.
 *  This object sets up some fake model data.
 *  Do not actually do anything like this.
 */

@implementation RgChatModelData

@synthesize chatSession;
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
        
        JSQMessagesAvatarImage *jsqImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:@"IN"
              backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                    textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                         font:[UIFont systemFontOfSize:14.0f]
                     diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        self.avatars = [NSMutableDictionary dictionaryWithDictionary:@{ @"avatar":jsqImage }];
        //self.users = @{ };
        
        self.messages = [NSMutableArray array];
        self.messageData = [NSMutableArray array];
        self.messageUUIDs = [NSMutableArray array];
        self.messageInfo = [NSMutableArray array];
        self.messageRef = [NSMutableDictionary dictionary];
        self.lastSent = nil;
        
        /**
         *  Create message bubble images objects.
         *
         *  Be sure to create your bubble images one time and reuse them for good performance.
         *
         */
        RgChatBubbleFactory *bubbleFactoryIn = [[RgChatBubbleFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_ringmail_blue"] capInsets:UIEdgeInsetsZero];
        RgChatBubbleFactory *bubbleFactoryOut = [[RgChatBubbleFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_ringmail"] capInsets:UIEdgeInsetsZero];
        self.outgoingBubbleImageData = [bubbleFactoryOut outgoingMessagesBubbleImageWithColor:[UIColor clearColor]];
        self.incomingBubbleImageData = [bubbleFactoryIn incomingMessagesBubbleImageWithColor:[UIColor clearColor]];
        
        JSQMessagesBubbleImageFactory *bubbleFactory2 = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage jsq_bubbleRegularStrokedImage] capInsets:UIEdgeInsetsZero];
        self.outgoingBubbleOutlineImageData = [bubbleFactory2 outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
        self.incomingBubbleOutlineImageData = [bubbleFactory2 incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
        
        self.outgoingBubblePingImageData = [bubbleFactory2 outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
        self.incomingBubblePingImageData = [bubbleFactory2 incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
        self.outgoingBubblePingReplyImageData = [bubbleFactory2 outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
        self.incomingBubblePingReplyImageData = [bubbleFactory2 incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    }
    
    return self;
}

- (id)initWithChatRoom:(NSNumber *)session
{
    if (self = [self init])
    {
        chatSession = session;
        [self loadMessages];
    }
    return self;
}

- (JSQMessagesAvatarImage*)getAvatar:(NSString *)avatar
{
    JSQMessagesAvatarImage* image = [self.avatars objectForKey:avatar];
    return image;
}

- (void)loadMessages
{
    [self loadMessages:nil];
}

- (void)loadMessages:(NSString*)uuid
{
    if ([chatSession intValue] != 0)
    {
        NSDictionary* msgRec = [self buildMessages:uuid];
        NSMutableArray* msgs = [msgRec objectForKey:@"messages"];
        NSMutableArray* msgData = [msgRec objectForKey:@"data"];
        NSMutableArray* msgInfo = [msgRec objectForKey:@"info"];
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
                [self.messageInfo addObject:msgInfo[0]];
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
            self.messageInfo = msgInfo;
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
        NSMutableArray* msgInfo = [msgRec objectForKey:@"info"];
        NSMutableArray* msgUUIDs = [msgRec objectForKey:@"uuids"];
        NSInteger ct = [msgs count];
        if (ct > 0)
        {
            NSLog(@"Update message data: %@", msgs);
            int i = [itemIdx intValue];
            self.messages[i] = msgs[0];
            self.messageData[i] = msgData[0];
            self.messageInfo[i] = msgInfo[0];
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
    NSMutableArray* msgInfo = [NSMutableArray array];
    NSMutableArray* msgUUIDs = [NSMutableArray array];
    //NSLog(@"**** RELOAD MESSAGES ****");
    RgChatManager* mgr = [[LinphoneManager instance] chatManager];
    NSArray* input;
    if (uuid)
    {
        input = [mgr dbGetMessages:self.chatSession uuid:uuid];
    }
    else
    {
        input = [mgr dbGetMessages:self.chatSession];
    }
	// TODO: Fix label
    NSString *displayName = [self.chatSession stringValue];
    
    ABRecordRef acontact = [[[LinphoneManager instance] fastAddressBook] getContact:displayName];
    if (acontact != nil) {
        displayName = [FastAddressBook getContactDisplayName:acontact];
    }
    //NSLog(@"RingMail: Messages: %@", input);
    for (NSDictionary* msgdata in input)
    {
        [msgInfo addObject:msgdata];
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
			// TODO: Fix sender
            sender = [self.chatSession stringValue];
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
                              @"media": @"image",
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
         @"info":msgInfo,
         @"uuids":msgUUIDs,
    };
}

@end
