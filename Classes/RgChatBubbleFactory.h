//
//  RgChatBubbleFactory.h
//  ringmail
//
//  Created by Mike Frager on 3/10/16.
//
//

#import <Foundation/Foundation.h>
#import "JSQMessages.h"


@interface RgChatBubbleFactory : NSObject

@property (strong, nonatomic, readonly) UIImage *bubbleImage;
@property (assign, nonatomic, readonly) UIEdgeInsets capInsets;

- (instancetype)initWithBubbleImage:(UIImage *)bubbleImage capInsets:(UIEdgeInsets)capInsets;
- (JSQMessagesBubbleImage *)outgoingMessagesBubbleImageWithColor:(UIColor *)color;
- (JSQMessagesBubbleImage *)incomingMessagesBubbleImageWithColor:(UIColor *)color;

@end
