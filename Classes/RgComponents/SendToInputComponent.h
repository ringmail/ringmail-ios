//
//  SendToInputComponent.h
//  ringmail
//
//  Created by Mike Frager on 3/1/17.
//
//

#import <ComponentKit/CKStatefulViewComponent.h>
#import <ComponentKit/CKStatefulViewComponentController.h>

@interface SendToInputComponent : CKStatefulViewComponent
+ (instancetype)newWithText:(NSString*)text tag:(NSNumber*)inputTag size:(const CKComponentSize &)size;
@end

@interface SendToInputView : UITextField;
@end

@interface SendToInputComponentController : CKStatefulViewComponentController

- (void)didMount;
- (void)didUnmount;
- (void)resetText:(NSNotification*)notif;

@end
