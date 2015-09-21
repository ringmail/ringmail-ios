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

#import "UICompositeViewController.h"

#import "UIEraseButton.h"
#import "UICamSwitch.h"
#import "UICallButton.h"
#import "UIMessageButton.h"
#import "UITransferButton.h"
#import "UIDigitButton.h"

@interface RgMainViewController : UIViewController <UITextFieldDelegate, UICompositeViewDelegate, MFMailComposeViewControllerDelegate> {
}

- (void)setAddress:(NSString*)address;
- (void)call:(NSString*)address displayName:(NSString *)displayName;
- (void)call:(NSString*)address;

@property (nonatomic, assign) BOOL transferMode;

@property (nonatomic, strong) IBOutlet UITextField* addressField;
@property (nonatomic, strong) IBOutlet UIButton* addContactButton;
@property (nonatomic, strong) IBOutlet UICallButton* callButton;
@property (nonatomic, strong) IBOutlet UICallButton* goButton;
@property (nonatomic, strong) IBOutlet UIMessageButton* messageButton;
@property (nonatomic, strong) IBOutlet UICallButton* addCallButton;
@property (nonatomic, strong) IBOutlet UITransferButton* transferButton;
@property (nonatomic, strong) IBOutlet UIButton* backButton;
@property (nonatomic, strong) IBOutlet UIEraseButton* eraseButton;

@property (nonatomic, strong) IBOutlet UIView* backgroundView;
@property (nonatomic, strong) IBOutlet UIView* videoPreview;
@property (nonatomic, strong) IBOutlet UICamSwitch* videoCameraSwitch;

- (IBAction)onAddContactClick: (id) event;
- (IBAction)onBackClick: (id) event;
- (IBAction)onAddressChange: (id)sender;

@end
