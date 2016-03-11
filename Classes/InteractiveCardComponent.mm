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

#import "InteractiveCardComponent.h"

#import <ComponentKit/CKComponentSubclass.h>

#import "Card.h"
#import "CardContext.h"
#import "CardComponent.h"
#import "HeaderComponent.h"

static NSString *const oscarWilde = @"Oscar Wilde";

@implementation InteractiveCardComponent
{
  CKComponent *_overlay;
}

+ (instancetype)newWithCard:(Card *)card
                     context:(CardContext *)context
{
    CKComponentScope scope(self);
    //const BOOL revealAnswer = [scope.state() boolValue];
    
    if ([card.header boolValue])
    {
        InteractiveCardComponent *c = [super newWithComponent:[HeaderComponent newWithHeader:[card.data objectForKey:@"text"] context:context]];
        return c;
    }
    
    InteractiveCardComponent *c = [super newWithComponent:[CardComponent newWithCard:card context:context]];
    return c;
}

+ (id)initialState
{
  return @NO;
}

- (std::vector<CKComponentAnimation>)animationsFromPreviousComponent:(InteractiveCardComponent *)previousComponent
{
  if (previousComponent->_overlay == nil && _overlay != nil) {
    return {{_overlay, scaleToAppear()}}; // Scale the overlay in when it appears.
  } else {
    return {};
  }
}

static CAAnimation *scaleToAppear()
{
  CABasicAnimation *scale = [CABasicAnimation animationWithKeyPath:@"transform"];
  scale.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.0, 0.0, 0.0)];
  scale.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
  scale.duration = 0.2;
  return scale;
}

@end
