#ifndef MainCollectionViewController_h
#define MainCollectionViewController_h

#import <UIKit/UIKit.h>
#import "MessageListModelController.h"

@interface MessageListViewController : UICollectionViewController

- (void)updateCollection;
//- (void)removeMessageThread:(NSNumber*)index;

@end

#endif
