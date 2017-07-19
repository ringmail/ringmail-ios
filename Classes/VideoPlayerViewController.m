//
//  TestVideoPlayerViewController.m
//  Memento
//
//  Created by Ömer Faruk Gül on 22/05/15.
//  Copyright (c) 2015 Ömer Faruk Gül. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import "PhoneMainView.h"

@implementation VideoPlayerViewController

- (instancetype)initWithVideoUrl:(NSURL *)url
{
	self = [super initWithNibName:@"VideoPlayerViewController" bundle:[NSBundle mainBundle]];
    if(self) {
        self->_videoUrl = url;
    }
    return self;
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"VideoPlayerView"
																content:@"VideoPlayerViewController"
															   stateBar:nil
														stateBarEnabled:false
                                                                 navBar:nil
																 tabBar:nil
                                                          navBarEnabled:false
														  tabBarEnabled:false
															 fullscreen:true
														  landscapeMode:false
														   portraitMode:true];
	}
	return compositeDescription;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];

    self.videoPlayerViewController = self.videoContainerView.videoPlayerViewController;
	self.videoPlayerViewController.delegate = self;
	self.videoPlayerViewController.videoURL = self.videoUrl;
	self.videoPlayerViewController.configuration.isShowFullscreenExpandAndShrinkButtonsEnabled = NO;
	
	[self.videoPlayerViewController prepareAndPlayAutomatically:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return self.videoPlayerViewController.isFullscreen;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - DZVideoPlayerViewControllerDelegate

- (void)playerFailedToLoadAssetWithError:(NSError *)error
{
}

- (void)playerDidPlay
{
}

- (void)playerDidPause
{
}

- (void)playerDidStop
{
}

- (void)playerDidToggleFullscreen {
    if (self.videoPlayerViewController.isFullscreen)
	{
        // expand videoPlayerViewController to fullscreen
        self.contentViewAspectRatioConstraint.priority = UILayoutPriorityDefaultLow;
        self.contentViewBottomSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
        [UIView animateWithDuration:0.5 animations:^{
            [self.contentView layoutIfNeeded];
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) { }];
    }
    else
	{
        // shrink videoPlayerViewController from fullscreen
        self.contentViewBottomSpaceConstraint.priority = UILayoutPriorityDefaultLow;
        self.contentViewAspectRatioConstraint.priority = UILayoutPriorityDefaultHigh;
        [UIView animateWithDuration:0.5 animations:^{
            [self.contentView layoutIfNeeded];
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) { }];
    }
}

- (void)playerDidPlayToEndTime
{
}

- (void)playerFailedToPlayToEndTime
{
}

- (void)playerPlaybackStalled
{
}

- (void)playerDoneButtonTouched
{
	[[PhoneMainView instance] popCurrentView];
}

- (void)playerGatherNowPlayingInfo:(NSMutableDictionary *)nowPlayingInfo
{
    //[nowPlayingInfo setObject:self.video.author forKey:MPMediaItemPropertyArtist];
    //[nowPlayingInfo setObject:kVideoFileName forKey:MPMediaItemPropertyTitle];
}

@end
