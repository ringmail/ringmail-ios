/* UIEditableTableViewCell.m
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

#import "UIEditableTableViewCell.h"
#import "UIColor+Hex.h"

@implementation UIEditableTableViewCell

@synthesize detailTextField;
@synthesize verticalSep;

#pragma mark - Lifecycle Functions

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
	if (self) {
		UITextField *tf = [[UITextField alloc] init];
		[tf setHidden:TRUE];
		[tf setClearButtonMode:UITextFieldViewModeWhileEditing];
		[tf setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
		self.detailTextField = tf;
        
		UIFont *font = [UIFont fontWithName:@"SFUIText-Light" size:17];
        UIFont *font2 = [UIFont fontWithName:@"SFUIText-Bold" size:12];
        
		[self.textLabel setFont:font2];
		[self.detailTextLabel setFont:font];
		[self.detailTextField setFont:font];
        
        self.textLabel.textColor = [UIColor colorWithHex:@"#428db7"];
        
		[self.contentView addSubview:detailTextField];

		// a separator
		UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
		[v setBackgroundColor:[UIColor lightGrayColor]];
		[v setHidden:TRUE];

		self.verticalSep = v;

		[self.contentView addSubview:verticalSep];
        
	}
	return self;
}

#pragma mark - View Functions

- (void)layoutSubviews {
	[super layoutSubviews];
    
	CGRect detailEditFrame;
	detailEditFrame.origin.x = 20;
	detailEditFrame.origin.y = 35;
	detailEditFrame.size.height = 20;

	if ([[self.textLabel text] length] != 0) {
        detailEditFrame.origin.y = 35;
//		// shrink left text width by 10px
		CGRect leftLabelFrame = [self.textLabel frame];
		leftLabelFrame.size.width -= 10;
        leftLabelFrame.origin.y = 18;
		[self.textLabel setFrame:leftLabelFrame];
        
		// place separator
		CGRect separatorFrame = [self.verticalSep frame];
		separatorFrame.origin.x = self.frame.origin.x + 20;
        separatorFrame.origin.y = self.frame.size.height - 1;
        separatorFrame.size.width = self.frame.size.width - 40;
		[self.verticalSep setFrame:separatorFrame];
		[self.verticalSep setHidden:FALSE];
	}
    
	// put the detailed text edit view at the correct position
	CGRect superframe = [[self.detailTextField superview] frame];
	detailEditFrame.size.width = superframe.size.width - detailEditFrame.origin.x;
	[self.detailTextField setFrame:detailEditFrame];
	
	// RingMail
	CGRect labelFrame = [self.textLabel frame];
	labelFrame.origin.y = 18;
    labelFrame.origin.x = 20;
	[self.textLabel setFrame:labelFrame];
	
    CGRect textFrame = [self.detailTextLabel frame];
    textFrame.origin.y = 35;
    textFrame.origin.x = 20;
    textFrame.size.height = 20;
    [self.detailTextLabel setFrame:textFrame];
    
    if ([self.reuseIdentifier isEqual: @"ContactDetailsHeaderCell"])
    {
        CGRect textFrame2 = [self.detailTextField frame];
        textFrame2.origin.y = 20;
        textFrame2.origin.x = 0;
        [self.detailTextField setFrame:textFrame2];
    }
    
}



#pragma mark - UITableViewCell Functions

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
    
	if (editing) {
		[self.detailTextField setHidden:FALSE];
		[self.detailTextLabel setHidden:TRUE];
	} else {
		[self.detailTextField setHidden:TRUE];
		[self.detailTextLabel setHidden:FALSE];
	}
}

- (void)setEditing:(BOOL)editing {
	[self setEditing:editing animated:FALSE];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
}

@end
