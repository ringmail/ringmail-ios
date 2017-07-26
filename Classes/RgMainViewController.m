/* RgMainViewController.h
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

#import "RgMainViewController.h"
#import "RgInCallViewController.h"
#import "DTAlertView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "UIColor+Hex.h"
#import "SendViewController.h"

#include "linphone/linphonecore.h"

#import "RgLocationManager.h"
#import "RgSearchBarViewController.h"

@interface RgMainViewController()
@property BOOL isSearchBarVisible;
@property BOOL didSubscribeToCurrentLocation;
@property (strong, nonatomic) RgSearchBarViewController *searchBarViewController;
@property (nonatomic, retain) IBOutlet SendViewController* sendViewController;
@end

@implementation RgMainViewController

@synthesize sendViewController;
@synthesize backgroundImageView;
@synthesize sendInfo;
@synthesize isEditing;
@synthesize didSubscribeToCurrentLocation;

#pragma mark - Lifecycle Functions

- (id)init {
	NSLog(@"RgMainViewController init");
	self = [super initWithNibName:@"RgMainViewController" bundle:[NSBundle mainBundle]];
	if (self) {
		self->sendInfo = [NSMutableDictionary dictionaryWithDictionary:@{
			@"media": [self getMediaThumbnails:[self getLatestMedia]],
		}];
		self->isEditing = FALSE;
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
		compositeDescription = [[UICompositeViewDescription alloc] init:@"RingMail"
																content:@"RgMainViewController"
															   stateBar:@"UIStateBar"
														stateBarEnabled:true
                                                                 navBar:@"UINavBar"
																 tabBar:@"UIMainBar"
                                                          navBarEnabled:true
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    self.searchBarViewController = [[RgSearchBarViewController alloc] initWithPlaceHolder:@"Hashtag, Domain or Email"];
    self.searchBarViewController.view.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 50);
    self.isSearchBarVisible = YES;
    self.didSubscribeToCurrentLocation = NO;
    [self addChildViewController:self.searchBarViewController];
    [self.view addSubview:self.searchBarViewController.view];
    
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
    
//    self.searchBarViewController = [[RgSearchBarViewController alloc] initWithPlaceHolder:@"Hashtag, Domain or Email"];
//    self.searchBarViewController.view.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 50);
//    self.isSearchBarVisible = YES;
//    [self addChildViewController:self.searchBarViewController];
//    [self.view addSubview:self.searchBarViewController.view];
    
    UITapGestureRecognizer* tapBackground = [[UITapGestureRecognizer alloc] initWithTarget:self.searchBarViewController action:@selector(dismissKeyboard:)];
    [tapBackground setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapBackground];
	
	[sendViewController setSendInfo:sendInfo];
    
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	// Set observer
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSegControl) name:kRgSegmentControl object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
	[[RgLocationManager sharedInstance] addObserver:self forKeyPath:kRgCurrentLocation options:NSKeyValueObservingOptionNew context:nil];
    self.didSubscribeToCurrentLocation = YES;
    [[RgLocationManager sharedInstance] requestWhenInUseAuthorization];
    [[RgLocationManager sharedInstance] startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kRgSegmentControl object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    if (self.didSubscribeToCurrentLocation)
    {
        [[RgLocationManager sharedInstance] removeObserver:self forKeyPath:kRgCurrentLocation context:nil];
        self.didSubscribeToCurrentLocation = NO;
    }
}

#pragma mark - Action Functions

- (void)handleSegControl
{
    printf("rgmain segement controller hit\n");
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object  change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kRgCurrentLocation])
	{
        [[RgLocationManager sharedInstance] stopUpdatingLocation];
	}
}

#pragma mark - Keyboard Events

- (void)keyboardWillShow:(NSNotification*)event
{
	self.isEditing = YES;
}

- (void)keyboardWillHide:(NSNotification*)event
{
	self.isEditing = NO;
}

#pragma mark - Tap Recognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (self.isEditing)
	{
        UITouch *touch = [touches anyObject];
        if (![touch.view isMemberOfClass:[UITextField class]])
    	{
    		[touch.view endEditing:YES];
        }
	}
}

#pragma mark - Photos & Videos

- (BOOL)hasNewMedia:(NSArray*)media current:(NSArray*)prev
{
	if ([prev count] == 0)
	{
		if ([media count] > 0)
		{
			return YES;
		}
		else
		{
			return NO;
		}
	}
	else if ([media count] > 0 && [prev count] > 0)
	{
		NSString* item1 = [(PHAsset*)media[0][@"asset"] localIdentifier];
		NSString* item2 = [(PHAsset*)prev[0][@"asset"] localIdentifier];
		if ([item1 isEqualToString:item2])
		{
			return NO;
		}
		else
		{
			return YES;
		}
	}
	else
	{
		return NO; // Both empty
	}
}

- (NSArray*)getLatestMedia
{
    // load recent media
    int max = 25;
    int count = 0;
    NSMutableArray *assets = [NSMutableArray new];
    PHFetchOptions *mainopts = [[PHFetchOptions alloc] init];
    mainopts.sortDescriptors = @[
    	[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:NO],
    ];
    PHFetchResult *collects = [PHAssetCollection fetchMomentsWithOptions:mainopts];
    for (PHAssetCollection *collection in collects)
    {
    	//NSLog(@"Collection(%@): %@", collection.localizedTitle, collection);
    	PHFetchOptions *opts = [[PHFetchOptions alloc] init];
    	opts.fetchLimit = max;
    	opts.sortDescriptors = @[
    		[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO],
        ];
    	PHFetchResult *fr = [PHAsset fetchAssetsInAssetCollection:collection options:opts];
        for (PHAsset *asset in fr)
    	{
    		if (count < max)
    		{
    			[assets addObject:@{@"asset": asset}];
    			count++;
    		}
        }
    	if (count == max)
    	{
    		break;
    	}
    }
    [assets sortUsingComparator:^NSComparisonResult(NSDictionary* obj1, NSDictionary* obj2) {
    	return [[(PHAsset*)obj2[@"asset"] creationDate] compare:[(PHAsset*)obj1[@"asset"] creationDate]];
    }];
    //NSLog(@"Latest Media: %@", assets);
	return assets;
}

- (NSArray*)getMediaThumbnails:(NSArray*)media
{
	__block NSMutableArray* res = [NSMutableArray new];
	PHImageManager* imageManager = [PHImageManager defaultManager];
	PHImageRequestOptions* opts = [PHImageRequestOptions new];
	opts.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
	opts.resizeMode = PHImageRequestOptionsResizeModeExact;
	opts.synchronous = YES;
	for (NSDictionary* item in media)
	{
		[imageManager requestImageForAsset:item[@"asset"] targetSize:CGSizeMake(142, 142) contentMode:PHImageContentModeAspectFill options:opts resultHandler:^(UIImage* image, NSDictionary* info){
			[res addObject:@{
				@"asset": item[@"asset"],
				@"thumbnail": image,
			}];
		}];
	}
	return res;
}


- (void)addMedia:(NSDictionary*)param
{
	[sendViewController addMedia:param];
}

#pragma mark - SendContactSelectDelegate Functions

- (void)didSelectSingleContact:(NSString*)address
{
	NSLog(@"%s: Address: %@", __PRETTY_FUNCTION__, address);
    [sendViewController updateTo:address];
}

/*- (void)didSelectMultipleContacts:(NSMutableArray*)contacts
{
    for (id obj in contacts)
        NSLog(@"didSelectMultiSendContact:  %@", obj);
    
    NSLog(@"momentData[file]: %@",momentData[@"file"]);
    
    RgMainViewController* ctl = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription] push:NO], RgMainViewController);
    
    momentData = @{};
    [ctl sendMulti:@{}];
}*/

@end
