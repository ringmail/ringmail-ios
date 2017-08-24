//
//  HashtagCollectionViewController.h
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#ifndef HashtagCollectionViewController_h
#define HashtagCollectionViewController_h

#import <UIKit/UIKit.h>
#import "CardsPage.h"

@interface HashtagCollectionViewController : UICollectionViewController

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout path:(NSString*)path;
- (void)enqueuePage:(CardsPage *)cardsPage;
- (void)updateCollection:(BOOL)myActivity;

@property (nonatomic, weak) id <CardPageLoading> waitDelegate;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL eof;

@end

#endif
