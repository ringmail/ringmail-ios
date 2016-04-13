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
#import "RgCallDuration.h"

@interface RgCallViewController : UIViewController

@property (nonatomic, strong) NSDictionary *callData;
@property (nonatomic, strong) RgCallDuration *durationLabel;

+ (void)setDurationLabel:(RgCallDuration*)label;
+ (RgCallDuration*)getDurationLabel;

- (void)updateCall:(NSDictionary*)data;
- (void)addCallView;
- (void)removeCallView;

@end

#endif /* MainCollectionViewController_h */
