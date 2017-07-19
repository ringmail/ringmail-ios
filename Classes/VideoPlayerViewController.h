//
//  TestVideoPlayerViewController.h
//  Memento
//
//  Created by Ömer Faruk Gül on 22/05/15.
//  Copyright (c) 2015 Ömer Faruk Gül. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UICompositeViewController.h"
#import <DZVideoPlayerViewController/DZVideoPlayerViewController.h>

@interface VideoPlayerViewController : UIViewController<UICompositeViewDelegate, DZVideoPlayerViewControllerDelegate>

@property (strong, nonatomic) NSURL *videoUrl;
@property (strong, nonatomic) DZVideoPlayerViewController *videoPlayerViewController;
@property (strong, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewAspectRatioConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *contentViewBottomSpaceConstraint;
@property (strong, nonatomic) IBOutlet DZVideoPlayerViewControllerContainerView *videoContainerView;

- (instancetype)initWithVideoUrl:(NSURL *)url;

@end
