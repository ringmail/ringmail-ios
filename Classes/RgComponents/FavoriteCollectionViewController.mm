#import <Foundation/Foundation.h>
#import <ComponentKit/ComponentKit.h>

#import "Favorite.h"
#import "FavoriteContext.h"
#import "FavoriteComponent.h"
#import "FavoriteCollectionViewController.h"
#import "FavoriteModelController.h"
#import "FavoritesPage.h"
#import "RgManager.h"

@interface FavoriteCollectionViewController () <CKComponentProvider, UICollectionViewDelegateFlowLayout>
@end

@implementation FavoriteCollectionViewController
{
    CKCollectionViewDataSource *_dataSource;
    FavoriteModelController *_modelController;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
    FavoritesPage* _currentFavPage;
}

static NSInteger const pageSize = 50;

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    if (self = [super initWithCollectionViewLayout:layout]) {
        _sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight];
        _modelController = [[FavoriteModelController alloc] init];
        _currentFavPage = [[FavoritesPage alloc] init];
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
		
		FavoriteContext *context = [[FavoriteContext alloc] init];
		_dataSource = [[CKCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
													 supplementaryViewDataSource:nil
															   componentProvider:[self class]
																		 context:context
													   cellConfigurationFunction:nil];
		// Insert the initial section
		CKArrayControllerSections sections;
		sections.insert(0);
		[_dataSource enqueueChangeset:{sections, {}} constrainedSize:{}];
        
	});
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCollection) name:kRgContactsUpdated object:nil];
}


- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgContactsUpdated object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self updateCollection];
}


- (void)updateCollection
{
    CKArrayControllerInputItems items;
    
    NSArray *curFavs = _currentFavPage.favorites;
    
    if (curFavs.count)
    {
        for (NSInteger i = 0; i < curFavs.count; i++)
        {
            items.remove([NSIndexPath indexPathForRow:i inSection:0]);
        }
        [_dataSource enqueueChangeset:{{}, items} constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _enqueuePage:[_modelController fetchNewFavoritesPageWithCount:pageSize]];
    });
}

- (void)_enqueuePage:(FavoritesPage *)favsPage
{
    NSArray *favs = favsPage.favorites;
    
    // Convert the array of cards to a valid changeset
    BOOL hasitems = NO;
    CKArrayControllerInputItems items;
    
    _currentFavPage = favsPage;
    
    for (NSInteger i = 0; i < [favs count]; i++) {
        items.insert([NSIndexPath indexPathForRow:i inSection:0], favs[i]);
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

+ (CKComponent *)componentForModel:(Favorite *)fav context:(FavoriteContext *)context
{
    return [FavoriteComponent newWithFavorite:fav context:context];
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
