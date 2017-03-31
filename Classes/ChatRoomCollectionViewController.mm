#import <Foundation/Foundation.h>
#import <ComponentKit/ComponentKit.h>

#import "ChatElement.h"
#import "ChatElementContext.h"
#import "ChatElementComponent.h"
#import "ChatRoomCollectionViewController.h"
#import "ChatRoomModelController.h"
#import "ChatElementPage.h"

@interface ChatRoomCollectionViewController () <CKComponentProvider, UICollectionViewDelegateFlowLayout>
@end

@implementation ChatRoomCollectionViewController
{
    CKCollectionViewDataSource *_dataSource;
    ChatRoomModelController *_modelController;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
}

static NSInteger const pageSize = 50;

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout chatThreadID:(NSNumber*)threadID
{
    if (self = [super initWithCollectionViewLayout:layout]) {
        _sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight];
        _modelController = [[ChatRoomModelController alloc] initWithID:threadID];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Preload images for the component context that need to be used in component preparation. Components preparation
    // happens on background threads but +[UIImage imageNamed:] is not thread safe and needs to be called on the main
    // thread. The preloaded images are then cached on the component context for use inside components.
	
	//NSMutableDictionary *images = [NSMutableDictionary dictionaryWithDictionary:@{}];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		self.collectionView.backgroundColor = [UIColor clearColor];
		self.collectionView.delegate = self;
		
		ChatElementContext *context = [[ChatElementContext alloc] init];
		_dataSource = [[CKCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
													 supplementaryViewDataSource:nil
															   componentProvider:[self class]
																		 context:context
													   cellConfigurationFunction:nil];
		// Insert the initial section
		CKArrayControllerSections sections;
		sections.insert(0);
		[_dataSource enqueueChangeset:{sections, {}} constrainedSize:{}];
		[self _enqueuePage:[_modelController fetchNewChatElementPageWithCount:pageSize]];
	});
}

- (void)_enqueuePage:(ChatElementPage *)favsPage
{
    NSArray *favs = favsPage.elements;
    NSInteger position = favsPage.position;
    
    // Convert the array of cards to a valid changeset
    BOOL hasitems = NO;
    CKArrayControllerInputItems items;
    for (NSInteger i = 0; i < [favs count]; i++) {
        items.insert([NSIndexPath indexPathForRow:position + i inSection:0], favs[i]);
        hasitems = YES;
    }
    if (hasitems)
    {
        [_dataSource enqueueChangeset:{{}, items} constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size]];
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

+ (CKComponent *)componentForModel:(ChatElement *)fav context:(ChatElementContext *)context
{
    return [ChatElementComponent newWithChatElement:fav context:context];
}

#pragma mark - UIScrollViewDelegate

/*

TODO: fix this

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if( scrollView.contentSize.height == 0 ) {
        return ;
    }
    
    if (scrolledToBottomWithBuffer(scrollView.contentOffset, scrollView.contentSize, scrollView.contentInset, scrollView.bounds)) {
        [self _enqueuePage:[_modelController fetchNewFavoritesPageWithCount:pageSize]];
    }
}

static BOOL scrolledToBottomWithBuffer(CGPoint contentOffset, CGSize contentSize, UIEdgeInsets contentInset, CGRect bounds)
{
    CGFloat buffer = CGRectGetHeight(bounds) - contentInset.top - contentInset.bottom;
    const CGFloat maxVisibleY = (contentOffset.y + bounds.size.height);
    const CGFloat actualMaxY = (contentSize.height + contentInset.bottom);
    return ((maxVisibleY + buffer) >= actualMaxY);
}

*/

@end
