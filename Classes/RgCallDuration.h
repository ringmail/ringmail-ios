//
//  RgCallDuration.h
//  ringmail
//
//  Created by Mike Frager on 4/1/16.
//
//

#import <Foundation/Foundation.h>

@interface RgCallDuration : UILabel
{
	NSTimer* durationTimer;
}

- (void)startTimer;
- (void)stopTimer;

@end
