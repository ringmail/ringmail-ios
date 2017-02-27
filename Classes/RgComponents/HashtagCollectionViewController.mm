//
//  HashtagCollectionViewController.m
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#import <Foundation/Foundation.h>
#import <ComponentKit/ComponentKit.h>
#import "UIColor+Hex.h"
#import "HashtagCollectionViewController.h"
#import "InteractiveCardComponent.h"
#import "HashtagModelController.h"
#import "Card.h"
#import "CardContext.h"
#import "CardsPage.h"

@interface HashtagCollectionViewController () <CKComponentProvider, UICollectionViewDelegateFlowLayout>
@end

@implementation HashtagCollectionViewController
{
    CKCollectionViewDataSource *_dataSource;
    HashtagModelController *_cardModelController;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
}

@synthesize waitDelegate;

static NSInteger const pageSize = 42;

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout path:(NSString*)path
{
    if (self = [super initWithCollectionViewLayout:layout]) {
        _sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
        _cardModelController = [[HashtagModelController alloc] init];
        [_cardModelController setMainPath:path];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Preload images for the component context that need to be used in component preparation. Components preparation
    // happens on background threads but +[UIImage imageNamed:] is not thread safe and needs to be called on the main
    // thread. The preloaded images are then cached on the component context for use inside components.
    NSDictionary *images = @{};
	
    self.collectionView.backgroundColor = [UIColor colorWithHex:@"#f4f4f4" alpha:0.0f];
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
	[_cardModelController fetchPageWithCount:pageSize caller:self];
}

- (void)enqueuePage:(CardsPage *)cardsPage
{
    NSArray *cards = cardsPage.cards;
    NSInteger position = cardsPage.position;
    
    BOOL hasitems = NO;
    // Convert the array of cards to a valid changeset
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
        //[self enqueuePage:[_cardModelController fetchNewCardsPageWithCount:pageSize]];
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
