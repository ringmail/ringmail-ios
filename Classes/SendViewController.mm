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

@interface SendViewController () <CKComponentProvider, CKComponentHostingViewDelegate>

@end

@implementation SendViewController
{
    CKComponentDataSource *_componentDataSource;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
    CKComponentHostingView *_hostView;
}

- (id)init
{
	if (self = [super init])
	{
		self->_hostView = nil;
		self->_componentDataSource = nil;
		self->_sizeRangeProvider = nil;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if (self->_hostView == nil)
	{
		// load recent media
		int max = 25;
		int count = 0;
		NSMutableArray *assets = [NSMutableArray new];
		PHFetchOptions *mainopts = [[PHFetchOptions alloc] init];
		mainopts.sortDescriptors = @[
			[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:NO],
        ];
        PHFetchResult *collects = [PHAssetCollection fetchMomentsWithOptions:mainopts];
        for (PHAssetCollection *collection in collects)
		{
			NSLog(@"Collection(%@): %@", collection.localizedTitle, collection);
			PHFetchOptions *opts = [[PHFetchOptions alloc] init];
			opts.fetchLimit = max;
			opts.sortDescriptors = @[
				[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
            ];
			PHFetchResult *fr = [PHAsset fetchAssetsInAssetCollection:collection options:opts];
            for (PHAsset *asset in fr)
			{
				if (count < max)
				{
					[assets addObject:asset];
					count++;
				}
            }
			NSLog(@"Assets 1: %@", assets);
			if (count == max)
			{
				break;
			}
        }
		[assets sortUsingComparator:^NSComparisonResult(PHAsset* obj1, PHAsset* obj2) {
			return [obj2.creationDate compare:obj1.creationDate];
		}];
		NSLog(@"Assets 2: %@", assets);
	
		// build panel
		CGFloat height = self.view.frame.size.height;
		CGFloat width = [[UIScreen mainScreen] bounds].size.width;
		NSLog(@"Height: %f", height);
		_sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
		_hostView = [[CKComponentHostingView alloc] initWithComponentProvider:[self class] sizeRangeProvider:_sizeRangeProvider];
		_hostView.delegate = self;
		_hostView.frame = CGRectMake(0, 50, width, height);

		SendContext *context = [[SendContext alloc] init];
		[_hostView updateContext:context mode:CKUpdateModeSynchronous];
		
		Send *send = [[Send alloc] initWithData:@{
			@"media": assets,
		}];
		[_hostView updateModel:send mode:CKUpdateModeSynchronous];
		
		[self.view addSubview:_hostView];
	}
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
