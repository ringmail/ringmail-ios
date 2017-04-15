//
//  MessageTextView.m
//  Messenger
//
//  Created by Ignacio Romero Z. on 1/20/15.
//  Copyright (c) 2015 Slack Technologies, Inc. All rights reserved.
//

#import "MessageTextView.h"
#import "UIColor+Hex.h"

@implementation MessageTextView

- (instancetype)init
{
    if (self = [super init]) {
        // Do something
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    self.backgroundColor = [UIColor whiteColor];
    
    self.placeholder = NSLocalizedString(@"Message", nil);
    self.placeholderColor = [UIColor lightGrayColor];
    self.pastableMediaTypes = SLKPastableMediaTypeAll;
}

@end
