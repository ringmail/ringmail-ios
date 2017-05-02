//
//  MediaAssetProvider.m

#import "MediaAssetProvider.h"

@interface MediaAssetProvider ()

@property (nonatomic, strong) PHCachingImageManager *cacheManager;

@end

@implementation MediaAssetProvider

+ (instancetype)sharedManager {
	static MediaAssetProvider *instance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		PHCachingImageManager *manager = [[PHCachingImageManager alloc] init];
		instance = [[self alloc] initWithCache:manager];
	});
	return instance;
}

- (instancetype)initWithCache:(PHCachingImageManager *)manager {
	if (self = [super init]) {
		_cacheManager = manager;
	}
	return self;
}

#pragma mark - Start Caching

- (void)startCaching:(NSArray*)media targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options
{
	[_cacheManager startCachingImagesForAssets:media targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options];
}

#pragma mark - CKNetworkImageDownloading

- (id)downloadImageWithURL:(NSURL *)URL
                 scenePath:(id)scenePath
                    caller:(id)caller
             callbackQueue:(dispatch_queue_t)callbackQueue
     downloadProgressBlock:(void (^)(CGFloat progress))downloadProgressBlock
                completion:(void (^)(CGImageRef image, NSError *error))completion {
	
	// Validate the input URL
	if (!URL)
	{
		NSString *domain = [NSBundle bundleForClass:[self class]].bundleIdentifier;
		NSString *description = @"The URL of the image to download is unspecified";
		completion(nil, [NSError errorWithDomain:domain code:0 userInfo:@{ NSLocalizedDescriptionKey: description }]);
		return nil;
	}
	
	//NSLog(@"Get asset for local id: %@", URL.absoluteString);
	
	PHFetchResult* fr = [PHAsset fetchAssetsWithLocalIdentifiers:@[URL.absoluteString] options:nil];
	if (fr[0])
	{
		PHImageRequestOptions *params = [[PHImageRequestOptions alloc] init];
		params.resizeMode = PHImageRequestOptionsResizeModeExact;
		NSNumber* proc = [NSNumber numberWithInt:[_cacheManager requestImageForAsset:fr[0] targetSize:CGSizeMake(142, 142) contentMode:PHImageContentModeAspectFill options:params resultHandler:^(UIImage *result, NSDictionary *info) {
    	    dispatch_async(callbackQueue ? : dispatch_get_main_queue(), ^{
				NSError *error = [NSError new];
    			completion(result.CGImage, error);
    		});
		}]];
		return proc;
	}
	
	return nil;
}

- (void)cancelImageDownload:(id)download
{
	// Is it possible to cancel this request? (Yes...)
}

@end
