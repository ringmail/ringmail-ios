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

#import "RgScanViewController.h"
#import "PhoneMainView.h"
#import "ImageProcessingImplementation.h"
#import "UIImage+operation.h"
#import "NYXImagesKit/NYXImagesKit.h"

@implementation RgScanViewController

@synthesize scrollView;
@synthesize backButton;
@synthesize image;

#pragma mark - Lifecycle Functions

- (id)init {
	return [super initWithNibName:@"ImageViewController" bundle:[NSBundle mainBundle]];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"RgScanView"
																content:@"RgScanViewController"
															   stateBar:nil
														stateBarEnabled:false
																 tabBar:nil
														  tabBarEnabled:false
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true];
	}
	return compositeDescription;
}

#pragma mark - Property Functions

- (void)setImage:(UIImage *)aimage {
	scrollView.image = aimage;
}

- (UIImage *)image {
	return scrollView.image;
}

#pragma mark - Scan

- (void)beginScan {
    UICompositeViewDescription *description = [ImagePickerViewController compositeViewDescription];
    ImagePickerViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:description push:TRUE],
                                  ImagePickerViewController);
    if (controller != nil) {
        controller.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        // Displays a control that allows the user to choose picture or
        // movie capture, if both are available:
        controller.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeImage];
        
        // Hides the controls for moving & scaling pictures, or for
        // trimming movies. To instead show the controls, use YES.
        controller.allowsEditing = NO;
        controller.imagePickerDelegate = self;
        
        /*
        //Create camera overlay for square pictures
        CGSize viewSize = [controller getCaptureViewSize];
        CGSize navSize = [controller getCaptureNavSize];
        CGFloat navigationBarHeight = navSize.height + 25;
        CGFloat height = viewSize.height - 2 * navigationBarHeight;
        CGFloat width = viewSize.width;
        CGRect f = CGRectMake(0, navigationBarHeight, width, height);
        CGFloat barHeight = (f.size.height - f.size.width) / 2;
        UIGraphicsBeginImageContext(f.size);
        [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7] set];
        UIRectFillUsingBlendMode(CGRectMake(0, 0, f.size.width, barHeight), kCGBlendModeNormal);
        UIRectFillUsingBlendMode(CGRectMake(0, f.size.height - barHeight, f.size.width, barHeight - 4), kCGBlendModeNormal);
        UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        UIImageView *overlayIV = [[UIImageView alloc] initWithFrame:f];
        
        // Disable all user interaction on overlay
        [overlayIV setUserInteractionEnabled:NO];
        [overlayIV setExclusiveTouch:NO];
        [overlayIV setMultipleTouchEnabled:NO];
        
        // Map generated image to overlay
        overlayIV.image = overlayImage;
        
        [controller setOverlayView:overlayIV];
        */
    }
}

- (void)processScan:(UIImage*)input {
    UIImage *rotatedCorrectly;
    if (input.imageOrientation!=UIImageOrientationUp)
    {
        rotatedCorrectly = [input rotate:input.imageOrientation];
    }
    else
    {
        rotatedCorrectly = input;
    }
    ImageProcessingImplementation *imageProcessor = [[ImageProcessingImplementation alloc] init];
    rotatedCorrectly = [rotatedCorrectly scaleToFitSize:(CGSize){2048, 2048}];
    UIImage *processed = [imageProcessor processImage:rotatedCorrectly];
    [self setImage:processed];
}

#pragma mark - Action Functions

- (IBAction)onBackClick:(id)sender {
	if ([[[PhoneMainView instance] currentView] equal:[RgScanViewController compositeViewDescription]]) {
		[[PhoneMainView instance] popCurrentView];
	}
}

#pragma mark - ImagePickerDelegate Functions

- (void)imagePickerDelegateImage:(UIImage *)scan info:(NSDictionary *)info {
    [self processScan:scan];
}

@end
