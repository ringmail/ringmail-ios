/* UIMainBar.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "UIMainBar.h"
#import "PhoneMainView.h"
#import "CAAnimation+Blocks.h"
#import "RKThreadStore.h"

@implementation UIMainBar

static NSString *const kBounceAnimation = @"bounce";
static NSString *const kAppearAnimation = @"appear";
static NSString *const kDisappearAnimation = @"disappear";

@synthesize hashtagButton;
@synthesize messagesButton;
@synthesize ringmailButton;
@synthesize contactsButton;
@synthesize settingsButton;
@synthesize chatNotificationView;
@synthesize chatNotificationLabel;
@synthesize logoView;
@synthesize background;

NSArray *buttonArray;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super initWithNibName:@"UIMainBar" bundle:[NSBundle mainBundle]];

    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(applicationWillEnterForeground:)
												 name:UIApplicationWillEnterForegroundNotification
											   object:nil];

    /*if (! [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.ringmail.phone"])
    {
        UIImage *logo = [UIImage imageNamed:@"ringmail_dev_logo"];
        [logoView setImage:logo];
    }*/
    
    buttonArray = [[NSArray alloc] initWithObjects:messagesButton,contactsButton,ringmailButton,settingsButton,hashtagButton,nil];
    
    [self setInstance: [UIScreen mainScreen].applicationFrame.size.width];
    
	[super viewDidLoad]; // Have to be after due to TPMultiLayoutViewController
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadSeenEvent:) name:kRKThreadSeen object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemActivityEvent:) name:kRKItemActivity object:nil];
	
}

- (void)viewDidUnload {
	[super viewDidUnload];

	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIApplicationWillEnterForegroundNotification
												  object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeViewEvent:) name:kLinphoneMainViewChange object:nil];
	[self update:FALSE];

}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneMainViewChange object:nil];
}

- (void)flipImageForButton:(UIButton *)button {
	UIControlState states[] = {UIControlStateNormal, UIControlStateDisabled, UIControlStateSelected,
							   UIControlStateHighlighted, -1};
	UIControlState *state = states;

	while (*state != -1) {
		UIImage *bgImage = [button backgroundImageForState:*state];

		UIImage *flippedImage =
			[UIImage imageWithCGImage:bgImage.CGImage scale:bgImage.scale orientation:UIImageOrientationUpMirrored];
		[button setBackgroundImage:flippedImage forState:*state];
		state++;
	}
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
								duration:(NSTimeInterval)duration {
	// Force the animations
	[[self.view layer] removeAllAnimations];
	[chatNotificationView.layer setTransform:CATransform3DIdentity];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[chatNotificationView setHidden:TRUE];
	[self update:FALSE];
}


- (void)setInstance:(int)widthIn
{
    buttonArray = [[NSArray alloc] initWithObjects:messagesButton,contactsButton,ringmailButton,hashtagButton,settingsButton,nil];
    
    NSArray *imgPrefix =  [NSArray arrayWithObjects:@"tabs_recents%@%@",@"tabs_contacts%@%@",@"tabs_ring%@%@",@"tabs_explore%@%@",@"tabs_settings%@%@",nil];
    NSArray *imgSuffix = [NSArray arrayWithObjects:@"_5@2x",@"@2x",@"@3x",nil];
    NSArray *imgState = [NSArray arrayWithObjects:@"_normal",@"_pressed",@"_selected",nil];
    
    int i = 0; int j = 0;
    
    if (widthIn == 320) {
        background.image = [UIImage imageNamed:@"tabs_background_5@2x"];
    }
    else if (widthIn == 375) {
        background.image = [UIImage imageNamed:@"tabs_background@2x"];
        j = 1;
    }
    else if (widthIn == 414) {
        background.image = [UIImage imageNamed:@"tabs_background@3x"];
        j = 2;
    }
    
    for (UIButton* btn in buttonArray) {
        NSString *tabNorm = [NSString stringWithFormat:imgPrefix[i], imgState[0], imgSuffix[j]];
        NSString *tabPres = [NSString stringWithFormat:imgPrefix[i], imgState[1], imgSuffix[j]];
        NSString *tabSele = [NSString stringWithFormat:imgPrefix[i], imgState[2], imgSuffix[j]];
        
        [btn setImage:[UIImage imageNamed:tabNorm] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:tabPres] forState:UIControlStateHighlighted];
        [btn setImage:[UIImage imageNamed:tabSele] forState:UIControlStateSelected];
        
        CGSize imageSize = btn.imageView.image.size;
        btn.titleEdgeInsets = UIEdgeInsetsMake(imageSize.height, -imageSize.width, 0.0, 0.0);
        
        i++;
    }
}


#pragma mark - Event Functions

- (void)applicationWillEnterForeground:(NSNotification *)notif {
	// Force the animations
	[[self.view layer] removeAllAnimations];
	[chatNotificationView.layer setTransform:CATransform3DIdentity];
	[chatNotificationView setHidden:TRUE];
	[self update:FALSE];
}

- (void)changeViewEvent:(NSNotification *)notif {
	// UICompositeViewDescription *view = [notif.userInfo objectForKey: @"view"];
	// if(view != nil)
	[self updateView:[[PhoneMainView instance] firstView]];
}

- (void)threadSeenEvent:(NSNotification *)notif
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        [self updateUnread];
    }];
}

- (void)itemActivityEvent:(NSNotification *)notif
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	if (! [notif.userInfo[@"name"] isEqualToString:kRKMessageUpdated]) // skip updated messages
	{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
            [self updateUnread];
        }];
	}
}

#pragma mark -

- (void)update:(BOOL)appear {
	[self updateView:[[PhoneMainView instance] firstView]];
	[self updateUnread];
    
    // center button text below button image
//    for (UIButton* btn in buttonArray) {
//        CGSize imageSize = btn.imageView.image.size;
//        CGSize titleSize = [btn.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: btn.titleLabel.font}];
//        CGSize contentSize = btn.frame.size;
//        btn.titleEdgeInsets = UIEdgeInsetsMake((contentSize.height - titleSize.height - 4), -(imageSize.width/2 + titleSize.width/2), 0.0, 0.0);
//    }

}

- (void)updateUnread
{
    NSNumber* unread = [NSNumber numberWithInteger:[[RKThreadStore sharedInstance] getUnseenCount]];
	int unreadMessage = [unread intValue];
	if (unreadMessage > 0)
	{
		if ([chatNotificationView isHidden])
        {
			[chatNotificationView setHidden:FALSE];
		}
		[chatNotificationLabel setText:[unread stringValue]];
	}
	else
	{
		if (![chatNotificationView isHidden])
        {
			[chatNotificationView setHidden:TRUE];
		}
	}
}

- (void)appearAnimation:(NSString *)animationID target:(UIView *)target completion:(void (^)(BOOL finished))completion {
	CABasicAnimation *appear = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	appear.duration = 0.4;
	appear.fromValue = [NSNumber numberWithDouble:0.0f];
	appear.toValue = [NSNumber numberWithDouble:1.0f];
	appear.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	appear.fillMode = kCAFillModeForwards;
	appear.removedOnCompletion = NO;
	[appear setCompletion:completion];
	[target.layer addAnimation:appear forKey:animationID];
}

- (void)disappearAnimation:(NSString *)animationID
					target:(UIView *)target
				completion:(void (^)(BOOL finished))completion {
	CABasicAnimation *disappear = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
	disappear.duration = 0.4;
	disappear.fromValue = [NSNumber numberWithDouble:1.0f];
	disappear.toValue = [NSNumber numberWithDouble:0.0f];
	disappear.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	disappear.fillMode = kCAFillModeForwards;
	disappear.removedOnCompletion = NO;
	[disappear setCompletion:completion];
	[target.layer addAnimation:disappear forKey:animationID];
}

- (void)startBounceAnimation:(NSString *)animationID target:(UIView *)target {
	CABasicAnimation *bounce = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
	bounce.duration = 0.3;
	bounce.fromValue = [NSNumber numberWithDouble:0.0f];
	bounce.toValue = [NSNumber numberWithDouble:8.0f];
	bounce.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	bounce.autoreverses = TRUE;
	bounce.repeatCount = HUGE_VALF;
	[target.layer addAnimation:bounce forKey:animationID];
}

- (void)stopBounceAnimation:(NSString *)animationID target:(UIView *)target {
	[target.layer removeAnimationForKey:animationID];
}

- (void)updateView:(UICompositeViewDescription *)view {
	// Update buttons
	if ([view equal:[MessagesViewController compositeViewDescription]]) {
		messagesButton.selected = TRUE;
	} else {
		messagesButton.selected = FALSE;
	}
	if ([view equal:[ContactsViewController compositeViewDescription]]) {
		contactsButton.selected = TRUE;
	} else {
		contactsButton.selected = FALSE;
	}
	if ([view equal:[RgMainViewController compositeViewDescription]]) {
		ringmailButton.selected = TRUE;
	} else {
		ringmailButton.selected = FALSE;
	}
	if ([view equal:[SettingsViewController compositeViewDescription]]) {
		settingsButton.selected = TRUE;
	} else {
		settingsButton.selected = FALSE;
	}
	if ([view equal:[RgHashtagDirectoryViewController compositeViewDescription]]) {
		hashtagButton.selected = TRUE;
	} else {
		hashtagButton.selected = FALSE;
	}
}

#pragma mark - Action Functions

- (IBAction)onExploreClick:(id)event {
	[[PhoneMainView instance] changeCurrentView:[RgHashtagDirectoryViewController compositeViewDescription]];
}

- (IBAction)onMessagesClick:(id)event {
	[[PhoneMainView instance] changeCurrentView:[MessagesViewController compositeViewDescription]];
}

- (IBAction)onRingMailClick:(id)event {
	[[PhoneMainView instance] changeCurrentView:[RgMainViewController compositeViewDescription]];
}

- (IBAction)onContactsClick:(id)event {
	[ContactSelection setSelectionMode:ContactSelectionModeNone];
	[ContactSelection setAddAddress:nil];
	[ContactSelection setSipFilter:nil];
	[ContactSelection enableEmailFilter:FALSE];
	[ContactSelection setNameOrEmailFilter:nil];
	[[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription]];
}

- (IBAction)onSettingsClick:(id)event {
	[[PhoneMainView instance] changeCurrentView:[SettingsViewController compositeViewDescription]];
}


#pragma mark - TPMultiLayoutViewController Functions

- (NSDictionary *)attributesForView:(UIView *)view {
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];

	[attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
	[attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
	if ([view isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton *)view;
		[LinphoneUtils buttonMultiViewAddAttributes:attributes button:button];
	}
	[attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];

	return attributes;
}

- (void)applyAttributes:(NSDictionary *)attributes toView:(UIView *)view {
	view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
	view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
	if ([view isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton *)view;
		[LinphoneUtils buttonMultiViewApplyAttributes:attributes button:button];
	}
	view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}

@end
