#import "SendComponentController.h"
#import "SendComponent.h"
#import "Send.h"

@implementation SendComponentController

- (void)showMomentCamera:(CKButtonComponent *)sender
{
	Send *obj = [[Send alloc] initWithData:@{}];
	[obj showMomentCamera];
}

@end

