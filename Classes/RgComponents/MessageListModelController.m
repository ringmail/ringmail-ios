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

#import "MessageThreadModelController.h"

#import <UIKit/UIColor.h>

#import "MessageThread.h"
#import "MessageThreadPage.h"
#import "LinphoneManager.h"
#import "RingKit.h"

@implementation MessageThreadModelController
{
  NSInteger _numberOfObjects;
}

@synthesize mainList;
@synthesize mainCount;

- (instancetype)init
{
    if (self = [super init]) {
        mainList = [[RKCommunicator sharedInstance] listThreads];
        mainCount = [NSNumber numberWithInteger:0]; // Counter as items are added to the UI
    }
    return self;
}

- (NSArray *)readMainList
{
    NSArray* list = [[[LinphoneManager instance] chatManager] dbGetMainList];
    return [self buildMessageThreads:list];
}

- (NSArray *)buildMessageThreads:(NSArray*)list
{
	//NSLog(@"MessageThread Data: %@", list);
    NSMutableArray *list2 = [NSMutableArray array];
    int item = 0;
	UIImage *defaultImage = [UIImage imageNamed:@"avatar_unknown_small.png"];
    for (NSDictionary* r in list)
    {
        NSString *address = [r objectForKey:@"session_tag"];
        
        NSMutableDictionary *newdata = [NSMutableDictionary dictionaryWithDictionary:r];
		
		// Index
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
        }
		else
		{
    		// Avatar image
			NSNumber *contactId = r[@"contact_id"];
			ABRecordRef contact = NULL;
			if (NILIFNULL(contactId) != nil)
			{
                // Contact ID was supplied by the server
				contact = [[[LinphoneManager instance] fastAddressBook] getContactById:contactId];
        		if (contact)
        		{
        			UIImage *customImage = [FastAddressBook getContactImage:contact thumbnail:true];
                    [newdata setObject:[FastAddressBook getContactDisplayName:contact] forKey:@"label"];
                    [newdata setObject:((customImage != nil) ? customImage : defaultImage) forKey:@"image"];
        		}
			}
            else
            {
                // Contact ID lookup attemp
				contact = [[[LinphoneManager instance] fastAddressBook] getContact:r[@"session_tag"]];
        		if (contact)
        		{
                    LOGI(@"RingMail: Matched contact");
        			UIImage *customImage = [FastAddressBook getContactImage:contact thumbnail:true];
                    [newdata setObject:[FastAddressBook getContactDisplayName:contact] forKey:@"label"];
                    [newdata setObject:((customImage != nil) ? customImage : defaultImage) forKey:@"image"];
        		}
            }
    		if (! contact)
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
        LOGI(@"RingMail: List Object: %@", newdata);
        [list2 addObject:newdata];
    }
    return list2;
}

- (MessageThreadPage *)fetchNewPageWithCount:(NSInteger)count
{
    NSAssert(count >= 1, @"Count should be a positive integer");
    NSMutableArray *cards = [NSMutableArray new];
    NSInteger added = 0;
    for (NSUInteger i = 0; i < count; i++)
    {
        NSInteger mainIndex = [mainCount integerValue] + i;
        if ([mainList count] > mainIndex)
        {
            MessageThread *card = [[MessageThread alloc] initWithData:mainList[mainIndex]];
            [cards addObject:card];
            added++;
        }
    }
    MessageThreadPage *page = [[MessageThreadPage alloc] initWithMessageThreads:cards position:[mainCount integerValue]];
    mainCount = [NSNumber numberWithInteger:[mainCount integerValue] + added];
    return page;
}

@end
