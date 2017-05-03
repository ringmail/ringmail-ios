#import "CKNetworkImageDownloading.h"
#import <Photos/Photos.h>

@interface MediaAssetProvider : NSObject <CKNetworkImageDownloading>

+ (instancetype)sharedManager;
- (instancetype)initWithCache:(PHCachingImageManager *)manager;
- (void)startCaching:(NSArray*)media targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options;

@end
