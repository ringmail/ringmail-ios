//
//  SendToInputComponent.m
//  ringmail
//
//  Created by Mike Frager on 3/1/17.
//
//

#import <ComponentKit/CKComponentScope.h>
#import "SendToInputComponent.h"
#import "RgManager.h"

@interface SendToInputComponent ()

@property (nonatomic, strong) NSNumber* tag;
@property (nonatomic, weak) SendToInputView* sendToView;

@end

@implementation SendToInputComponent

+ (instancetype)newWithTag:(NSNumber*)inputTag size:(const CKComponentSize &)size
{
	CKComponentScope scope(self);
	SendToInputComponent *c = [super newWithSize:size accessibility:{}];
	if (c)
	{
		c->_tag = inputTag;
		c->_sendToView = nil;
	}
	return c;
}

@end

@implementation SendToInputComponentController

+ (SendToInputView *)newStatefulView:(id)context
{
	SendToInputView* tv = [[SendToInputView alloc] init];
	return tv;
}

+ (void)configureStatefulView:(SendToInputView *)statefulView forComponent:(SendToInputComponent *)component
{
	statefulView.backgroundColor = [UIColor clearColor];
	statefulView.font = [UIFont systemFontOfSize:18];
	statefulView.minimumFontSize = 14.0f;
	[statefulView setAdjustsFontSizeToFitWidth:YES];
	[statefulView setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[statefulView setAutocorrectionType:UITextAutocorrectionTypeNo];
	[statefulView setKeyboardType:UIKeyboardTypeEmailAddress];
	[statefulView setTag:[component.tag integerValue]];
	component.sendToView = statefulView;
}

- (void)didMount
{
	[super didMount];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetText:) name:kRgSendComponentReset object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTo:) name:kRgSendComponentUpdateTo object:nil];
}

- (void)didUnmount
{
	[super didUnmount];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSendComponentReset object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSendComponentUpdateTo object:nil];
}

- (void)resetText:(NSNotification*)notif
{
	SendToInputComponent* cp = (SendToInputComponent*)self.component;
	SendToInputView* tv = cp.sendToView;
	[tv setText:@""];
}

- (void)updateTo:(NSNotification*)notif
{
	SendToInputComponent* cp = (SendToInputComponent*)self.component;
	SendToInputView* tv = cp.sendToView;
	[tv setText:notif.userInfo[@"to"]];
}

@end

@implementation SendToInputView

@end
