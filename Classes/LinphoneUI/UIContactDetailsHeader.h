/* UIContactDetailsHeader.h
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

#import "ImagePickerViewController.h"
#import "ContactDetailsDelegate.h"

@interface UIContactDetailsHeader : UIViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ImagePickerDelegate> {
    @private
    NSArray *propertyList;
    BOOL editing;
}

@property (nonatomic, assign) ABRecordRef contact;
    
@property (nonatomic, strong) IBOutlet UILabel *addressLabel;
@property (nonatomic, strong) IBOutlet UIImageView *avatarImage;
@property (nonatomic, strong) IBOutlet UIImageView *avatarEditImage;

@property (nonatomic, strong) IBOutlet UIView *normalView;
@property (nonatomic, strong) IBOutlet UIView *editView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet id<ContactDetailsDelegate> contactDetailsDelegate;
@property (nonatomic, strong) IBOutlet UIButton *rgInvite;
@property (nonatomic, strong) IBOutlet UIButton *callButton;
@property (nonatomic, strong) IBOutlet UIButton *chatButton;
@property (nonatomic, strong) IBOutlet UIButton *videoButton;
@property (nonatomic, strong) IBOutlet UIButton *favoriteButton;

@property (strong, nonatomic) ImagePickerViewController* popoverController;
@property (nonatomic) BOOL rgMember;

@property(nonatomic,getter=isEditing) BOOL editing;

- (IBAction)onAvatarClick:(id)event;
- (IBAction)onActionChat:(id)event;
- (IBAction)onActionCall:(id)event;
- (IBAction)onActionVideo:(id)event;
- (IBAction)onActionFavorite:(id)event;

+ (CGFloat)height:(BOOL)editing member:(BOOL)member;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)setEditing:(BOOL)editing;
- (BOOL)isEditing;
- (BOOL)isValid;
- (void)update;

@end
