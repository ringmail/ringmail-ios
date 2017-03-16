/* RgFavoriteViewController.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "RgScanViewController.h"
#import "RgFavoriteViewController.h"
#import "DTAlertView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "UIColor+Hex.h"

#include "linphone/linphonecore.h"

#import "RgSearchBarViewController.h"

@interface RgFavoriteViewController()
@property BOOL isSearchBarVisible;
@property (strong, nonatomic) RgSearchBarViewController *searchBarViewController;
@end

@implementation RgFavoriteViewController

@synthesize mainView;
@synthesize mainViewController;
@synthesize backgroundImageView2;
@synthesize needsRefresh;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"RgFavoriteViewController" bundle:[NSBundle mainBundle]];
	return self;
}

- (void)dealloc {

	// Remove all observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Recent Activity"
																content:@"RgFavoriteViewController"
															   stateBar:@"UIStateBar"
														stateBarEnabled:true
                                                                 navBar:@"UINavBar"
																 tabBar:@"UIMainBar"
                                                          navBarEnabled:true
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true
                                                                segLeft:@"All"
                                                               segRight:@"Missed"];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSegControl)
                                                 name:@"RgSegmentControl"
                                               object:nil];
	
    if ([self needsRefresh])
    {
        [mainViewController updateCollection];
        [self setNeedsRefresh:NO];
    }
    
    self.visible = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
    self.visible = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RgSegmentControl" object:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
    int width = [UIScreen mainScreen].applicationFrame.size.width;
    if (width == 320) {
		[backgroundImageView setImage:[UIImage imageNamed:@"explore_background_ip5p@2x.png"]];
    }
    else if (width == 375) {
		[backgroundImageView setImage:[UIImage imageNamed:@"explore_background_ip6-7s@2x.png"]];
    }
    else if (width == 414) {
		[backgroundImageView setImage:[UIImage imageNamed:@"explore_background_ip6-7p@3x.png"]];
    }
    
    self.searchBarViewController = [[RgSearchBarViewController alloc] initWithPlaceHolder:@""];
    self.searchBarViewController.view.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 50);
    self.isSearchBarVisible = YES;
    [self addChildViewController:self.searchBarViewController];
    [self.view addSubview:self.searchBarViewController.view];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:0];
    
    MainCollectionViewController *mainController = [[MainCollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
    
    [[mainController collectionView] setBounces:YES];
    [[mainController collectionView] setAlwaysBounceVertical:YES];
    
    CGRect r = mainView.frame;
    r.origin.y = 0;
    [mainController.view setFrame:r];
    [mainView addSubview:mainController.view];
    [self addChildViewController:mainController];
    [mainController didMoveToParentViewController:self];
    mainViewController = mainController;
    [self setNeedsRefresh:NO];
    
    UITapGestureRecognizer* tapBackground = [[UITapGestureRecognizer alloc] initWithTarget:self.searchBarViewController action:@selector(dismissKeyboard:)];
    [tapBackground setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapBackground];
    
	// Set observer
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshEvent:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshEvent:)
                                                 name:kRgTextReceived
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshEvent:)
                                                 name:kRgTextUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshEvent:)
                                                 name:kRgMainRefresh
                                               object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshEvent:)
                                                 name:kRgFavoriteRefresh
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshEvent:)
                                                 name:kRgContactRefresh
                                               object:nil];
    
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgTextReceived object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgTextUpdate object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgMainRefresh object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgFavoriteRefresh object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kRgContactRefresh object:nil];
}

#pragma mark - Event Functions

- (void)refreshEvent:(NSNotification *)notif {
    if (self.visible)
    {
        [mainViewController updateCollection];
    }
    else
    {
        [self setNeedsRefresh:YES];
    }
}

- (void)handleSegControl {
    printf("recents segement controller hit\n");
}

#pragma mark -

@end
