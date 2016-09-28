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

@implementation RgFavoriteViewController

@synthesize mainView;
@synthesize mainViewController;
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
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Favorites"
																content:@"RgFavoriteViewController"
															   stateBar:@"UIStateBar"
														stateBarEnabled:true
																 tabBar:@"UIMainBar"
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	
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
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:0];
    
    FavoriteCollectionViewController *mainController = [[FavoriteCollectionViewController alloc] initWithCollectionViewLayout:flowLayout];
    
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

#pragma mark -

@end
