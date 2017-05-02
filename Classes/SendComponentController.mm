#import "SendComponentController.h"
#import "SendComponent.h"
#import "Send.h"
#import "RgManager.h"

@implementation SendComponentController

- (void)showPhotoCamera:(CKButtonComponent *)sender
{
	Send *obj = [[Send alloc] initWithData:@{}];
	[obj showPhotoCamera];
}

- (void)showVideoCamera:(CKButtonComponent *)sender
{
	Send *obj = [[Send alloc] initWithData:@{}];
	[obj showVideoCamera];
}

- (void)showMomentCamera:(CKButtonComponent *)sender
{
	Send *obj = [[Send alloc] initWithData:@{}];
	[obj showMomentCamera];
}

@end

