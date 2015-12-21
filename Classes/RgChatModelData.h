//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "JSQMessages.h"
#import "RgManager.h"
#import "LinphoneManager.h"

@interface RgChatModelData : NSObject

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableArray *messageData;
@property (strong, nonatomic) NSMutableArray *messageUUIDs;
@property (strong, nonatomic) NSMutableDictionary *messageRef;
@property (strong, nonatomic) NSDictionary *avatars;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleOutlineImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleOutlineImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubblePingImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubblePingImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubblePingReplyImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubblePingReplyImageData;
@property (strong, nonatomic) NSDictionary *users;
@property (strong, nonatomic) NSString *chatRoom;
@property (strong, nonatomic) NSNumber* lastSent;

- (id)initWithChatRoom:(NSString *)room;
- (void)loadMessages;
- (void)loadMessages:(NSString*)uuid;
- (void)updateMessage:(NSString*)uuid;


@end
