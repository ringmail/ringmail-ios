//
//  MediaCollectionViewController.h
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#ifndef MediaCollectionViewController_h
#define MediaCollectionViewController_h

#import <UIKit/UIKit.h>

@interface MediaCollectionViewController : UICollectionViewController

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout media:(NSArray*)media;

@end

#endif /* MediaCollectionViewController_h */
