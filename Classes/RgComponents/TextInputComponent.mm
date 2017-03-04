//
//  TextInputComponent.m
//  ringmail
//
//  Created by Mike Frager on 3/1/17.
//
//

#import <ComponentKit/CKComponentScope.h>
#import "TextInputComponent.h"

@interface TextInputComponent ()

@property (nonatomic, strong) NSNumber* tag;

@end

@implementation TextInputComponent

+ (instancetype)newWithTag:(NSNumber*)inputTag size:(const CKComponentSize &)size
{
	CKComponentScope scope(self);
	TextInputComponent *c = [super newWithSize:size accessibility:{}];
	if (c)
	{
		c->_tag = inputTag;
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
	statefulView.font = [UIFont systemFontOfSize:16];
	statefulView.textContainerInset = UIEdgeInsetsZero;
	[statefulView setTag:[component.tag integerValue]];
}

@end

@implementation TextInputView
@end
