//
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#ifndef RgIncomingCallViewController_h
#define RgIncomingCallViewController_h

#import <UIKit/UIKit.h>
#import "RgCall.h"
#import "RgCallContext.h"

@interface RgIncomingCallViewController : UIViewController

@property (nonatomic, strong) NSDictionary *callData;
@property (nonatomic, strong) RgCall *call;

- (void)updateCall:(NSDictionary*)data;

@end

#endif
