#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MediaAssetProvider.h"

@interface MediaContext : NSObject

@property (strong, nonatomic, readwrite) MediaAssetProvider *cacheManager;

- (instancetype)initWithMedia:(NSArray*)media targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options;

@end
