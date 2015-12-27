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
@synthesize mediaPickerController;

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
    self.mediaPickerController = [[CRMediaPickerController alloc] init];
    self.mediaPickerController.delegate = self;
    self.mediaPickerController.mediaType = CRMediaPickerControllerMediaTypeImage;
    self.mediaPickerController.sourceType = CRMediaPickerControllerSourceTypeCamera;
    self.mediaPickerController.allowsEditing = NO;
    
    UIImagePickerController* picker = [[UIImagePickerController alloc] init];
    
    //Create camera overlay for square pictures
    CGFloat navigationBarHeight = picker.navigationBar.bounds.size.height;
    CGFloat height = picker.view.bounds.size.height;
    CGFloat width = picker.view.bounds.size.width;
    CGFloat barHeight = 166.0f;
    CGFloat camHeight = (height - barHeight) / 2;
    CGFloat slot = 80.0f / 2.0f;
    CGRect f = CGRectMake(0, 0, width, height);
    UIGraphicsBeginImageContext(f.size);
    [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.75] set];
    UIRectFillUsingBlendMode(CGRectMake(0, navigationBarHeight, width, camHeight - slot), kCGBlendModeNormal);
    UIRectFillUsingBlendMode(CGRectMake(0, navigationBarHeight + camHeight + slot, width, camHeight - slot), kCGBlendModeNormal);
    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *overlayIV = [[UIImageView alloc] initWithFrame:f];
    
    // Disable all user interaction on overlay
    [overlayIV setUserInteractionEnabled:NO];
    [overlayIV setExclusiveTouch:NO];
    [overlayIV setMultipleTouchEnabled:NO];
    
    // Map generated image to overlay
    overlayIV.image = overlayImage;
    
    self.mediaPickerController.showsCameraControls = YES;
    self.mediaPickerController.cameraOverlayView = overlayIV;
    [self.mediaPickerController show];
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
    rotatedCorrectly = [rotatedCorrectly scaleToFitSize:(CGSize){1024, 1024}];
    UIImage *processed = [imageProcessor processImage:rotatedCorrectly];
    
    [self recognizeScan:processed];
    
    [self setImage:processed];
}

- (void)recognizeScan:(UIImage*)input {
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng" configDictionary:@{} configFileNames:@[] absoluteDataPath:[[NSBundle mainBundle] resourcePath] engineMode:G8OCREngineModeTesseractOnly copyFilesFromResources:NO];
    
    //tesseract.charWhitelist = @"#_0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz ";
    tesseract.pageSegmentationMode = G8PageSegmentationModeSingleLine;
    tesseract.image = [input g8_blackAndWhite];
    
    [tesseract recognize];
    
    NSString *result = [tesseract recognizedText];
    NSLog(@"RingMail - Recognized Text: '%@'", result);
    
    result = [result stringByReplacingOccurrencesOfRegex:@"[^#a-zA-Z0-9_ ]" withString:@""];
    result = [result stringByReplacingOccurrencesOfRegex:@"^\\s*" withString:@""];
    result = [result stringByReplacingOccurrencesOfRegex:@"\\s.*" withString:@""];
    
    NSLog(@"RingMail - Processed Text: '%@'", result);
    
    if ([result isMatchedByRegex:@"^#"])
    {
        NSLog(@"RingMail - Recognized Hashtag: '%@' !!!", result);
        NSDictionary *dict = @{
                               @"address": result,
                               };
        [[NSNotificationCenter defaultCenter] postNotificationName:kRgSetAddress object:self userInfo:dict];
        if ([[[PhoneMainView instance] currentView] equal:[RgScanViewController compositeViewDescription]]) {
            [[PhoneMainView instance] popCurrentView];
        }
    }
}

#pragma mark - Action Functions

- (IBAction)onBackClick:(id)sender {
	if ([[[PhoneMainView instance] currentView] equal:[RgScanViewController compositeViewDescription]]) {
		[[PhoneMainView instance] popCurrentView];
	}
}

#pragma mark - Picker Delegate Functions

/*- (void)imagePickerDelegateImage:(UIImage *)scan info:(NSDictionary *)info {
    [self processScan:scan];
}*/

- (void)CRMediaPickerController:(CRMediaPickerController *)mediaPickerController didFinishPickingAsset:(ALAsset *)asset error:(NSError *)error
{
    if (!error) {
        
        if (asset) {
            
            if ([[asset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto])
            {
                ALAssetRepresentation *representation = asset.defaultRepresentation;
                UIImage *scan = [UIImage imageWithCGImage:representation.fullScreenImage];
                double slice = scan.size.height * 0.125; // Take middle 8th
                UIImage *cropped = [scan cropToSize:(CGSize){scan.size.width, slice} usingMode:NYXCropModeCenter];
                
                NSString *imageID = [[[[LinphoneManager instance] chatManager] xmppStream] generateUUID];
                NSData *imageData = UIImagePNGRepresentation(cropped);
                [[RgNetwork instance] uploadImage:imageData uuid:imageID callback:^(AFHTTPRequestOperation *operation, id responseObject) {
                    NSDictionary* res = responseObject;
                    NSString *ok = [res objectForKey:@"result"];
                    if ([ok isEqualToString:@"ok"])
                    {
                        NSLog(@"RingMail - Scan Image Upload Success: %@", res);
                    }
                }];
                [self processScan:cropped];
            }
            
        } else {
            NSLog(@"No media selected");
        }
        
    } else {
        NSLog(@"%@", error.localizedDescription);
    }
}

- (void)CRMediaPickerControllerDidCancel:(CRMediaPickerController *)mediaPickerController
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

@end
