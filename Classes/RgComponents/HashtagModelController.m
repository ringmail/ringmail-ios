#import "HashtagModelController.h"

#import <UIKit/UIColor.h>
#import <ObjectiveSugar/ObjectiveSugar.h>

#import "Card.h"
#import "CardsPage.h"
#import "HashtagCollectionViewController.h"
#import "RgNetwork.h"
#import "LinphoneManager.h"
#import "Utils.h"

NSString *const RG_HASHTAG_DIRECTORY = @"http://data.ringmail.com/hashtag/directory";

@implementation HashtagModelController
{
  NSInteger _numberOfObjects;
}

@synthesize mainList;
@synthesize mainCount;
@synthesize mainPath;
@synthesize mainHeader;

- (instancetype)init
{
    if (self = [super init]) {
        mainCount = [NSNumber numberWithInteger:0];
        mainList = nil;
		mainHeader = nil;
    }
    return self;
}

- (NSMutableArray *)readMainList
{
    NSArray* list = [[[LinphoneManager instance] chatManager] dbGetMainList];
    
    return [NSMutableArray arrayWithArray:[self buildCards:list]];
}

- (NSArray *)buildCards:(NSArray*)list
{
    NSMutableArray *htagList = [NSMutableArray array];
    int item = 0;
    UIImage *defaultImage = [UIImage imageNamed:@"avatar_unknown_small.png"];
    for (NSDictionary* r in list)
    {
        NSString *address = [r objectForKey:@"session_tag"];
        
        NSMutableDictionary *newdata = [NSMutableDictionary dictionaryWithDictionary:r];
        
        [newdata setObject:[NSNumber numberWithInt:item++] forKey:@"index"];
        
        if ([address length] > 0 && [[address substringToIndex:1] isEqualToString:@"#"])
        {
            [newdata setObject:@"hashtag" forKey:@"type"];
            [newdata setObject:address forKey:@"label"];
            [newdata setObject:defaultImage forKey:@"image"];
            
            if (![[r objectForKey:@"avatar_img"] isEqual:[NSNull null]] && ![[r objectForKey:@"img_path"] isEqual:[NSNull null]]) {
                NSString *avatarUrl = [NSString stringWithFormat:@"%@%@%@%@",@"https://",[RgManager ringmailHost],[r objectForKey:@"img_path"],[r objectForKey:@"avatar_img"]];
                [newdata setObject:avatarUrl forKey:@"avatar_url"];
            }
            else
                [newdata setObject:@"" forKey:@"avatar_url"];
            
            LOGI(@"RingMail: List Object: %@", newdata);
            [htagList addObject:newdata];
        }
    }
    return htagList;
}


- (void)fetchPageWithCount:(NSInteger)count screenWidth:(NSString*)screenWidth caller:(HashtagCollectionViewController*)caller
{
    [caller.waitDelegate showWaiting];
    [[RgNetwork instance] hashtagDirectory:@{
        @"category_id": mainPath,
        @"screen_width": screenWidth,
    } success:^(NSURLSessionTask *operation, id responseObject) {
        [caller.waitDelegate hideWaiting];
        NSDictionary* res = responseObject;
        NSLog(@"API Response: %@", res);
        NSString *ok = [res objectForKey:@"result"];
        if (ok != nil && [ok isEqualToString:@"ok"])
        {
            mainList = res[@"directory"];
			mainHeader = res[@"header"];
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
    
    for (NSUInteger i = 0; i < count; i++)
    {
        if ([mainCount intValue] == 0 && i == 0)
        {
            if (mainHeader)
            {
                Card* card = [[Card alloc] initWithData:@{
                    @"type": mainHeader[@"type"],
                    @"text": @"",
                    @"header_img_url": mainHeader[@"image_url"],
                    @"header_img_ht": mainHeader[@"image_height"],
                    //@"name": mainHeader[@"category_name"],
                    //@"parent_name": mainHeader[@"parent_name"],
                    @"parent_name": mainHeader[@"category_name"],
                    @"parent2parent_name": mainHeader[@"top_name"],
                } header:@NO];
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
