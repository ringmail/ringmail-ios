//
//  MainCollectionViewController.h
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#ifndef RgCallViewController_h
#define RgCallViewController_h

#import <UIKit/UIKit.h>
#import "RgCall.h"
#import "RgCallContext.h"

@interface RgCallViewController : UIViewController

@property (nonatomic, strong) NSDictionary *callData;
@property (nonatomic, strong) RgCall *call;

- (void)updateCall:(NSDictionary*)data;
- (void)addCallView;
- (void)removeCallView;

@end

#endif /* MainCollectionViewController_h */
