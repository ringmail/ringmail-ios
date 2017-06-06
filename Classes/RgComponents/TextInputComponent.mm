//
//  TextInputComponent.m
//  ringmail
//
//  Created by Mike Frager on 3/1/17.
//
//

#import <ComponentKit/CKComponentScope.h>
#import "TextInputComponent.h"
#import "RgManager.h"

@interface TextInputComponent ()

@property (nonatomic, strong) NSNumber* tag;
@property (nonatomic, weak) TextInputView* textInputView;

@end

@implementation TextInputComponent

+ (instancetype)newWithTag:(NSNumber*)inputTag size:(const CKComponentSize &)size
{
	CKComponentScope scope(self);
	TextInputComponent *c = [super newWithSize:size accessibility:{}];
	if (c)
	{
		c->_tag = inputTag;
		c->_textInputView = nil;
	}
	return c;
}
@end

@implementation TextInputComponentController

+ (TextInputView *)newStatefulView:(id)context
{
	TextInputView* tv = [[TextInputView alloc] init];
	return tv;
}

+ (void)configureStatefulView:(TextInputView *)statefulView forComponent:(TextInputComponent *)component
{
	statefulView.backgroundColor = [UIColor clearColor];
	statefulView.font = [UIFont systemFontOfSize:18];
	statefulView.textContainerInset = UIEdgeInsetsZero;
	[statefulView setTag:[component.tag integerValue]];
	component.textInputView = statefulView;
}

- (void)didMount {
	[super didMount];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetText:) name:kRgSendComponentReset object:nil];
}

- (void)didUnmount {
	[super didUnmount];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSendComponentReset object:nil];
}

- (void)resetText:(NSNotification*)notif
{
	TextInputComponent* cp = (TextInputComponent*)self.component;
	TextInputView* tv = cp.textInputView;
	[tv setText:@""];
}

@end

@implementation TextInputView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
    UITouch *touch = [[event allTouches] anyObject];
    if ([self isFirstResponder] && [touch view] != self) {
        [self endEditing:YES];
    }
    [super touchesBegan:touches withEvent:event];
}

@end
