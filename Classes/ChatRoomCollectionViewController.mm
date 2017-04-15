#import <Foundation/Foundation.h>
#import <ComponentKit/ComponentKit.h>

#import "ChatElement.h"
#import "ChatElementContext.h"
#import "ChatElementComponent.h"
#import "ChatRoomCollectionViewController.h"

@interface ChatRoomCollectionViewController () <CKComponentProvider, UICollectionViewDelegateFlowLayout>
@end

@implementation ChatRoomCollectionViewController
{
    NSMutableArray *_elements;
	NSNumber *_mainCount;
	CKCollectionViewDataSource *_dataSource;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
}

@synthesize chatThreadID;
@synthesize lastMessageID;

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout chatThreadID:(NSNumber*)threadID elements:(NSArray*)elems
{
    if (self = [super initWithCollectionViewLayout:layout]) {
        _sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight];
		_elements = [NSMutableArray array];
		for (NSDictionary* i in elems)
		{
			[_elements addObject:[NSMutableDictionary dictionaryWithDictionary:i]];
		}
		_mainCount = [NSNumber numberWithInteger:0];
		self.lastMessageID = nil;
		self.chatThreadID = threadID;
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
		
		// Generate the initial changeset
		CKArrayControllerInputItems items;
		NSInteger added = 0;
		NSInteger count = [_elements count];
    	for (NSUInteger i = 0; i < count; i++)
        {
			if (i == 0)
			{
				_elements[i][@"first_element"] = @YES;
			}
			if (i == count - 1)
			{
				_elements[i][@"last_element"] = @YES;
			}
			lastMessageID = [_elements[i][@"id"] copy];
			ChatElement* item = [[ChatElement alloc] initWithData:[_elements objectAtIndex:i]];
			items.insert([NSIndexPath indexPathForRow:i inSection:0], item);
			added++;
    	}
		if (added > 0)
		{
			_mainCount = [NSNumber numberWithInteger:[_mainCount integerValue] + added];
			__block NSInteger lastIndex = [_mainCount intValue] - 1;
			self.collectionView.hidden = YES;
			[_dataSource enqueueChangeset:{{}, items} constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size] complete:^(BOOL i){
				NSLog(@"Enqueue batch complete! Last item: %ld", lastIndex);
				[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:lastIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
				self.collectionView.hidden = NO;
			}];
		}
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

#pragma mark - RingMail

- (void)scrollToBottom:(BOOL)animate
{
	NSInteger lastIndex = [_mainCount intValue] - 1;
	[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:lastIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:animate];
}

- (void)appendMessages:(NSArray*)msgs
{
	if ([msgs count] == 0)
	{
		return; // no messages
	}
	
	// Generate the additional changeset
	dispatch_async(dispatch_get_main_queue(), ^{
    	CKArrayControllerInputItems items;
		
		// remove last_element tag
		NSInteger count = [_elements count];
		if (count > 0)
		{
			NSInteger last = count - 1;
    		NSMutableDictionary *lastData = _elements[last];
    		[lastData removeObjectForKey:@"last_element"];
    		ChatElement* lastItem = [[ChatElement alloc] initWithData:lastData];
    		items.update([NSIndexPath indexPathForRow:last inSection:0], lastItem);
		}
	
    	for (NSDictionary* i in msgs)
    	{
    		[_elements addObject:[NSMutableDictionary dictionaryWithDictionary:i]];
    	}
		
		// add new items
    	NSInteger added = 0;
    	NSInteger start = [_mainCount intValue];
		count = [_elements count];
    	for (NSInteger i = start; i < count; i++)
        {
			if (i == count - 1)
			{
				_elements[i][@"last_element"] = @YES;
			}
			lastMessageID = [_elements[i][@"id"] copy];
			ChatElement* item = [[ChatElement alloc] initWithData:[_elements objectAtIndex:i]];
			items.insert([NSIndexPath indexPathForRow:i inSection:0], item);
			added++;
    	}
    	if (added > 0)
    	{
    		_mainCount = [NSNumber numberWithInteger:[_mainCount integerValue] + added];
    		__block NSInteger lastIndex = [_mainCount intValue] - 1;
    		[_dataSource enqueueChangeset:{{}, items} constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size] complete:^(BOOL i){
    			[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:lastIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
    		}];
    	}
	});
}

- (void)updateMessage
{
}

@end
