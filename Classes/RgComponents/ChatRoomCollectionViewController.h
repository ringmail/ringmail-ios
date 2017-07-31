//
//  ChatRoomCollectionViewController.h
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#ifndef ChatRoomCollectionViewController_h
#define ChatRoomCollectionViewController_h

#import <UIKit/UIKit.h>
#import "RingKit.h"
#import "GGMutableDictionary.h"

@interface ChatRoomCollectionViewController : UICollectionViewController

@property (nonatomic, strong) RKThread* chatThread;
@property (nonatomic, strong) NSNumber* lastMessageID;

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout chatThread:(RKThread*)chatThread;

- (void)scrollToBottom:(BOOL)animate;
- (void)appendNewMessages;
- (void)updateMessage:(RKItem*)msg;
- (void)removeMessage:(RKItem*)msg;

@end

#endif /* ChatRoomCollectionViewController_h */
