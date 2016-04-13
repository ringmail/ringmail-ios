//
//  RgIncomingCallViewController.m
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#import <Foundation/Foundation.h>
#import <ComponentKit/ComponentKit.h>
#import "UIColor+Hex.h"
#import "RgIncomingCallViewController.h"
#import "RgIncomingCallComponent.h"

@interface RgIncomingCallViewController () <CKComponentProvider, CKComponentHostingViewDelegate>
@end

@implementation RgIncomingCallViewController
{
    CKComponentDataSource *_componentDataSource;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
    CKComponentHostingView *_hostView;
}

- (void)viewDidLoad
{
	CGFloat ht = [[UIScreen mainScreen] bounds].size.height - [self statusBarHeight];
	_sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
	_hostView = [[CKComponentHostingView alloc] initWithComponentProvider:[self class] sizeRangeProvider:_sizeRangeProvider];
	_hostView.delegate = self;
	_hostView.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, ht);
	RgCallContext *context = [[RgCallContext alloc] initWithImages:[NSMutableDictionary dictionary]];
	[_hostView updateContext:context mode:CKUpdateModeSynchronous];
	[self.view addSubview:_hostView];
}

+ (id)initialState
{
  return [NSMutableDictionary dictionaryWithDictionary:@{}];
}

#pragma mark - CKComponentProvider

+ (CKComponent *)componentForModel:(id<NSObject>)call context:(id<NSObject>)context {
    return [RgIncomingCallComponent newWithCall:call context:context];
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
		CGFloat ht = [[UIScreen mainScreen] bounds].size.height - [self statusBarHeight];
		NSMutableDictionary* dt = [NSMutableDictionary dictionaryWithDictionary:data];
		[dt setObject:[NSNumber numberWithFloat:ht] forKey:@"height"];
		RgCall *call = [[RgCall alloc] initWithData:dt];
		[_hostView updateModel:call mode:CKUpdateModeSynchronous];
	}
}

-(float) statusBarHeight
{
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}

@end
