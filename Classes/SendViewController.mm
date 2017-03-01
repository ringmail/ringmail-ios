//
//  SendViewController.m
//

#import <Foundation/Foundation.h>
#import <ComponentKit/ComponentKit.h>
#import "UIColor+Hex.h"
#import "SendViewController.h"
#import "SendComponent.h"

@interface SendViewController () <CKComponentProvider, CKComponentHostingViewDelegate>

@end

@implementation SendViewController
{
    CKComponentDataSource *_componentDataSource;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
    CKComponentHostingView *_hostView;
}

- (void)viewDidLoad
{

}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	CGFloat height = self.view.frame.size.height;
	CGFloat width = [[UIScreen mainScreen] bounds].size.width;
	NSLog(@"Height: %f", height);
	_sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
	_hostView = [[CKComponentHostingView alloc] initWithComponentProvider:[self class] sizeRangeProvider:_sizeRangeProvider];
	_hostView.delegate = self;
	_hostView.frame = CGRectMake(0, 50, width, height);

	SendContext *context = [[SendContext alloc] init];
	[_hostView updateContext:context mode:CKUpdateModeSynchronous];
	
	Send *send = [[Send alloc] initWithData:@{}];
	[_hostView updateModel:send mode:CKUpdateModeSynchronous];
	
	[self.view addSubview:_hostView];
	//_hostView.frame = self.view.frame;

}

/*- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}*/

+ (id)initialState
{
	return [NSMutableDictionary dictionaryWithDictionary:@{}];
}

#pragma mark - CKComponentProvider

+ (CKComponent *)componentForModel:(id<NSObject>)send context:(id<NSObject>)context {
    return [SendComponent newWithSend:send context:context];
}

#pragma mark - CKComponentHostingViewDelegate <NSObject>
- (void)componentHostingViewDidInvalidateSize:(CKComponentHostingView *)hostingView {
    NSLog(@"componentHostingViewDidInvalidateSize");
}

#pragma mark - Update

- (void)updateSend:(NSDictionary*)data
{
	if (_hostView != nil)
	{
		Send *send = [[Send alloc] initWithData:data];
		[_hostView updateModel:send mode:CKUpdateModeSynchronous];
	}
}

- (float)statusBarHeight
{
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}

@end
