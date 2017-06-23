//
//  MessageViewController.h
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import "UICompositeViewController.h"
#import "RgTextViewController.h"
#import "RingKit.h"

@interface MessageViewController : RgTextViewController <UICompositeViewDelegate>

- (instancetype)initWithThread:(RKThread*)thread;

@end
