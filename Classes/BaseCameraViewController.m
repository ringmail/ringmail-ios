#import "BaseCameraViewController.h"
#import "ViewUtils.h"
#import "Utils.h"
#import "PhoneMainView.h"

@implementation BaseCameraViewController

/*-(NSString*)writeImage:(UIImage*)img
{
	NSString* imageUUID = [[NSUUID UUID] UUIDString];
	NSString* tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", imageUUID]];
	[UIImagePNGRepresentation(img) writeToFile:tmpfile atomically:YES];
	return tmpfile;
}*/

@end
