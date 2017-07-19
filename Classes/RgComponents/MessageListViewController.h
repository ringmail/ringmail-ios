#ifndef MainCollectionViewController_h
#define MainCollectionViewController_h

#import <UIKit/UIKit.h>
#import "MessageListModelController.h"

@interface MessageListViewController : UICollectionViewController

- (void)updateCollection;
- (void)updateCollection:(BOOL)force;
//- (void)removeMessageThread:(NSNumber*)index;

@end

#endif
