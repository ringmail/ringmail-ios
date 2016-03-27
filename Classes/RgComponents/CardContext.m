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

#import "CardContext.h"
#import "LinphoneManager.h"
#import "FastAddressBook.h"
#import <AddressBook/AddressBook.h>

@implementation CardContext
{
  NSMutableDictionary *_images;
}

- (instancetype)initWithImages:(NSMutableDictionary *)addImages
{
  if (self = [super init]) {
      _images = addImages;
  }
  return self;
}

- (instancetype)initWithImageNames:(NSSet *)imageNames
{
  if (self = [super init]) {
       _images = loadImageNames(imageNames);
  }
  return self;
}

- (UIImage *)imageNamed:(NSString *)imageName
{
    UIImage* img = _images[imageName];
    if (img != nil)
    {
        return _images[imageName];
    }
    else
    {
        img = [self getContactImage:imageName];
        [_images setObject:img forKey:imageName];
        return img;
    }
}

static NSMutableDictionary *loadImageNames(NSSet *imageNames)
{
  NSMutableDictionary *imageDictionary = [[NSMutableDictionary alloc] init];
  for (NSString *imageName in imageNames) {
    UIImage *image = [UIImage imageNamed:imageName];
    if (image) {
      imageDictionary[imageName] = image;
    }
  }
  return imageDictionary;
}


- (UIImage*)getContactImage:(NSString*)name
{
    UIImage *image = nil;
    ABRecordRef acontact = [[[LinphoneManager instance] fastAddressBook] getContact:name];
    if (acontact != nil) {
        image = [FastAddressBook getContactImage:acontact thumbnail:true];
    }
    if (image == nil) {
        image = [UIImage imageNamed:@"avatar_unknown_small.png"];
    }
    return image;
}


@end
