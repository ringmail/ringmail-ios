//
//  TextInputComponent.h
//  ringmail
//
//  Created by Mike Frager on 3/1/17.
//
//

#import <ComponentKit/CKStatefulViewComponent.h>
#import <ComponentKit/CKStatefulViewComponentController.h>

@interface TextInputComponent : CKStatefulViewComponent
+ (instancetype)newWithTag:(NSNumber*)tag size:(const CKComponentSize &)size;
@end

@interface TextInputView : UITextView;
@end

@interface TextInputComponentController : CKStatefulViewComponentController

- (void)didMount;
- (void)didUnmount;
- (void)resetText:(NSNotification*)notif;

@end
