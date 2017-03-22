#import "MediaModelController.h"

#import <UIKit/UIColor.h>

#import "Media.h"
#import "MediaPage.h"
#import "LinphoneManager.h"

@implementation MediaModelController

@synthesize mediaData;
@synthesize mainCount;

- (MediaModelController *)initWithMedia:(NSArray*)media
{
    if (self = [super init]) {
        mainCount = [NSNumber numberWithInteger:0];
		mediaData = media;
    }
    return self;
}

- (MediaPage *)fetchNewMediaPageWithCount:(NSInteger)count;
{
	NSAssert(count >= 1, @"Count should be a positive integer");
	NSMutableArray *mediaList = [NSMutableArray array];
	NSInteger added = 0;
	for (NSUInteger i = 0; i < count; i++)
    {
		NSInteger mainIndex = [mainCount intValue] + i;
		if ([mediaData count] > mainIndex)
		{
			Media* mediaItem = [[Media alloc] initWithData:@{
				@"asset": [mediaData objectAtIndex:mainIndex],
			}];
			[mediaList addObject:mediaItem];
			added++;
		}
	}
	MediaPage *mediaPage = [[MediaPage alloc] initWithMedia:mediaList position:[mainCount integerValue]];
	mainCount = [NSNumber numberWithInteger:[mainCount integerValue] + added];
	return mediaPage;
}

@end
