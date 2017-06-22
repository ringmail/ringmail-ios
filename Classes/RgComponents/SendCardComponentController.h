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

#import <ComponentKit/ComponentKit.h>

@interface SendCardComponentController : CKComponentController

@property NSMutableDictionary *state;

- (void)didMount;
- (void)didUnmount;
- (void)textFieldDidChange:(NSNotification *)notif;
- (void)actionSend:(CKButtonComponent *)sender;
- (void)actionMediaTap:(CKButtonComponent *)sender;
- (void)actionMediaRemove:(CKButtonComponent *)sender;

- (void)actionAddContact:(CKButtonComponent *)sender;

- (void)updateToState:(NSNotification *)notif;

@end

