#import <Photos/Photos.h>

#import "Media.h"
#import "MediaContext.h"
#import "MediaComponent.h"
#import "RgManager.h"

#import "UIColor+Hex.h"

@implementation MediaComponent

@synthesize localData;

+ (instancetype)newWithMedia:(Media *)media context:(MediaContext *)context
{
    MediaComponent* m = [super newWithComponent:mediaComponent(media, context)];
    m.localData = media.data;
	return m;
}

static CKComponent *mediaComponent(Media *media, MediaContext *context)
{
	//NSLog(@"Media Data: %@", media.data);
	UIImage *thumb = media.data[@"thumbnail"];
	return [CKInsetComponent newWithInsets:{.top = 0, .left = 0, .bottom = 0, .right = 1} component:
		[CKButtonComponent newWithTitles:{} titleColors:{} images:{
			{UIControlStateNormal, thumb},
		} backgroundImages:{} titleFont:nil selected:NO enabled:YES action:@selector(actionSetMedia:) size:{.height = 71, .width = 71} attributes:{} accessibilityConfiguration:{}]
	];
}

- (void)actionSetMedia:(CKButtonComponent *)sender
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	[[NSNotificationCenter defaultCenter] postNotificationName:kRgSendComponentAddMedia object:nil userInfo:@{
		@"asset": [self localData][@"asset"]
	}];
}

@end
