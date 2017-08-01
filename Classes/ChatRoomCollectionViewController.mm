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
    GGMutableDictionary *_elementPaths;
	NSNumber *_mainCount;
	CKCollectionViewDataSource *_dataSource;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
}

@synthesize chatThread;
@synthesize lastMessageID;

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout chatThread:(RKThread*)thread
{
    if (self = [super initWithCollectionViewLayout:layout]) {
        _sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleWidthAndHeight];
		_elements = [NSMutableArray array];
		_elementPaths = [[GGMutableDictionary alloc] init];
		_mainCount = [NSNumber numberWithInteger:0];
		self.lastMessageID = nil;
		self.chatThread = thread;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	NSArray *elems = [[RKCommunicator sharedInstance] listThreadItems:chatThread];
	NSInteger j = 0;
	for (RKItem* i in elems)
	{
		if (_elementPaths[i.itemId] == nil)
		{
    		[_elements addObject:[NSMutableDictionary dictionaryWithDictionary:@{
    			@"item": i,
    		}]];
    		_elementPaths[i.itemId] = [NSNumber numberWithInteger:j++];
		}
	}
	
    // Preload images for the component context that need to be used in component preparation. Components preparation
    // happens on background threads but +[UIImage imageNamed:] is not thread safe and needs to be called on the main
    // thread. The preloaded images are then cached on the component context for use inside components.
	
	//NSMutableDictionary *images = [NSMutableDictionary dictionaryWithDictionary:@{}];
	
	self.collectionView.backgroundColor = [UIColor clearColor];
	self.collectionView.delegate = self;
	
	ChatElementContext *context = [[ChatElementContext alloc] initWithImages:@{
		@"message_summary_moment_normal.png": [UIImage imageNamed:@"message_summary_moment_normal.png"],
		@"message_moment_normal.png": [UIImage imageNamed:@"message_moment_normal.png"],
		@"summary_call_incoming.png": [UIImage imageNamed:@"summary_call_incoming.png"],
		@"summary_call_missed.png": [UIImage imageNamed:@"summary_call_missed.png"],
		@"summary_call_outgoing.png": [UIImage imageNamed:@"summary_call_outgoing.png"],
	}];
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
		lastMessageID = [[_elements[i][@"item"] itemId] copy];
		ChatElement* item = [[ChatElement alloc] initWithData:[_elements objectAtIndex:i]];
		items.insert([NSIndexPath indexPathForRow:i inSection:0], item);
		added++;
	}
	if (added > 0)
	{
		_mainCount = [NSNumber numberWithInteger:[_mainCount integerValue] + added];
		__block NSInteger lastIndex = [_mainCount intValue] - 1;
		self.collectionView.hidden = YES;
		NSLog(@"%s: Start Enqueue", __PRETTY_FUNCTION__);
		[_dataSource enqueueChangeset:{{}, items} constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size] complete:^(BOOL i){
			NSLog(@"%s: Enqueue batch complete! Last item: %ld", __PRETTY_FUNCTION__, lastIndex);
			[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:lastIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
			self.collectionView.hidden = NO;
		}];
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

#pragma mark - RingMail

- (void)scrollToBottom:(BOOL)animate
{
	NSInteger last = [self.collectionView numberOfItemsInSection:0] - 1;
	if (last >= 0)
	{
		[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:last inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:animate];
	}
}

- (void)appendNewMessages
{
	BOOL foreground = [ChatElement showingMessageThread];
	NSArray* newMessages = [[RKCommunicator sharedInstance] listThreadItems:chatThread lastItemId:lastMessageID seen:foreground];
	//NSLog(@"%s: New Messages: %@", __PRETTY_FUNCTION__, newMessages);
	if ([newMessages count] == 0)
    {
		return;
    }
	
	// Generate the new changeset
	__block CKArrayControllerInputItems items;
	
	// remove last_element tag
	NSInteger count = [_elements count];
	
	NSInteger start = count;
	NSInteger j = start;
	for (RKItem* i in newMessages)
	{
		if (_elementPaths[i.itemId] == nil)
		{
    		[_elements addObject:[NSMutableDictionary dictionaryWithDictionary:@{
    			@"item": i,
    		}]];
    		_elementPaths[i.itemId] = [NSNumber numberWithInteger:j++];
		}
	}
	NSInteger newcount = [_elements count];
	if (newcount == count)
	{
		return;
	}
	else if (foreground)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kRKThreadSeen object:nil userInfo:@{
    		@"thread": chatThread,
    	}];
	}
	if (count > 0)
	{
		NSInteger last = count - 1;
		NSMutableDictionary *lastData = _elements[last];
		[lastData removeObjectForKey:@"last_element"];
		ChatElement* lastItem = [[ChatElement alloc] initWithData:lastData];
		items.update([NSIndexPath indexPathForRow:last inSection:0], lastItem);
	}
	
	NSInteger added = 0;
	for (NSUInteger i = start; i < newcount; i++)
    {
		if (i == 0)
		{
			_elements[i][@"first_element"] = @YES;
		}
		if (i == newcount - 1)
		{
			_elements[i][@"last_element"] = @YES;
		}
		lastMessageID = [[_elements[i][@"item"] itemId] copy];
		ChatElement* item = [[ChatElement alloc] initWithData:[_elements objectAtIndex:i]];
		items.insert([NSIndexPath indexPathForRow:i inSection:0], item);
		added++;
	}
	if (added > 0)
	{
		_mainCount = [NSNumber numberWithInteger:[_mainCount integerValue] + added];
    	dispatch_async(dispatch_get_main_queue(), ^{
    		[_dataSource enqueueChangeset:{{}, items} constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size] complete:^(BOOL i) {
				NSInteger last = [self.collectionView numberOfItemsInSection:0] - 1;
    			[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:last inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
   			}];
		});
	}
}

- (void)updateMessage:(RKItem*)msg;
{
	__block NSNumber* position = _elementPaths[msg.itemId];
	if (position != nil)
	{
		__block CKArrayControllerInputItems items;
		_elements[[position integerValue]][@"item"] = msg;
		ChatElement* item = [[ChatElement alloc] initWithData:_elements[[position integerValue]]];
		items.update([NSIndexPath indexPathForRow:[position integerValue] inSection:0], item);
		dispatch_async(dispatch_get_main_queue(), ^{
			NSInteger last = [self.collectionView numberOfItemsInSection:0] - 1;
			if ([position integerValue] <= last)
			{
				[_dataSource enqueueChangeset:{{}, items} constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size] complete:NULL];
			}
		});
	}
}

- (void)removeMessage:(RKItem*)msg;
{
	NSNumber* position = _elementPaths[msg.itemId];
	if (position != nil)
	{
		__block CKArrayControllerInputItems items;
		[_elements removeObjectAtIndex:[position integerValue]];
		[_elementPaths removeObjectForKey:position];
		for (NSInteger i = [position integerValue]; i < [_elements count]; i++)
		{
			_elementPaths[[(RKItem*)_elements[i] itemId]] = [NSNumber numberWithInteger:i];
		}
		
		items.remove([NSIndexPath indexPathForRow:[position integerValue] inSection:0]);
		
		_mainCount = [NSNumber numberWithInteger:[_mainCount integerValue] - 1];
		__block NSInteger lastIndex = [_mainCount intValue] - 1;
		
		if ([_elements count] > 0)
		{
    		if (_elements[0][@"first_element"] == nil)
    		{
    			_elements[0][@"first_element"] = @YES;
    			if (lastIndex != 0) // If only one element is left, update it below since it's both first and last.
    			{
        			ChatElement* item = [[ChatElement alloc] initWithData:_elements[0]];
        			items.update([NSIndexPath indexPathForRow:0 inSection:0], item);
    			}
    		}
    		if (_elements[lastIndex][@"last_element"] == nil)
    		{
    			_elements[lastIndex][@"last_element"] = @YES;
    			ChatElement* item = [[ChatElement alloc] initWithData:_elements[lastIndex]];
    			items.update([NSIndexPath indexPathForRow:lastIndex inSection:0], item);
    		}
		}
		dispatch_async(dispatch_get_main_queue(), ^{
    		[_dataSource enqueueChangeset:{{}, items} constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size] complete:^(BOOL i) {
				if (lastIndex >= 0)
				{
					[self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:lastIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
				}
			}];
		});
	}
}

/*
- (void)updateMessage
{
}
*/

@end
