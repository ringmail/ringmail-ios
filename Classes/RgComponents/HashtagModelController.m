#import "HashtagModelController.h"

#import <UIKit/UIColor.h>
#import <ObjectiveSugar/ObjectiveSugar.h>

#import "Card.h"
#import "CardsPage.h"
#import "HashtagCollectionViewController.h"
#import "RgNetwork.h"

NSString *const RG_HASHTAG_DIRECTORY = @"http://data.ringmail.com/hashtag/directory";

@implementation HashtagModelController
{
  NSInteger _numberOfObjects;
}

@synthesize mainList;
@synthesize mainCount;
@synthesize mainPath;

- (instancetype)init
{
    if (self = [super init]) {
        mainCount = [NSNumber numberWithInteger:0];
        mainList = nil;
    }
    return self;
}

- (void)fetchPageWithCount:(NSInteger)count caller:(HashtagCollectionViewController*)caller
{
	[caller.waitDelegate showWaiting];
	[[RgNetwork instance] hashtagDirectory:@{
		@"category_id": mainPath,
	} success:^(NSURLSessionTask *operation, id responseObject) {
		[caller.waitDelegate hideWaiting];
	    NSDictionary* res = responseObject;
		NSLog(@"API Response: %@", res);
        NSString *ok = [res objectForKey:@"result"];
        if (ok != nil && [ok isEqualToString:@"ok"])
		{
			mainList = res[@"directory"];
		}
		[caller enqueuePage:[self fetchNewCardsPageWithCount:count]];
	} failure:^(NSURLSessionTask *operation, NSError *error) {
		[caller.waitDelegate hideWaiting];
		NSLog(@"RingMail API Error: %@", [error localizedDescription]);
	}];
}

- (CardsPage *)fetchNewCardsPageWithCount:(NSInteger)count
{
    NSAssert(count >= 1, @"Count should be a positive integer");
    NSMutableArray *_cards = [NSMutableArray new];
    NSInteger added = 0;
    BOOL main = [self.mainPath isEqualToString:@"0"];
    for (NSUInteger i = 0; i < count; i++)
    {
        if ([mainCount intValue] == 0 && i == 0)
        {
            if (main)
            {
                Card *card = [[Card alloc] initWithData:@{
                    @"type": @"hashtag_directory_header",
                    @"text": @"Explore #Hashtags",
                } header:@NO];
                [_cards addObject:card];
                added++;
            }
            else
            {
                Card *card = [[Card alloc] initWithData:@{
                    @"text": @"Explore #Hashtags",
                } header:@YES];
                [_cards addObject:card];
                added++;
            }
        }
        else
        {
            NSInteger mainIndex = [mainCount intValue] + i - 1;
            if ([mainList count] > mainIndex)
            {
                NSDictionary *itemData = mainList[mainIndex];
                NSMutableDictionary *cardData = [NSMutableDictionary dictionaryWithDictionary:itemData];
                if (itemData != nil)
                {
                    UIImage *defaultImage = [UIImage imageNamed:@"avatar_unknown_small.png"];
                    cardData[@"image"] = defaultImage;
                    // Todo: translate to name
                    Card *card = [[Card alloc] initWithData:cardData header:[NSNumber numberWithBool:0]];
                    [_cards addObject:card];
                    added++;
                }
            }
        }
    }
    CardsPage *cardsPage = [[CardsPage alloc] initWithCards:_cards
                                                     position:[mainCount integerValue]];
    mainCount = [NSNumber numberWithInteger:[mainCount integerValue] + added];
    return cardsPage;
}

@end
