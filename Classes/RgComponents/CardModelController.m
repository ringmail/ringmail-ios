/* This file provided by Facebook is for non-commercial testing and evaluation
 * purposes only.  Facebook reserves all rights not expressly granted.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "CardModelController.h"

#import <UIKit/UIColor.h>

#import "Card.h"
#import "CardsPage.h"
#import "LinphoneManager.h"

@implementation CardModelController
{
  NSInteger _numberOfObjects;
}

@synthesize mainList;
@synthesize mainCount;
@synthesize header;

- (instancetype)init
{
    if (self = [super init]) {
        mainCount = [NSNumber numberWithInteger:0];
        mainList = nil;
		header = nil;
    }
    return self;
}

- (NSArray *)readMainList
{
    NSArray* list = [[[LinphoneManager instance] chatManager] dbGetMainList];
    return [self buildCards:list];
}

- (NSArray *)buildCards:(NSArray*)list
{
    NSMutableArray *list2 = [NSMutableArray array];
    int item = 0;
	UIImage *defaultImage = [UIImage imageNamed:@"avatar_unknown_small.png"];
    for (NSDictionary* r in list)
    {
        NSString *address = [r objectForKey:@"session_tag"];

        NSMutableDictionary *newdata = [NSMutableDictionary dictionaryWithDictionary:r];
		
		// Index
        [newdata setObject:[NSNumber numberWithInt:item++] forKey:@"index"];
		
		if ([[address substringToIndex:1] isEqualToString:@"#"])
		{
            [newdata setObject:@"hashtag" forKey:@"type"];
            [newdata setObject:address forKey:@"label"];
            [newdata setObject:defaultImage forKey:@"image"];
		}
		else
		{
    		// Avatar image
    		ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
    		if (contact)
    		{
    			UIImage *customImage = [FastAddressBook getContactImage:contact thumbnail:true];
                [newdata setObject:[FastAddressBook getContactDisplayName:contact] forKey:@"label"];
                [newdata setObject:((customImage != nil) ? customImage : defaultImage) forKey:@"image"];
    		}
    		else
    		{
                [newdata setObject:address forKey:@"label"];
                [newdata setObject:defaultImage forKey:@"image"];
    		}
    		
    		// Timestamp & Last Event
    		BOOL last_was_chat = YES;
    		NSNumber *timeCall = [r objectForKey:@"call_time"];
    		NSNumber *timeChat = [r objectForKey:@"last_time"];
    		NSNumber *timeLatest = [NSNumber numberWithInt:0];
    		if (timeCall != nil && ! [timeCall isEqual:[NSNull null]])
    		{
    			if (timeChat != nil && ! [timeChat isEqual:[NSNull null]])
    			{
    				if ([timeChat intValue] > [timeCall intValue])
    				{
    					timeLatest = timeChat;
    				}
    				else
    				{
    					last_was_chat = NO;
    					timeLatest = timeCall;
    				}
    			}
    			else
    			{
    				last_was_chat = NO;
    				timeLatest = timeCall;
    			}
    		}
    		else if (timeChat != nil && ! [timeChat isEqual:[NSNull null]])
    		{
    			timeLatest = timeChat;
    		}
    		[newdata setObject:[NSDate dateWithTimeIntervalSince1970:[timeLatest doubleValue]] forKey:@"timestamp"];
    		NSString *lastEvent = (last_was_chat) ? @"chat" : @"call";
    		[newdata setObject:lastEvent forKey:@"last_event"];
    		if (! last_was_chat)
    		{
    			if ([[r objectForKey:@"call_status"] isEqualToString:@"success"])
    			{
    				int duration = [[r objectForKey:@"call_duration"] intValue];
    				NSString *dur = [NSString stringWithFormat:@"%02i:%02i:%02i", (duration / 3600), ((duration / 60) % 60), (duration % 60)];
    				dur = [dur stringByReplacingOccurrencesOfRegex:@"^00:" withString:@""];
    				[newdata setObject:dur forKey:@"call_duration"];
    			}
    		}
		}
        [list2 addObject:newdata];
    }
    return list2;
}

- (CardsPage *)fetchNewCardsPageWithCount:(NSInteger)count
{
    NSAssert(count >= 1, @"Count should be a positive integer");
    if (mainList == nil)
    {
        mainList = [self readMainList];
    }
    NSMutableArray *_cards = [NSMutableArray new];
    NSInteger added = 0;
    for (NSUInteger i = 0; i < count; i++)
    {
        if (header && [mainCount intValue] == 0 && i == 0)
        {
            NSNumber *headerCell = [NSNumber numberWithBool:1];
            Card *card = [[Card alloc] initWithData:@{@"text": header}
                                             header:headerCell];
            [_cards addObject:card];
            added++;
        }
        else
        {
            NSInteger mainIndex = [mainCount intValue] + i - ((header) ? 1 : 0);
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
