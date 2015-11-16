/* ContactDetailsViewController.h
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
#import <AddressBook/AddressBook.h>

#import "UICompositeViewController.h"
#import "UIToggleButton.h"
#import "RgChatQuestionTable.h"

@interface RgChatQuestionSelect : UIViewController<UICompositeViewDelegate> {
}

@property (nonatomic, strong) IBOutlet RgChatQuestionTable *tableController;
@property (nonatomic, strong) IBOutlet UIToggleButton *editButton;
@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;

- (IBAction)onBackClick:(id)event;
- (IBAction)onCancelClick:(id)event;
- (IBAction)onEditClick:(id)event;

@end
