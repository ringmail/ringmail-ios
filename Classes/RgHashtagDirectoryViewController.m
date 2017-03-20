/* RgHashtagDirectoryViewController.h
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
#import "RgHashtagDirectoryViewController.h"
#import "HashtagModelController.h"
#import "DTAlertView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "UIColor+Hex.h"

#include "linphone/linphonecore.h"

#import "RgLocationManager.h"
#import "RgSearchBarViewController.h"

@interface RgHashtagDirectoryViewController()
@property BOOL isSearchBarVisible;
@property (strong, nonatomic) RgSearchBarViewController *searchBarViewController;
@end

@implementation RgHashtagDirectoryViewController

@synthesize mainView;
@synthesize mainViewController;
@synthesize path;
@synthesize waitView;
@synthesize needsRefresh;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"RgHashtagDirectoryViewController" bundle:[NSBundle mainBundle]];
	if (self) {
        path = @"0";
	}
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
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Explore"
																content:@"RgHashtagDirectoryViewController"
															   stateBar:@"UIStateBar"
														stateBarEnabled:true
                                                                 navBar:@"UINavBar"
																 tabBar:@"UIMainBar"
                                                          navBarEnabled:true
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true
                                                                segLeft:@"Categories"
                                                               segRight:@"My Activity"];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}


#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSegControl:)
                                                 name:@"RgSegmentControl"
                                               object:nil];
    
    [[RgLocationManager sharedInstance] requestWhenInUseAuthorization];
    [[RgLocationManager sharedInstance] startUpdatingLocation];
    [[RgLocationManager sharedInstance] addObserver:self forKeyPath:@"currentLocation" options:NSKeyValueObservingOptionNew context:nil];
    
    
    
//    if ([self needsRefresh])
//    {
//        LOGI(@"RingMail: Updating Hashtag Card List 1");
//        [mainViewController updateCollection];
//        [self setNeedsRefresh:NO];
//    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RgSegmentControl" object:nil];
    [[RgLocationManager sharedInstance] removeObserver:self forKeyPath:@"currentLocation" context:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    self.searchBarViewController = [[RgSearchBarViewController alloc] initWithPlaceHolder:@"Hashtag"];
    self.searchBarViewController.view.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 50);
    self.isSearchBarVisible = YES;
    [self addChildViewController:self.searchBarViewController];
    [self.view addSubview:self.searchBarViewController.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePathEvent:)
                                                 name:@"RgHashtagDirectoryUpdatePath"
                                               object:nil];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:0];
    
    HashtagCollectionViewController *mainController = [[HashtagCollectionViewController alloc] initWithCollectionViewLayout:flowLayout path:path];
    
    [[mainController collectionView] setBounces:YES];
    [[mainController collectionView] setAlwaysBounceVertical:YES];
    
    int width = [UIScreen mainScreen].applicationFrame.size.width;
    UIImageView *background;
    
    if (width == 320) {
        background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"explore_background_ip5p@2x.png"]];
    }
    else if (width == 375) {
        background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"explore_background_ip6-7s@2x.png"]];
    }
    else if (width == 414) {
        background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"explore_background_ip6-7p@3x.png"]];
    }
    
    [mainView addSubview:background];
    [mainView sendSubviewToBack:background];
    
    CGRect r = mainView.frame;
    r.origin.y = 0;
    [mainController.view setFrame:r];
    self.componentView = mainController.view;
    [mainView addSubview:mainController.view];
    [self addChildViewController:mainController];
    [mainController didMoveToParentViewController:self];
    mainViewController = mainController;
    
    categoryStack = [[NSMutableArray alloc] init];
    [categoryStack addObject:@"0"];
    
    UITapGestureRecognizer* tapBackground = [[UITapGestureRecognizer alloc] initWithTarget:self.searchBarViewController action:@selector(dismissKeyboard:)];
    [tapBackground setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapBackground];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"RgHashtagDirectoryUpdatePath" object:nil];
}

#pragma mark - Event Functions

- (void)updatePathEvent:(NSNotification *)notif
{
    [self updatePath:[notif.userInfo objectForKey:@"category_id"]];
}

- (void)updatePath:(NSString*)newPath
{
    [mainViewController removeFromParentViewController];
    [self.componentView removeFromSuperview];
    
    [self.searchBarViewController dismissKeyboard:nil];
    
    
    if ([newPath isEqual:@"Categories"])
    {
        // seg control changing back to last category view. exiting VC is removed and new re-allocated using exiting path value
    }
    else if ([newPath isEqual:@"0"])
    {
        [categoryStack removeLastObject];
        path = [categoryStack lastObject];
        if ([path isEqual:@"0"])
            [[NSNotificationCenter defaultCenter] postNotificationName:@"navBarViewChange" object:self userInfo:@{@"header": @"Explore", @"lSeg": @"Categories", @"rSeg": @"My Activity", @"backstate": @"reset"}];
    }
    else
    {
        path = newPath;
        [categoryStack addObject:newPath];
    }
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [flowLayout setMinimumInteritemSpacing:0];
    [flowLayout setMinimumLineSpacing:0];

    HashtagCollectionViewController *mainController = [[HashtagCollectionViewController alloc] initWithCollectionViewLayout:flowLayout path:path];

    [[mainController collectionView] setBounces:YES];
    [[mainController collectionView] setAlwaysBounceVertical:YES];

    CGRect r = mainView.frame;
    r.origin.y = 0;
    [mainController.view setFrame:r];
    self.componentView = mainController.view;
    [mainView addSubview:mainController.view];
    [self addChildViewController:mainController];
    [mainController didMoveToParentViewController:self];
    mainViewController = mainController;
}


#pragma mark - CardPageLoading Functions

- (void)showWaiting
{
	[waitView setHidden:NO];
}

- (void)hideWaiting
{
	[waitView setHidden:YES];
}


#pragma mark - MFComposeMailDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error {
	[controller dismissViewControllerAnimated:TRUE
								   completion:^{
								   }];
	[self.navigationController setNavigationBarHidden:TRUE animated:FALSE];
}

#pragma mark - Action Functions


- (void)handleSegControl:(NSNotification *)notif {
    NSString *segIndex = [notif.userInfo objectForKey:@"segIndex"];
    
    if([segIndex isEqual: @"0"])
        [self updatePath:@"Categories"];
    else if ([segIndex isEqual: @"1"])
        [mainViewController updateCollection:true];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object  change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"currentLocation"])
        [[RgLocationManager sharedInstance] stopUpdatingLocation];
}

@end
