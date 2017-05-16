/* RgInCallViewController.h
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

#import <UIKit/UIKit.h>

#import "VideoZoomHandler.h"

#import "UICompositeViewController.h"
#import "RgCallViewController.h"
#import "RgCallDuration.h"
#import "UIDigitButton.h"

@class VideoViewController;

@interface RgInCallViewController : UIViewController <UIGestureRecognizerDelegate, UICompositeViewDelegate> {
    @private
    UITapGestureRecognizer* singleFingerTap;
    NSTimer* hideControlsTimer;
    BOOL videoShown;
    VideoZoomHandler* videoZoomHandler;
}

@property (nonatomic, strong) IBOutlet UIView* videoGroup;
@property (nonatomic, strong) IBOutlet UIView* videoView;
#ifdef TEST_VIDEO_VIEW_CHANGE
@property (nonatomic, retain) IBOutlet UIView* testVideoView;
#endif
@property (nonatomic, strong) IBOutlet UIView* videoPreview;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView* videoWaitingForFirstImage;

@property (nonatomic, strong) IBOutlet UILabel *addressLabel;
@property (nonatomic, strong) IBOutlet UIImageView *avatarImage;
@property (nonatomic, strong) IBOutlet RgCallViewController* callViewController;
@property (nonatomic, strong) NSMutableDictionary* callData;

@property (nonatomic, strong) IBOutlet UIView* padView;
@property (nonatomic, strong) IBOutlet UIView* backView;
@property (nonatomic, strong) IBOutlet UIButton* backButton;

@property (nonatomic, retain) NSNumber* padActive;
@property (nonatomic, strong) IBOutlet UIDigitButton* oneButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* twoButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* threeButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* fourButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* fiveButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* sixButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* sevenButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* eightButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* nineButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* starButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* zeroButton;
@property (nonatomic, strong) IBOutlet UIDigitButton* sharpButton;

+ (int)callCount:(LinphoneCore *)lc;
+ (LinphoneCall *)retrieveCallAtIndex:(NSInteger)index;

- (IBAction)onHideButton:(id)sender;

@end
