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

@implementation RgHashtagDirectoryViewController

@synthesize addressField;
@synthesize backButton;
@synthesize callButton;
@synthesize goButton;
@synthesize messageButton;
@synthesize mainView;
@synthesize mainViewController;
@synthesize path;
@synthesize waitView;

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
		compositeDescription = [[UICompositeViewDescription alloc] init:@"HashtagDirectory"
																content:@"RgHashtagDirectoryViewController"
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

    NSString *intro = @"";
    NSAttributedString *placeHolderString = [[NSAttributedString alloc] initWithString:intro
        attributes:@{
            NSForegroundColorAttributeName:[UIColor colorWithHex:@"#878787"],
            NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeueLTStd-Cn" size:19]
        }];
	addressField.attributedPlaceholder = placeHolderString;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

}

- (void)viewDidLoad {
	[super viewDidLoad];
    
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
    
    CGRect r = mainView.frame;
    r.origin.y = 0;
    [mainController.view setFrame:r];
    self.componentView = mainController.view;
    [mainView addSubview:mainController.view];
    [self addChildViewController:mainController];
    [mainController didMoveToParentViewController:self];
    mainViewController = mainController;
    addressField.returnKeyType = UIReturnKeyDone;
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
    
    path = newPath;
    
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

- (void)setAddressEvent:(NSNotification *)notif
{
    NSString *newAddress = [notif.userInfo objectForKey:@"address"];
    NSLog(@"RingMail - Set Address Event: %@", newAddress);
    [addressField setText:newAddress];
    if ([[newAddress substringToIndex:1] isEqualToString:@"#"])
    {
        messageButton.hidden = YES;
        callButton.hidden = YES;
        goButton.hidden = NO;
    }
    else
    {
        messageButton.hidden = NO;
        callButton.hidden = NO;
        goButton.hidden = YES;
    }
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

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
	//[textField performSelector:@selector() withObject:nil afterDelay:0];
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"textFieldShouldReturn");
	if (textField == addressField) {
        NSLog(@"textField == addressField");
        [goButton sendActionsForControlEvents:UIControlEventTouchUpInside];
		[addressField resignFirstResponder];
	}
	return YES;
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

- (IBAction)onAddressChange:(id)sender {
	if ([[addressField text] length] > 0) {
        NSString* addr = [addressField text];
        if ([[addr substringToIndex:1] isEqualToString:@"#"])
        {
            messageButton.hidden = YES;
            callButton.hidden = YES;
            goButton.hidden = NO;
        }
        else
        {
            messageButton.hidden = NO;
            callButton.hidden = NO;
            goButton.hidden = YES;
        }
	} else {
        messageButton.hidden = YES;
        callButton.hidden = YES;
        goButton.hidden = YES;
	}
}

@end
