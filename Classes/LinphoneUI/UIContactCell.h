/* UIContactCell.h
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

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "UITransparentTVCell.h"

@interface UIContactCell : UITransparentTVCell {
}

@property (nonatomic, strong) IBOutlet UILabel* firstNameLabel;
@property (nonatomic, strong) IBOutlet UILabel* lastNameLabel;
@property (nonatomic, strong) IBOutlet UILabel* contactLabel;
@property (nonatomic, strong) IBOutlet UIImageView *avatarImage;
@property (nonatomic, strong) IBOutlet UIImageView *rgImage;
@property (nonatomic, assign) ABRecordRef contact;
@property (nonatomic, strong) IBOutlet UIButton* inviteButton;
@property (nonatomic, strong) IBOutlet UIImageView *bgSelectImage;
@property (nonatomic, strong) IBOutlet UIImageView *selectImage;
@property (nonatomic) BOOL sendContactsTVC;
@property (nonatomic,getter=isTempSelected) BOOL tempSelected;

- (id)initWithIdentifier:(NSString*)identifier;
- (IBAction)inviteContact:(id)event;

@end
