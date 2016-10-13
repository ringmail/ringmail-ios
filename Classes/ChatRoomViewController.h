/* ChatRoomViewController.h
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

#import <UIKit/UIKit.h>

#import "UIToggleButton.h"
#import "UICompositeViewController.h"
#import "HPGrowingTextView.h"
#import "OrderedDictionary.h"
#import "RgMessagesViewController.h"
#import "RgManager.h"

#include "linphone/linphonecore.h"

@interface ChatRoomViewController : UIViewController<UICompositeViewDelegate> {
}

@property (nonatomic, strong) IBOutlet UIToggleButton *editButton;
@property (nonatomic, strong) IBOutlet UILabel *addressLabel;
@property (nonatomic, strong) IBOutlet UIImageView *avatarImage;
@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UIView *chatView;
@property (nonatomic, strong) IBOutlet UIView *originalToView;
@property (nonatomic, strong) IBOutlet UILabel *originalToLabel;
@property (nonatomic, strong) IBOutlet RgMessagesViewController *chatViewController;

- (IBAction)onBackClick:(id)event;
- (IBAction)onEditClick:(id)event;
- (IBAction)onCallClick:(id)sender;
- (IBAction)onVideoClick:(id)sender;
- (IBAction)onContactClick:(id)sender;

@end
