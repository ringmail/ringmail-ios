//
//  RgCallDuration.m
//  ringmail
//
//  Created by Mike Frager on 4/1/16.
//
//

#import "RgCallDuration.h"
#import "LinphoneManager.h"
#import "RgInCallViewController.h"

@implementation RgCallDuration

- (id)initWithFrame:(CGRect)rect
{
	if (self = [super initWithFrame:rect])
	{
		[self setFont:[UIFont fontWithName:@"HelveticaNeueLTStd-Cn" size:14]];
		[self setTextAlignment:NSTextAlignmentCenter];
		[self setText:@"00:00:00"];
	}
	return self;
}

- (void)startTimer
{
	if (durationTimer == nil)
	{
		durationTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerRefresh) userInfo:nil repeats:YES];
	}
	[self setText:[self getCallDuration]];
}

- (void)stopTimer
{
	if (durationTimer != nil)
	{
		[durationTimer invalidate];
		durationTimer = nil;
		NSLog(@"RingMail: Invalidate Duration Timer");
	}
}

- (void)timerRefresh
{
	[self setText:[self getCallDuration]];
}

- (NSString*)getCallDuration
{
	if ([RgInCallViewController callCount:[LinphoneManager getLc]] > 0)
	{
		LinphoneCall *call = [RgInCallViewController retrieveCallAtIndex:0];
		int duration = linphone_call_get_duration(call);
		return [NSString stringWithFormat:@"%02i:%02i:%02i", (duration / 3600), ((duration / 60) % 60), (duration % 60), nil];
	}
	return @"00:00:00";
}

@end
