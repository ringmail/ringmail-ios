/* ImageViewController.m
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

#import "ImageViewController.h"
#import "PhoneMainView.h"

@implementation ImageViewController

@synthesize image;
@synthesize photoBrowser;

#pragma mark - Lifecycle Functions

- (instancetype)initWithImage:(UIImage*)aimage
{
	self = [super init];
	if (self)
	{
		self->image = aimage;
		IDMPhoto* photo = [IDMPhoto photoWithImage:aimage];
		self->photoBrowser = [[IDMPhotoBrowser alloc] initWithPhotos:@[photo]];
	}
	return self;
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"ImageView"
																content:@"ImageViewController"
															   stateBar:nil
														stateBarEnabled:false
                                                                 navBar:nil
																 tabBar:nil
                                                          navBarEnabled:false
														  tabBarEnabled:false
															 fullscreen:true
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true];
	}
	return compositeDescription;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	[self addChildViewController:self.photoBrowser];
	self.photoBrowser.view.frame = self.view.frame;
	[self.view addSubview:self.photoBrowser.view];
	[self.photoBrowser didMoveToParentViewController:self];
	self.photoBrowser.delegate = self;
}

#pragma mark - Action Functions

- (void)willDisappearPhotoBrowser:(IDMPhotoBrowser *)photoBrowser;
{
	if ([[[PhoneMainView instance] currentView] equal:[ImageViewController compositeViewDescription]]) {
		[[PhoneMainView instance] popCurrentView];
	}
}

@end
