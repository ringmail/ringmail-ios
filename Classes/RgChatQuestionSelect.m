/* ContactDetailsViewController.m
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
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "RgChatQuestionSelect.h"
#import "PhoneMainView.h"

@implementation RgChatQuestionSelect

@synthesize tableController;
@synthesize editButton;
@synthesize backButton;
@synthesize cancelButton;

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];

	// Set selected+over background: IB lack !
	[editButton setBackgroundImage:[UIImage imageNamed:@"contact_ok_over.png"]
						  forState:(UIControlStateHighlighted | UIControlStateSelected)];

	// Set selected+disabled background: IB lack !
	[editButton setBackgroundImage:[UIImage imageNamed:@"contact_ok_disabled.png"]
						  forState:(UIControlStateDisabled | UIControlStateSelected)];

	[LinphoneUtils buttonFixStates:editButton];
    
    [super viewDidLoad];

}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ([ContactSelection getSelectionMode] == ContactSelectionModeEdit ||
		[ContactSelection getSelectionMode] == ContactSelectionModeNone) {
		[editButton setHidden:FALSE];
	} else {
		[editButton setHidden:TRUE];
	}
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"RgChatQuestion"
																content:@"RgChatQuestionSelect"
															   stateBar:nil
														stateBarEnabled:false
                                                                 navBar:@"UINavBar"
																 tabBar:@"UIMainBar"
                                                          navBarEnabled:true  
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true
                                                                segLeft:@""
                                                               segRight:@""];
	}
	return compositeDescription;
}

#pragma mark -

- (void)enableEdit:(BOOL)animated {
	[editButton setOn];
	[cancelButton setHidden:FALSE];
	[backButton setHidden:TRUE];
}

- (void)disableEdit:(BOOL)animated {
	[editButton setOff];
	[cancelButton setHidden:TRUE];
	[backButton setHidden:FALSE];
}

#pragma mark - Action Functions

- (IBAction)onCancelClick:(id)event {
	[self disableEdit:TRUE];
}

- (IBAction)onBackClick:(id)event {
	[[PhoneMainView instance] popCurrentView];
}

- (IBAction)onEditClick:(id)event {
}

- (void)onRemove:(id)event {
	[self disableEdit:FALSE];
	[[PhoneMainView instance] popCurrentView];
}

- (void)onModification:(id)event {
}

@end
