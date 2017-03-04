//
//  SendToInputComponent.m
//  ringmail
//
//  Created by Mike Frager on 3/1/17.
//
//

#import <ComponentKit/CKComponentScope.h>
#import "SendToInputComponent.h"

@interface SendToInputComponent ()

@property (nonatomic, strong) NSNumber* tag;

@end

@implementation SendToInputComponent

+ (instancetype)newWithTag:(NSNumber*)inputTag size:(const CKComponentSize &)size
{
	CKComponentScope scope(self);
	SendToInputComponent *c = [super newWithSize:size accessibility:{}];
	if (c)
	{
		c->_tag = inputTag;
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
	statefulView.font = [UIFont systemFontOfSize:16];
	[statefulView setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[statefulView setAutocorrectionType:UITextAutocorrectionTypeNo];
	[statefulView setKeyboardType:UIKeyboardTypeEmailAddress];
	[statefulView setTag:[component.tag integerValue]];
}

@end

@implementation SendToInputView
@end
