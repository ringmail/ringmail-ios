//
//  MessageListViewController.mm
//  ringmail
//
//  Created by Mike Frager on 2/14/16.
//
//

#import <Foundation/Foundation.h>
#import <ComponentKit/ComponentKit.h>
#import "UIColor+Hex.h"
#import "RingKit.h"
#import "MessageListViewController.h"
#import "MessageListModelController.h"
#import "MessageThreadContext.h"
#import "MessageThread.h"
#import "MessageThreadPage.h"
#import "MessageThreadComponent.h"

@interface MessageListViewController () <CKComponentProvider, UICollectionViewDelegateFlowLayout>
@end

@implementation MessageListViewController
{
    CKCollectionViewDataSource *_dataSource;
    MessageListModelController *_cardModelController;
    CKComponentFlexibleSizeRangeProvider *_sizeRangeProvider;
}

static NSInteger const pageSize = 10;

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
    if (self = [super initWithCollectionViewLayout:layout])
	{
        _sizeRangeProvider = [CKComponentFlexibleSizeRangeProvider providerWithFlexibility:CKComponentSizeRangeFlexibleHeight];
        _cardModelController = [[MessageListModelController alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Preload images for the component context that need to be used in component preparation. Components preparation
    // happens on background threads but +[UIImage imageNamed:] is not thread safe and needs to be called on the main
    // thread. The preloaded images are then cached on the component context for use inside components.
	
	// TODO: use the correct images!
    NSDictionary *images = @{
		@"ringmail_action_call_normal.png": [UIImage imageNamed:@"ringmail_action_call_normal.png"],
		@"ringmail_action_video_normal.png": [UIImage imageNamed:@"ringmail_action_video_normal.png"],
		@"ringmail_action_text_normal.png": [UIImage imageNamed:@"ringmail_action_text_normal.png"],
		@"ringmail_triangle_green.png": [UIImage imageNamed:@"ringmail_triangle_green.png"],
		@"ringmail_triangle_grey.png": [UIImage imageNamed:@"ringmail_triangle_grey.png"],
		@"message_summary_moment_normal.png": [UIImage imageNamed:@"message_summary_moment_normal.png"],
		@"message_summary_photo_normal.png": [UIImage imageNamed:@"message_summary_photo_normal.png"],
		@"message_summary_video_normal.png": [UIImage imageNamed:@"message_summary_video_normal.png"],
		@"avatar_unknown_small.png": [UIImage imageNamed:@"avatar_unknown_small.png"],
	};
    MessageThreadContext *context = [[MessageThreadContext alloc] initWithImages:images];
    
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.delegate = self;
    
    _dataSource = [[CKCollectionViewDataSource alloc] initWithCollectionView:self.collectionView
                                                 supplementaryViewDataSource:nil
                                                           componentProvider:[self class]
                                                                     context:context
                                                   cellConfigurationFunction:nil];
    // Insert the initial section
    CKArrayControllerSections sections;
    sections.insert(0);
    [_dataSource enqueueChangeset:{sections, {}} constrainedSize:{}];
    [self _enqueuePage:[_cardModelController fetchNewPageWithCount:pageSize]];
}

- (void)_enqueuePage:(MessageThreadPage *)cardsPage
{
    NSArray *cards = cardsPage.threads;
    NSInteger position = cardsPage.position;
    
    // Convert the array of cards to a valid changeset
    BOOL hasitems = NO;
    CKArrayControllerInputItems items;
    for (NSInteger i = 0; i < [cards count]; i++)
	{
        items.insert([NSIndexPath indexPathForRow:position + i inSection:0], cards[i]);
        hasitems = YES;
    }
    if (hasitems)
    {
        [_dataSource enqueueChangeset:{{}, items} constrainedSize:[_sizeRangeProvider sizeRangeForBoundingSize:self.collectionView.bounds.size]];
    }
}

#pragma mark - Update collection

- (void)updateCollection
{
    NSArray *current = [_cardModelController mainList];
    NSArray *newlist = [[RKCommunicator sharedInstance] listThreads];
	
    NSInteger curcount = [current count];
    NSInteger newcount = [newlist count];
	
    // Generate changeset
    NSInteger viewcount = [[_cardModelController mainCount] integerValue];
    if (viewcount < pageSize)
    {
        viewcount = pageSize;
    }
    __block CKArrayControllerInputItems items;
    for (NSInteger i = 0; i < viewcount; i++)
    {
        NSInteger j = i;
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
            NSNumber* curId = current[j][@"item_id"];
            NSNumber* newId = newlist[j][@"item_id"];
            if (! [curId isEqualToNumber:newId]) // item changed
            {
                MessageThread *card = [[MessageThread alloc] initWithData:newlist[j]];
                items.update([NSIndexPath indexPathForRow:i inSection:0], card);
            }
            else
            {
                NSNumber* curVer = current[j][@"version"];
                NSNumber* newVer = newlist[j][@"version"];
				
                if (! [curVer isEqualToNumber:newVer])
                {
                    // Regenerate card
                    MessageThread *card = [[MessageThread alloc] initWithData:newlist[j]];
                    items.update([NSIndexPath indexPathForRow:i inSection:0], card);
                }
				// TODO: compare thread image & displayName
                /*else if (! [current[j][@"label"] isEqualToString:newlist[j][@"label"]])
                {
                    MessageThread *card = [[MessageThread alloc] initWithData:newlist[j]];
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
                            MessageThread *card = [[MessageThread alloc] initWithData:newlist[j] header:[NSNumber numberWithBool:0]];
                            items.update([NSIndexPath indexPathForRow:i inSection:0], card);
                        }
                    }
                }*/
            }
        }
        else if (hasnew)
        {
            MessageThread *card = [[MessageThread alloc] initWithData:newlist[j]];
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

- (void)removeMessageThread:(NSNumber*)index
{
	// Obsolete
    __block CKArrayControllerInputItems items;
    items.remove([NSIndexPath indexPathForRow:[index intValue] inSection:0]);
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

+ (CKComponent *)componentForModel:(MessageThread *)thr context:(MessageThreadContext *)context
{
    return [MessageThreadComponent newWithMessageThread:thr context:context];
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
        [self _enqueuePage:[_cardModelController fetchNewPageWithCount:pageSize]];
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
