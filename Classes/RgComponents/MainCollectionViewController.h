//
//  MainCollectionViewController.h
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#ifndef MainCollectionViewController_h
#define MainCollectionViewController_h

#import <UIKit/UIKit.h>
#import "CardModelController.h"

@interface MainCollectionViewController : UICollectionViewController

- (void)updateCollection;
- (void)removeCard:(NSNumber*)index;

@end

#endif /* MainCollectionViewController_h */
