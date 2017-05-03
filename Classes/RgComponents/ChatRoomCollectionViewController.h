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

@interface ChatRoomCollectionViewController : UICollectionViewController

@property (nonatomic, strong) NSNumber* chatThreadID;
@property (nonatomic, strong) NSNumber* lastMessageID;

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout chatThreadID:(NSNumber*)threadID elements:(NSArray*)elems;

- (void)scrollToBottom:(BOOL)animate;
- (void)appendMessages:(NSArray*)msgs;

@end

#endif /* ChatRoomCollectionViewController_h */
