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

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout chatThreadID:(NSNumber*)threadID;

@end

#endif /* ChatRoomCollectionViewController_h */
