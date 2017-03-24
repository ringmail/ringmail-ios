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

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#import "UICompositeViewController.h"
#import "UICamSwitch.h"
#import "UICallButton.h"
#import "UIMessageButton.h"
#import "UIDigitButton.h"

@interface RgMainViewController : UIViewController <UITextFieldDelegate, UICompositeViewDelegate, MFMailComposeViewControllerDelegate> {
}

- (void)handleUserActivity;
- (void)handleSegControl;
- (void)addMedia:(NSDictionary*)param;

@property (nonatomic, strong) IBOutlet UIView* videoPreview;
@property (nonatomic, strong) IBOutlet UICamSwitch* videoCameraSwitch;
@property (nonatomic, retain) IBOutlet UIImageView* backgroundImageView;
@property (nonatomic, assign) BOOL needsRefresh;
@property (nonatomic, assign) BOOL visible;
@property (nonatomic, assign) BOOL transferMode;
@property (nonatomic, strong) NSMutableDictionary* sendInfo;

- (IBAction)onAddContactClick: (id) event;

@end
