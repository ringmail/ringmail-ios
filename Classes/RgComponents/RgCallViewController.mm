//
//  RgCallViewController.m
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#import <Foundation/Foundation.h>
#import <ComponentKit/ComponentKit.h>
#import "UIColor+Hex.h"
#import "RgCallViewController.h"
#import "RgCallComponent.h"

@interface RgCallViewController () <CKComponentProvider, CKComponentHostingViewDelegate>
@end

static RgCallDuration* globalDuration = nil;

@implementation RgCallViewController
{
    CKComponentDataSource *_componentDataSource;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
    CKComponentHostingView *_hostView;
}

- (void)viewDidLoad
{
	[self addCallView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	if (_hostView == nil)
	{
		[self addCallView];
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	RgCallDuration* durationLabel = [RgCallViewController getDurationLabel];
	if (durationLabel != nil)
	{
		[durationLabel stopTimer];
	}
}

- (void)addCallView
{
	if (_hostView == nil)
	{
//		CGFloat ht = [[UIScreen mainScreen] bounds].size.height - [self statusBarHeight];
        CGFloat ht = [[UIScreen mainScreen] bounds].size.height;
		_sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
		_hostView = [[CKComponentHostingView alloc] initWithComponentProvider:[self class] sizeRangeProvider:_sizeRangeProvider];
		_hostView.delegate = self;
		_hostView.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, ht);
		RgCallContext *context = [[RgCallContext alloc] initWithImages:[NSMutableDictionary dictionary]];
		[_hostView updateContext:context mode:CKUpdateModeSynchronous];
		[self.view addSubview:_hostView];
	}
}

- (void)removeCallView
{
	if (_hostView != nil)
	{
		RgCallDuration* durationLabel = [RgCallViewController getDurationLabel];
		if (durationLabel != nil)
		{
			[durationLabel stopTimer];
		}
		[_hostView removeFromSuperview];
		_hostView = nil;
		_sizeRangeProvider = nil;
	}
}

+ (id)initialState
{
  return [NSMutableDictionary dictionaryWithDictionary:@{}];
}

#pragma mark - CKComponentProvider

+ (CKComponent *)componentForModel:(id<NSObject>)call context:(id<NSObject>)context {
    return [RgCallComponent newWithCall:call context:context];
}

#pragma mark - CKComponentHostingViewDelegate <NSObject>
- (void)componentHostingViewDidInvalidateSize:(CKComponentHostingView *)hostingView {
    NSLog(@"componentHostingViewDidInvalidateSize");
}

#pragma mark - Update call

- (void)updateCall:(NSDictionary*)data
{
	if (_hostView != nil)
	{
//		CGFloat ht = [[UIScreen mainScreen] bounds].size.height - [self statusBarHeight];
        CGFloat ht = [[UIScreen mainScreen] bounds].size.height;
		NSMutableDictionary* dt = [NSMutableDictionary dictionaryWithDictionary:data];
		[dt setObject:[NSNumber numberWithFloat:ht] forKey:@"height"];
		RgCall *call = [[RgCall alloc] initWithData:dt];
		[_hostView updateModel:call mode:CKUpdateModeSynchronous];
		RgCallDuration* durationLabel = [RgCallViewController getDurationLabel];
		if (durationLabel != nil)
		{
			[durationLabel startTimer];
		}
	}
}

-(float) statusBarHeight
{
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}


+ (void)setDurationLabel:(RgCallDuration*)label
{
	globalDuration = label;
	[globalDuration startTimer];
}

+ (RgCallDuration*)getDurationLabel
{
	return globalDuration;
}


@end
