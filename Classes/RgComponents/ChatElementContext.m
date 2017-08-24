#import "ChatElementContext.h"
#import "LinphoneManager.h"
#import "UIImage+Scale.h"

@implementation ChatElementContext
{
  NSMutableDictionary *_images;
}

- (instancetype)initWithImages:(NSMutableDictionary *)addImages
{
  if (self = [super init]) {
      _images = addImages;
  }
  return self;
}

- (UIImage *)imageNamed:(NSString *)imageName
{
    return _images[imageName];
}

@end
