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

static NSInteger const pageSize = 50;

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout path:(NSString*)path
{
    if (self = [super initWithCollectionViewLayout:layout]) {
        _sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
        _cardModelController = [[HashtagModelController alloc] init];
        [_cardModelController setMainPath:path];
		self.loading = NO;
		self.eof = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *screenWidth = [NSString stringWithFormat:@"%f", [UIScreen mainScreen].applicationFrame.size.width];
	
    self.collectionView.backgroundColor = [UIColor colorWithHex:@"#f4f4f4" alpha:0.0f];
    self.collectionView.delegate = self;
    
    NSSet<NSString *> *imageNames = [NSSet setWithObjects:
        @"message_summary_video_normal.png",
        nil
    ];
    CardContext *context = [[CardContext alloc] initWithImageNames:imageNames];
    _dataSource = [[CKCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
                                                 supplementaryViewDataSource:nil
                                                           componentProvider:[self class]
                                                                     context:context
                                                   cellConfigurationFunction:nil];
    // Insert the initial section
    CKArrayControllerSections sections;
    sections.insert(0);
    [_dataSource enqueueChangeset:{sections, {}} constrainedSize:{}];
    [_cardModelController fetchPageWithCount:pageSize screenWidth:screenWidth caller:self];
}

- (void)enqueuePage:(CardsPage *)cardsPage
{
    NSArray *cards = cardsPage.cards;
    NSInteger position = cardsPage.position;
    
    BOOL hasitems = NO;
    // Convert the array of cards to a valid changeset
    CKArrayControllerInputItems items;
    for (NSInteger i = 0; i < [cards count]; i++)
	{
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

- (void)updateCollection:(BOOL)myActivity
{
    if (myActivity)
    {
        CKArrayControllerInputItems items;
        for (NSInteger i = 0; i < [[_cardModelController mainCount] integerValue]; i++)
		{
            items.remove([NSIndexPath indexPathForRow:i inSection:0]);
		}
        [_dataSource enqueueChangeset:{{}, items} constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size]];
        [self enqueuePage:[_cardModelController readActivityList]];
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
    return [InteractiveCardComponent newWithCard:card context:context];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentSize.height == 0)
	{
        return;
    }
    
    if (scrolledToBottomWithBuffer(scrollView.contentOffset, scrollView.contentSize, scrollView.contentInset, scrollView.bounds))
	{
		if (! self.loading && ! self.eof)
		{
			self.loading = YES;
		    NSString *screenWidth = [NSString stringWithFormat:@"%f", [UIScreen mainScreen].applicationFrame.size.width];
			[_cardModelController fetchPageWithCount:pageSize screenWidth:screenWidth caller:self];
		}
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
