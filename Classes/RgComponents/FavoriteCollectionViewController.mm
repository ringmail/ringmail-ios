//
//  FavoriteCollectionViewController.m
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#import <Foundation/Foundation.h>
#import <ComponentKit/ComponentKit.h>
#import "UIColor+Hex.h"
#import "FavoriteCollectionViewController.h"
#import "InteractiveCardComponent.h"
#import "FavoriteModelController.h"
#import "Card.h"
#import "CardContext.h"
#import "CardsPage.h"

@interface FavoriteCollectionViewController () <CKComponentProvider, UICollectionViewDelegateFlowLayout>
@end

@implementation FavoriteCollectionViewController
{
    CKCollectionViewDataSource *_dataSource;
    FavoriteModelController *_cardModelController;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
}

static NSInteger const pageSize = 10;

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    if (self = [super initWithCollectionViewLayout:layout]) {
        _sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
        _cardModelController = [[FavoriteModelController alloc] init];
		[_cardModelController setHeader:@"Favorites"];
        //self.title = @"Wilde Guess";
        //self.navigationItem.prompt = @"Tap to reveal which cards are from Oscar Wilde";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Preload images for the component context that need to be used in component preparation. Components preparation
    // happens on background threads but +[UIImage imageNamed:] is not thread safe and needs to be called on the main
    // thread. The preloaded images are then cached on the component context for use inside components.
    NSMutableDictionary *images = [NSMutableDictionary dictionaryWithDictionary:@{
         @"button_call":[UIImage imageNamed:@"phone.png"],
         @"button_chat":[UIImage imageNamed:@"quote.png"],
         @"button_video":[UIImage imageNamed:@"camera.png"],
    }];
    
    self.collectionView.backgroundColor = [UIColor colorWithHex:@"#f4f4f4" alpha:1.0f];
    self.collectionView.delegate = self;
    
    CardContext *context = [[CardContext alloc] initWithImages:images];
    _dataSource = [[CKCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
                                                 supplementaryViewDataSource:nil
                                                           componentProvider:[self class]
                                                                     context:context
                                                   cellConfigurationFunction:nil];
    // Insert the initial section
    CKArrayControllerSections sections;
    sections.insert(0);
    [_dataSource enqueueChangeset:{sections, {}} constrainedSize:{}];
    [self _enqueuePage:[_cardModelController fetchNewCardsPageWithCount:pageSize]];
}

- (void)_enqueuePage:(CardsPage *)cardsPage
{
    NSArray *cards = cardsPage.cards;
    NSInteger position = cardsPage.position;
    
    // Convert the array of cards to a valid changeset
    BOOL hasitems = NO;
    CKArrayControllerInputItems items;
    for (NSInteger i = 0; i < [cards count]; i++) {
        items.insert([NSIndexPath indexPathForRow:position + i inSection:0], cards[i]);
        hasitems = YES;
    }
    if (hasitems)
    {
        [_dataSource enqueueChangeset:{{}, items}
                      constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size]];
    }
}

#pragma mark - Update collection

- (void)updateCollection
{
    NSArray *current = [_cardModelController mainList];
    NSArray *newlist = [_cardModelController readMainList];
    
    NSInteger curcount = [current count];
    NSInteger newcount = [newlist count];
    // Generate changeset
    NSInteger viewcount = [[_cardModelController mainCount] integerValue];
    if (viewcount < pageSize)
    {
        viewcount = pageSize;
    }
    __block CKArrayControllerInputItems items;
    for (NSInteger i = 1; i < viewcount; i++)
    {
        NSInteger j = i - 1;
        BOOL hascur = NO;
        BOOL hasnew = NO;
        if (j < curcount)
        {
            hascur = YES;
        }
        if (j < newcount)
        {
            hasnew = YES;
        }
        if (hascur && hasnew)
        {
            NSNumber* curId = [current[j] objectForKey:@"id"];
            NSNumber* newId = [newlist[j] objectForKey:@"id"];
            if (! [curId isEqualToNumber:newId]) // item changed
            {
                Card *card = [[Card alloc] initWithData:newlist[j]
                                                 header:[NSNumber numberWithBool:0]];
                items.update([NSIndexPath indexPathForRow:i inSection:0], card);
            }
            else
            {
                NSDate* curDate = [current[j] objectForKey:@"timestamp"];
                NSDate* newDate = [newlist[j] objectForKey:@"timestamp"];
                if ([curDate compare:newDate] != NSOrderedSame)
                {
                    // Regenerate card
                    Card *card = [[Card alloc] initWithData:newlist[j]
                                                     header:[NSNumber numberWithBool:0]];
                    items.update([NSIndexPath indexPathForRow:i inSection:0], card);
                }
                else
                {
                    NSNumber *curUnread = [current[j] objectForKey:@"unread"];
                    NSNumber *newUnread = [newlist[j] objectForKey:@"unread"];
                    if (curUnread != nil && newUnread != nil)
                    {
                        if ([curUnread integerValue] != [newUnread integerValue])
                        {
                            // Regenerate card
                            Card *card = [[Card alloc] initWithData:newlist[j]
                                                             header:[NSNumber numberWithBool:0]];
                            items.update([NSIndexPath indexPathForRow:i inSection:0], card);
                        }
                    }
                }
            }
        }
        else if (hasnew)
        {
            Card *card = [[Card alloc] initWithData:newlist[j]
                                             header:[NSNumber numberWithBool:0]];
            items.insert([NSIndexPath indexPathForRow:i inSection:0], card);
            [_cardModelController setMainCount:[NSNumber numberWithInt:[[_cardModelController mainCount] intValue] + 1]];
            
        }
        else if (hascur)
        {
            // need to remove
            items.remove([NSIndexPath indexPathForRow:i inSection:0]);
            [_cardModelController setMainCount:[NSNumber numberWithInt:[[_cardModelController mainCount] intValue] - 1]];
        }
    }
    [_cardModelController setMainList:newlist];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_dataSource enqueueChangeset:{{}, items}
                      constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size]];
    });
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [_dataSource sizeForItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView
       willDisplayCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [_dataSource announceWillAppearForItemInCell:cell];
}

- (void)collectionView:(UICollectionView *)collectionView
  didEndDisplayingCell:(UICollectionViewCell *)cell
    forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [_dataSource announceDidDisappearForItemInCell:cell];
}

#pragma mark - CKComponentProvider

+ (CKComponent *)componentForModel:(Card *)card context:(CardContext *)context
{
    return [InteractiveCardComponent
            newWithCard:card
            context:context];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if( scrollView.contentSize.height == 0 ) {
        return ;
    }
    
    if (scrolledToBottomWithBuffer(scrollView.contentOffset, scrollView.contentSize, scrollView.contentInset, scrollView.bounds)) {
        [self _enqueuePage:[_cardModelController fetchNewCardsPageWithCount:pageSize]];
    }
}

static BOOL scrolledToBottomWithBuffer(CGPoint contentOffset, CGSize contentSize, UIEdgeInsets contentInset, CGRect bounds)
{
    CGFloat buffer = CGRectGetHeight(bounds) - contentInset.top - contentInset.bottom;
    const CGFloat maxVisibleY = (contentOffset.y + bounds.size.height);
    const CGFloat actualMaxY = (contentSize.height + contentInset.bottom);
    return ((maxVisibleY + buffer) >= actualMaxY);
}

@end
