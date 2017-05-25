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

#import "CardComponent.h"

#import "Card.h"
#import "CardContext.h"
#import "HashtagCardComponent.h"
#import "HashtagCategoryCardComponent.h"
#import "HashtagCategoryHeaderComponent.h"
#import "HashtagCategoryGroupCardComponent.h"
#import "HashtagDirectoryHeaderCardComponent.h"

@implementation CardComponent

+ (instancetype)newWithCard:(Card *)card context:(CardContext *)context
{
   return [super newWithComponent:cardComponent(card, context)];
}

static CKComponent *cardComponent(Card *card, CardContext *context)
{
    // Build different types of cards
    NSString* type = [card.data objectForKey:@"type"];
    if (type != nil)
    {
        if ([type isEqualToString:@"hashtag"])
        {
            return [HashtagCardComponent
                      newWithData:card.data
                      context:context];
        }
        else if ([type isEqualToString:@"hashtag_category"])
        {
            return [HashtagCategoryCardComponent
                      newWithData:card.data
                      context:context];
        }
		else if ([type isEqualToString:@"hashtag_category_group"])
        {
			NSArray *cats = [card.data objectForKey:@"group"];
			NSMutableArray *comps = [NSMutableArray array];
			for (NSDictionary* itemdata in cats)
			{
				[comps addObject:[HashtagCategoryCardComponent
                      newWithData:itemdata
                      context:context]];
			}
            return [HashtagCategoryGroupCardComponent newWithData:@{ @"group": comps } context:context];
        }
		else if ([type isEqualToString:@"hashtag_category_header"])
        {
            return [HashtagCategoryHeaderComponent
                      newWithData:card.data
                      context:context];
        }
        else if ([type isEqualToString:@"hashtag_directory_header"])
        {
            return [HashtagDirectoryHeaderCardComponent
                      newWithData:card.data
                      context:context];
        }
    }
	return nil;
}

@end
