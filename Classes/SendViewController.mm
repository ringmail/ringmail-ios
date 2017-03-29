//
//  SendViewController.m
//

#import <Foundation/Foundation.h>
#import <ComponentKit/ComponentKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#import "UIColor+Hex.h"
#import "SendViewController.h"
#import "SendComponent.h"
#import "RgManager.h"

@interface SendViewController () <CKComponentProvider, CKComponentHostingViewDelegate>

@end

@implementation SendViewController
{
    CKComponentDataSource *_componentDataSource;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
    CKComponentHostingView *_hostView;
}

@synthesize sendInfo;

- (id)init
{
	NSLog(@"SendViewController init");
	if (self = [super init])
	{
		self->_hostView = nil;
		self->_componentDataSource = nil;
		self->_sizeRangeProvider = nil;
		sendInfo = nil;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	NSLog(@"SendViewController viewWillAppear");
	[super viewWillAppear:animated];
	
	if (self->_hostView == nil)
	{
		// build panel
		CGFloat height = self.view.frame.size.height;
		CGFloat width = [[UIScreen mainScreen] bounds].size.width;
		//NSLog(@"Height: %f", height);
		_sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
		_hostView = [[CKComponentHostingView alloc] initWithComponentProvider:[self class] sizeRangeProvider:_sizeRangeProvider];
		_hostView.delegate = self;
		_hostView.frame = CGRectMake(0, 50, width, height);

		SendContext *context = [[SendContext alloc] init];
		[_hostView updateContext:context mode:CKUpdateModeSynchronous];
		
   		NSLog(@"Initial sendInfo: %@", sendInfo);
		if (sendInfo != nil)
		{
    		Send *send = [[Send alloc] initWithData:sendInfo];
    		[_hostView updateModel:send mode:CKUpdateModeSynchronous];
		}
		[self.view addSubview:_hostView];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectMedia:) name:kRgSendComponentAddMedia object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeMedia) name:kRgSendComponentRemoveMedia object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetSend) name:kRgSendComponentReset object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSendComponentAddMedia object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSendComponentRemoveMedia object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSendComponentReset object:nil];
}

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
    //NSLog(@"componentHostingViewDidInvalidateSize");
}

#pragma mark - Event handlers

- (void)selectMedia:(NSNotification *)notif {
	NSDictionary *data = notif.userInfo;
	NSLog(@"Select Media: %@", data);
	// get image
	PHImageManager* imageManager = [PHImageManager defaultManager];
	PHImageRequestOptions* opts = [PHImageRequestOptions new];
	opts.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
	opts.resizeMode = PHImageRequestOptionsResizeModeExact;
	opts.synchronous = YES;
	[imageManager requestImageForAsset:data[@"asset"] targetSize:CGSizeMake(180, 180) contentMode:PHImageContentModeAspectFill options:opts resultHandler:^(UIImage* image, NSDictionary* info){
		sendInfo[@"send_media"] = image;
	}];
	sendInfo[@"send_asset"] = data[@"asset"];
	if (_hostView != nil)
	{
    	Send *send = [[Send alloc] initWithData:sendInfo];
    	[_hostView updateModel:send mode:CKUpdateModeAsynchronous];
	}
}

- (void)addMedia:(NSDictionary*)param
{
	sendInfo[@"send_media"] = param[@"thumbnail"];
	sendInfo[@"send_file"] = param[@"file"];
	if (_hostView != nil)
	{
    	Send *send = [[Send alloc] initWithData:sendInfo];
    	[_hostView updateModel:send mode:CKUpdateModeAsynchronous];
	}
}

- (void)removeMedia
{
	if (sendInfo[@"send_media"])
	{
		[sendInfo removeObjectForKey:@"send_media"];
	}
	if (sendInfo[@"send_file"])
	{
		[sendInfo removeObjectForKey:@"send_file"];
	}
	if (sendInfo[@"send_asset"])
	{
		[sendInfo removeObjectForKey:@"send_asset"];
	}
	if (_hostView != nil)
	{
    	Send *send = [[Send alloc] initWithData:sendInfo];
    	[_hostView updateModel:send mode:CKUpdateModeAsynchronous];
	}
}

#pragma mark - Update

- (void)resetSend
{
	[self removeMedia];
}

- (void)updateSend
{
	if (_hostView != nil)
	{
		NSLog(@"Update Send View");
		Send *send = [[Send alloc] initWithData:sendInfo];
		[_hostView updateModel:send mode:CKUpdateModeSynchronous];
	}
}

- (float)statusBarHeight
{
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}

@end
