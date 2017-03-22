#import <Photos/Photos.h>

#import "Media.h"
#import "MediaContext.h"
#import "MediaComponent.h"

#import "UIColor+Hex.h"

@implementation MediaComponent

+ (instancetype)newWithMedia:(Media *)media context:(MediaContext *)context
{
   return [super newWithComponent:mediaComponent(media, context)];
}

static CKComponent *mediaComponent(Media *media, MediaContext *context)
{
	PHAsset *asset = media.data[@"asset"];
	return [CKInsetComponent newWithInsets:{.top = 0, .left = 0, .bottom = 0, .right = 1} component:
		[CKNetworkImageComponent newWithURL:[NSURL URLWithString:asset.localIdentifier]
			imageDownloader:context.cacheManager scenePath:nil size:{.height = 71, .width = 71 } options:{} attributes:{}]
	];
}

@end
