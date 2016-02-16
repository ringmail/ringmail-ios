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
#import "MainCardComponent.h"

@implementation CardComponent

+ (instancetype)newWithCard:(Card *)card context:(CardContext *)context
{
  return [super newWithComponent:cardComponent(card, context)];
}

static CKComponent *cardComponent(Card *card, CardContext *context)
{
  return [MainCardComponent
          newWithText:card.text
          context:context];
}

@end
