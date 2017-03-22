#import "MediaContext.h"

@implementation MediaContext
{
}

- (instancetype)initWithMedia:(NSArray*)media targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options;
{
  if (self = [super init]) {
      self.cacheManager = [MediaAssetProvider sharedManager];
	  [self.cacheManager startCaching:media targetSize:targetSize contentMode:contentMode options:options];
  }
  return self;
}

@end
