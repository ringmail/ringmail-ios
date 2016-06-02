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
        mainPath = RG_HASHTAG_DIRECTORY;
    }
    return self;
}

- (void)fetchPageWithCount:(NSInteger)count caller:(HashtagCollectionViewController*)caller
{
	[caller.waitDelegate showWaiting];
	[[RgNetwork instance] hashtagDirectory:@{
		@"path": mainPath,
	} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		[caller.waitDelegate hideWaiting];
	    NSDictionary* res = responseObject;
		NSLog(@"API Response: %@", res);
        NSString *ok = [res objectForKey:@"result"];
        if (ok != nil && [ok isEqualToString:@"ok"])
		{
			mainList = res[@"directory"];
		}
		[caller enqueuePage:[self fetchNewCardsPageWithCount:count]];
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		[caller.waitDelegate hideWaiting];
		NSLog(@"RingMail API Error: %@", [error localizedDescription]);
	}];
}

- (CardsPage *)fetchNewCardsPageWithCount:(NSInteger)count
{
    NSAssert(count >= 1, @"Count should be a positive integer");
    NSString* title = @"Hashtag Categories";
//    if (mainList == nil)
//    {
//        // Initialize
//        mainList = [NSMutableArray array];
//        if ([mainPath isEqualToString:RG_HASHTAG_DIRECTORY])
//        {
//            title = @"Hashtag Categories";
//            [mainList push:@{
//                             @"type": @"hashtag_category",
//                             @"name": @"Lifestyle",
//							 @"pattern": @"wov",
//							 @"color": @"grapefruit",
//                             }];
//            [mainList push:@{
//                             @"type": @"hashtag_category",
//                             @"name": @"Technology",
//							 @"pattern": @"squared_metal",
//							 @"color": @"denim",
//                             }];
//            [mainList push:@{
//                             @"type": @"hashtag_category",
//                             @"name": @"Stocks",
//							 @"pattern": @"swirl_pattern",
//							 @"color": @"grass",
//                             }];
//            [mainList push:@{
//                             @"type": @"hashtag_category",
//                             @"name": @"News",
//							 @"pattern": @"upfeathers",
//							 @"color": @"turquoise",
//                             }];
//            [mainList push:@{
//                             @"type": @"hashtag_category",
//                             @"name": @"Shopping",
//							 @"pattern": @"dimension",
//							 @"color": @"banana",
//                             }];
//        }
//        else
//        {
//            title = @"Hashtag Categories";
//            [mainList push:@{
//                @"type": @"hashtag_category_header",
//                @"name": mainPath,
//				@"pattern": @"swirl_pattern",
//				@"color": @"grape",
//            }];
//            for (NSUInteger i = 0; i < 25; i++)
//            {
//                [mainList push:@{
//                    @"type": @"hashtag",
//                    @"label": [NSString stringWithFormat:@"#tag%lu", (unsigned long)i],
//                    @"session_tag": [NSString stringWithFormat:@"#tag%lu", (unsigned long)i],
//					@"image": [UIImage imageNamed:@"avatar_unknown_small.png"],
//                }];
//            }
//        }
//    }
    NSMutableArray *_cards = [NSMutableArray new];
    NSInteger added = 0;
    for (NSUInteger i = 0; i < count; i++)
    {
        if ([mainCount intValue] == 0 && i == 0)
        {
            NSNumber *headerCell = [NSNumber numberWithBool:1];
            Card *card = [[Card alloc] initWithData:@{@"text": title}
                                             header:headerCell];
            [_cards addObject:card];
            added++;
        }
        else
        {
            NSInteger mainIndex = [mainCount intValue] + i - 1;
            if ([mainList count] > mainIndex)
            {
                NSDictionary *itemData = mainList[mainIndex];
                if (itemData != nil)
                {
                    // Todo: translate to name
                    Card *card = [[Card alloc] initWithData:itemData
                                            header:[NSNumber numberWithBool:0]];
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
