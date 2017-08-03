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

#import "MessageThreadContext.h"
#import "LinphoneManager.h"

@implementation MessageThreadContext
{
  NSMutableDictionary *_images;
}

- (instancetype)initWithImages:(NSMutableDictionary *)addImages
{
  if (self = [super init]) {
      _images = addImages;
      self.imageDownloader = [IAWCKImageDownloader sharedManager];
  }
  return self;
}

- (instancetype)initWithImageNames:(NSSet *)imageNames
{
  if (self = [super init]) {
       _images = loadImageNames(imageNames);
      self.imageDownloader = [IAWCKImageDownloader sharedManager];
  }
  return self;
}

- (UIImage *)imageNamed:(NSString *)imageName
{
    return _images[imageName];
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

@end
